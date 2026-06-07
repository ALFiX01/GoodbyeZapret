package main

import (
	"bufio"
	"context"
	"crypto/tls"
	"errors"
	"flag"
	"fmt"
	"io"
	"math/rand"
	"net"
	"net/http"
	"net/http/httptrace"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/fatih/color"
	"golang.org/x/net/publicsuffix"
	"golang.org/x/sys/windows/registry"
)

var (
	// Таймауты
	fastDialTimeout    = 2 * time.Second
	fastTLSHandshake   = 2 * time.Second
	fastResponseHeader = 2500 * time.Millisecond

	// Read-timeout (аналог requests read_timeout)
	fastReadTimeout = 3 * time.Second
	slowReadTimeout = 6 * time.Second

	// Общий потолок на запрос (context timeout)
	probeTotalTimeout = 3 * time.Second
	fastTotalTimeout  = 6 * time.Second
	slowTotalTimeout  = 12 * time.Second

	successPause = 5 * time.Second
	failPause    = 8 * time.Second
)

const (
	// Конфигурация
	userAgent      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
	registryPath   = `Software\ALFiX inc.\GoodbyeZapret`
	updateCheckURL = "https://goodbyezapret.crabdance.com/GoodbyeZapret_Version"

	// Порог чтения. Fast тоже делает GET, но читает мало.
	fastThreshold   = 16 * 1024
	strictThreshold = 64 * 1024
	chunkSize       = 4096
)

var realHeaders = map[string]string{
	"User-Agent":      userAgent,
	"Accept":          "*/*",
	"Connection":      "keep-alive",
	"Cache-Control":   "no-cache",
	"Pragma":          "no-cache",
	"Accept-Encoding": "identity",
}

// timeoutConn ставит ReadDeadline перед каждым Read (read-timeout “на сокете”)
type timeoutConn struct {
	net.Conn
	readTimeout time.Duration
}

func (c *timeoutConn) Read(p []byte) (int, error) {
	if c.readTimeout > 0 {
		_ = c.Conn.SetReadDeadline(time.Now().Add(c.readTimeout))
	}
	return c.Conn.Read(p)
}

// --- Транспорт (параметризованный read-timeout) ---
func buildHTTPTransport(readTimeout time.Duration, ipMode string) *http.Transport {
	d := &net.Dialer{
		Timeout:   fastDialTimeout,
		KeepAlive: 30 * time.Second,
	}

	dialNetwork := func(network string) string {
		switch strings.ToLower(ipMode) {
		case "4", "ipv4":
			return "tcp4"
		case "6", "ipv6":
			return "tcp6"
		default:
			return network
		}
	}

	return &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			conn, err := d.DialContext(ctx, dialNetwork(network), addr)
			if err != nil {
				return nil, err
			}
			return &timeoutConn{Conn: conn, readTimeout: readTimeout}, nil
		},
		// как в Python verify=False
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, //nolint:gosec

		TLSHandshakeTimeout:   fastTLSHandshake,
		ResponseHeaderTimeout: fastResponseHeader,
		ForceAttemptHTTP2:     true,
		DisableKeepAlives:     false,
		DisableCompression:    true,
		MaxIdleConns:          100,
		MaxIdleConnsPerHost:   16,
		IdleConnTimeout:       30 * time.Second,
	}
}

type Checker struct {
	clientFast *http.Client
	clientSlow *http.Client

	updateURL string
	strict    bool
}

type probeProfile struct {
	minBytes            int
	maxBytes            int
	rangeRequest        bool
	rejectHTML          bool
	allowedContentTypes []string
	allowedStatuses     []int
}

type domainResult struct {
	domain string
	ok     bool
	reason string
}

type resultGroup struct {
	ok    int
	total int
	anyOK bool
	soft  bool
}

func NewChecker(updateURL string, strict bool, ipMode string) *Checker {
	trFast := buildHTTPTransport(fastReadTimeout, ipMode)
	trSlow := buildHTTPTransport(slowReadTimeout, ipMode)

	return &Checker{
		clientFast: &http.Client{Transport: trFast, Timeout: 0},
		clientSlow: &http.Client{Transport: trSlow, Timeout: 0},
		updateURL:  updateURL,
		strict:     strict,
	}
}

func (c *Checker) Check(domainOrURL string) (bool, string) {
	rawURL := c.buildURL(domainOrURL)
	rawURL = bypassURL(rawURL)

	if !c.strict {
		r := c.checkOncePyLike(rawURL, c.clientFast, probeTotalTimeout, false)
		if r.err == nil {
			return true, ""
		}
		if !shouldFallbackToStrict(r) {
			return false, classifyPyLike(r)
		}
	}

	return c.checkStrict(rawURL)
}

func (c *Checker) checkStrict(rawURL string) (bool, string) {
	r := c.checkOncePyLike(rawURL, c.clientFast, fastTotalTimeout, true)
	if r.err == nil {
		return true, ""
	}

	if shouldRetry(r.err) {
		r = c.checkOncePyLike(rawURL, c.clientSlow, slowTotalTimeout, true)
		if r.err == nil {
			return true, ""
		}
	}

	return false, classifyPyLike(r)
}

func (c *Checker) buildURL(domainOrURL string) string {
	// Если в domains.txt уже полный URL
	if strings.HasPrefix(domainOrURL, "http://") || strings.HasPrefix(domainOrURL, "https://") {
		return domainOrURL
	}

	// YouTube кэши: rr*---sn-*.googlevideo.com -> /generate_204
	if strings.HasSuffix(strings.ToLower(domainOrURL), ".googlevideo.com") {
		return "https://" + domainOrURL + "/generate_204"
	}

	// i.ytimg.com без пути на практике часто бесполезен для проверки.
	if strings.EqualFold(domainOrURL, "i.ytimg.com") {
		return "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg"
	}

	if strings.EqualFold(domainOrURL, "discord.com") {
		return "https://discord.com/api/v9/experiments"
	}

	if strings.EqualFold(domainOrURL, "aws.amazon.com") {
		return "https://aws.amazon.com/robots.txt"
	}

	// Backward-compatible alias for old domain lists.
	if strings.EqualFold(domainOrURL, "raw.githubusercontent.com") {
		return c.updateURL
	}

	return "https://" + domainOrURL
}

func bypassURL(raw string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return raw
	}
	if u.Path == "" {
		u.Path = "/"
	}
	q := u.Query()
	q.Set("_t", strconv.Itoa(1000+rand.Intn(9000)))
	u.RawQuery = q.Encode()
	return u.String()
}

// displayDomain возвращает “главный” домен (eTLD+1) для вывода
func displayDomain(domainOrURL string) string {
	s := strings.TrimSpace(domainOrURL)
	s = strings.TrimSuffix(s, ".")

	// 1) Если это похоже на "host/path" без схемы (как i.ytimg.com/vi/...)
	// то host = до первого "/" или "?"
	host := s
	if strings.HasPrefix(s, "http://") || strings.HasPrefix(s, "https://") {
		// нормальный URL
		if u, err := url.Parse(s); err == nil {
			if hn := u.Hostname(); hn != "" {
				host = hn
			}
		}
	} else {
		// без схемы: режем по / ? #
		cut := len(s)
		for _, sep := range []string{"/", "?", "#"} {
			if i := strings.Index(s, sep); i >= 0 && i < cut {
				cut = i
			}
		}
		host = s[:cut]
	}

	// 2) убрать порт, если вдруг есть
	if h, _, err := net.SplitHostPort(host); err == nil && h != "" {
		host = h
	}

	host = strings.TrimSuffix(host, ".")
	if host == "" {
		return s
	}

	// IP адреса не прогоняем через publicsuffix
	if net.ParseIP(host) != nil {
		return host
	}

	if strings.EqualFold(host, "updates.discord.com") {
		return "updates.discord.com"
	}

	// 3) eTLD+1: rr6---sn-xxx.googlevideo.com -> googlevideo.com
	if etld1, err := publicsuffix.EffectiveTLDPlusOne(host); err == nil && etld1 != "" {
		return etld1
	}

	// fallback: последние 2 метки
	parts := strings.Split(host, ".")
	if len(parts) >= 2 {
		return parts[len(parts)-2] + "." + parts[len(parts)-1]
	}
	return host
}

type checkRes struct {
	downloaded  int
	statusCode  int
	contentType string
	gotFirst    bool
	err         error
}

func (c *Checker) checkOncePyLike(urlStr string, client *http.Client, totalTimeout time.Duration, strict bool) checkRes {
	ctx, cancel := context.WithTimeout(context.Background(), totalTimeout)
	defer cancel()
	profile := profileForURL(urlStr, strict)

	var gotFirst int32
	trace := &httptrace.ClientTrace{
		GotFirstResponseByte: func() { atomic.StoreInt32(&gotFirst, 1) },
	}
	ctx = httptrace.WithClientTrace(ctx, trace)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, urlStr, nil)
	if err != nil {
		return checkRes{err: err}
	}

	for k, v := range realHeaders {
		req.Header.Set(k, v)
	}
	if profile.rangeRequest && profile.maxBytes > 0 {
		req.Header.Set("Range", fmt.Sprintf("bytes=0-%d", profile.maxBytes-1))
	}

	resp, err := client.Do(req)
	if err != nil {
		return checkRes{gotFirst: atomic.LoadInt32(&gotFirst) == 1, err: err}
	}
	defer resp.Body.Close()

	if !statusAllowed(resp.StatusCode, profile.allowedStatuses) {
		return checkRes{
			statusCode:  resp.StatusCode,
			contentType: resp.Header.Get("Content-Type"),
			gotFirst:    true,
			err:         fmt.Errorf("http %d", resp.StatusCode),
		}
	}

	buf := make([]byte, chunkSize)
	downloaded := 0

	for downloaded < profile.maxBytes {
		n, rerr := resp.Body.Read(buf)
		if n > 0 {
			downloaded += n
		}
		if rerr == io.EOF {
			break
		}
		if rerr != nil {
			return checkRes{
				downloaded:  downloaded,
				statusCode:  resp.StatusCode,
				contentType: resp.Header.Get("Content-Type"),
				gotFirst:    atomic.LoadInt32(&gotFirst) == 1,
				err:         rerr,
			}
		}
	}

	contentType := resp.Header.Get("Content-Type")
	if err := validateResponse(resp.StatusCode, contentType, downloaded, profile); err != nil {
		return checkRes{
			downloaded:  downloaded,
			statusCode:  resp.StatusCode,
			contentType: contentType,
			gotFirst:    atomic.LoadInt32(&gotFirst) == 1,
			err:         err,
		}
	}

	return checkRes{
		downloaded:  downloaded,
		statusCode:  resp.StatusCode,
		contentType: contentType,
		gotFirst:    atomic.LoadInt32(&gotFirst) == 1,
		err:         nil,
	}
}

func profileForURL(urlStr string, strict bool) probeProfile {
	maxBytes := fastThreshold
	if strict {
		maxBytes = strictThreshold
	}

	p := probeProfile{
		minBytes:        512,
		maxBytes:        maxBytes,
		rangeRequest:    true,
		allowedStatuses: []int{http.StatusOK, http.StatusPartialContent},
	}

	u, err := url.Parse(urlStr)
	if err != nil {
		return p
	}
	host := strings.ToLower(u.Hostname())
	path := strings.ToLower(u.EscapedPath())

	if strings.HasSuffix(host, ".googlevideo.com") && path == "/generate_204" {
		p.minBytes = 0
		p.maxBytes = 1024
		p.rangeRequest = false
		p.rejectHTML = true
		p.allowedStatuses = []int{http.StatusNoContent, http.StatusOK}
		return p
	}

	if host == "i.ytimg.com" || hasAnySuffix(path, ".jpg", ".jpeg", ".png", ".webp", ".gif", ".avif") {
		p.minBytes = 4 * 1024
		if strict {
			p.minBytes = 16 * 1024
		}
		p.maxBytes = maxBytes
		p.rejectHTML = true
		p.allowedContentTypes = []string{"image/"}
		return p
	}

	if host == "discord.com" && strings.HasPrefix(path, "/api/") {
		p.minBytes = 2
		p.rejectHTML = true
		p.allowedContentTypes = []string{"application/json", "text/plain"}
		return p
	}

	if host == "updates.discord.com" {
		p.minBytes = 0
		p.maxBytes = 1024
		p.rangeRequest = false
		p.allowedStatuses = []int{http.StatusOK, http.StatusNoContent, http.StatusNotFound}
		return p
	}

	if host == "goodbyezapret.crabdance.com" && strings.Contains(path, "goodbyezapret_version") {
		p.minBytes = 1
		p.maxBytes = 4 * 1024
		p.rangeRequest = false
		p.rejectHTML = true
		p.allowedContentTypes = []string{"text/plain", "application/octet-stream"}
		return p
	}

	if host == "aws.amazon.com" && path == "/robots.txt" {
		p.minBytes = 1
		p.maxBytes = 4 * 1024
		p.rangeRequest = false
		p.rejectHTML = true
		p.allowedContentTypes = []string{"text/plain"}
		return p
	}

	return p
}

func validateResponse(statusCode int, contentType string, downloaded int, p probeProfile) error {
	if p.minBytes == 0 && statusAllowed(statusCode, p.allowedStatuses) {
		return nil
	}

	lowerCT := strings.ToLower(contentType)
	if p.rejectHTML && strings.Contains(lowerCT, "text/html") {
		return fmt.Errorf("unexpected html")
	}

	if len(p.allowedContentTypes) > 0 && lowerCT != "" {
		ok := false
		for _, prefix := range p.allowedContentTypes {
			if strings.HasPrefix(lowerCT, strings.ToLower(prefix)) {
				ok = true
				break
			}
		}
		if !ok {
			return fmt.Errorf("content type %s", contentType)
		}
	}

	if downloaded < p.minBytes {
		return fmt.Errorf("short body %d", downloaded)
	}

	return nil
}

func statusAllowed(statusCode int, allowed []int) bool {
	if len(allowed) == 0 {
		return statusCode >= 200 && statusCode < 400
	}
	for _, s := range allowed {
		if statusCode == s {
			return true
		}
	}
	return false
}

func hasAnySuffix(s string, suffixes ...string) bool {
	for _, suffix := range suffixes {
		if strings.HasSuffix(s, suffix) {
			return true
		}
	}
	return false
}

func classifyPyLike(r checkRes) string {
	if r.err == nil {
		return ""
	}

	if r.statusCode >= 400 {
		return fmt.Sprintf("HTTP_%d", r.statusCode)
	}

	// TIMEOUT vs DPI-blackhole (read-timeout после первого байта)
	if isTimeoutErr(r.err) {
		if r.gotFirst {
			return "DPI_TIMEOUT"
		}
		return "TIMEOUT"
	}

	// RST / forcibly closed
	if isRSTErr(r.err) {
		return "RST"
	}

	// DNS
	var dnsErr *net.DNSError
	if errors.As(r.err, &dnsErr) {
		return "DNS"
	}

	if strings.Contains(r.err.Error(), "unexpected html") ||
		strings.Contains(r.err.Error(), "content type") {
		return "CONTENT"
	}
	if strings.Contains(r.err.Error(), "short body") {
		return "SHORT"
	}

	return "CONN"
}

func isTimeoutErr(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return true
	}
	var netErr net.Error
	return errors.As(err, &netErr) && netErr.Timeout()
}

func isRSTErr(err error) bool {
	if err == nil {
		return false
	}
	s := strings.ToLower(err.Error())
	return strings.Contains(s, "connection reset") ||
		strings.Contains(s, "wsarecv") ||
		strings.Contains(s, "forcibly closed") ||
		strings.Contains(s, "remote host")
}

func shouldRetry(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return true
	}
	var netErr net.Error
	if errors.As(err, &netErr) {
		return netErr.Timeout() || netErr.Temporary()
	}
	return false
}

func shouldFallbackToStrict(r checkRes) bool {
	switch r.statusCode {
	case http.StatusForbidden, http.StatusMethodNotAllowed, http.StatusNotImplemented:
		return true
	}
	return false
}

func main() {
	strict := flag.Bool("strict", false, "строгая проверка GET с чтением тела ответа")
	quick := flag.Bool("quick", false, "быстрая проверка для авто-подбора конфигов")
	ipMode := flag.String("ip", "4", "режим IP: 4, 6 или auto")
	domainsFile := flag.String("domains", "", "путь к файлу доменов (по умолчанию domains.txt рядом с exe)")
	flag.Parse()

	if *quick {
		applyQuickProfile()
	}

	var batFile string
	if flag.NArg() > 0 {
		batFile = flag.Arg(0)
	}

	domains, err := loadDomains(*domainsFile)
	if err != nil {
		color.Red("Ошибка: %v\n", err)
		os.Exit(1)
	}
	if len(domains) == 0 {
		color.Red("Файл domains.txt пуст\n")
		os.Exit(1)
	}

	concurrency := runtime.NumCPU() * 4
	if concurrency < 32 {
		concurrency = 32
	}
	if concurrency > len(domains) {
		concurrency = len(domains)
	}

	printHeader()

	checker := NewChecker(updateCheckURL, *strict, *ipMode)

	var wg sync.WaitGroup
	sem := make(chan struct{}, concurrency)
	results := make([]domainResult, len(domains))
	softDefaultInfra := *domainsFile == ""

	for i, d := range domains {
		wg.Add(1)
		sem <- struct{}{}

		go func(idx int, domainOrURL string) {
			defer wg.Done()
			defer func() { <-sem }()

			ok, reason := checker.Check(domainOrURL)
			results[idx] = domainResult{
				domain: domainOrURL,
				ok:     ok,
				reason: reason,
			}
		}(i, d)
	}

	wg.Wait()

	groups := buildResultGroups(results, softDefaultInfra)
	for i, r := range results {
		printResult(i, r, groups)
	}

	success, total := summarizeGroups(groups)
	msg := fmt.Sprintf("Доступно обязательных проверок: %d/%d", success, total)

	if success == total {
		printFooter(true, msg)
		if batFile != "" {
			writeRegistrySuccess(batFile)
		}
		time.Sleep(successPause)
		os.Exit(0)
	} else {
		printFooter(false, msg)
		time.Sleep(failPause)
		os.Exit(1)
	}
}

const (
	colWidth     = 22
	domainWidth  = 28
	dividerWidth = 74
)

func applyQuickProfile() {
	fastDialTimeout = 800 * time.Millisecond
	fastTLSHandshake = 800 * time.Millisecond
	fastResponseHeader = 1 * time.Second
	fastReadTimeout = 1 * time.Second
	slowReadTimeout = 2 * time.Second
	probeTotalTimeout = 1200 * time.Millisecond
	fastTotalTimeout = 2500 * time.Millisecond
	slowTotalTimeout = 4 * time.Second
	successPause = 1 * time.Second
	failPause = 1 * time.Second
}

var (
	dimColor   = color.New(color.FgHiBlack).SprintFunc()
	infoColor  = color.New(color.FgCyan).SprintFunc()
	okColor    = color.New(color.FgGreen).SprintFunc()
	warnColor  = color.New(color.FgYellow).SprintFunc()
	errorColor = color.New(color.FgRed).SprintFunc()
	titleColor = color.New(color.FgHiCyan).SprintFunc()
)

func printHeader() {
	fmt.Printf(" %s %s\n", infoColor("[ * ]"), titleColor("Проверка доступности обхода"))
	fmt.Printf(" %s\n", dimColor(strings.Repeat("─", dividerWidth)))
}

func printResult(index int, r domainResult, groups map[string]resultGroup) {
	name := displayDomain(r.domain)
	label := displayName(r.domain)
	domain := dimColor(fmt.Sprintf("%-*s", domainWidth, name))

	if r.ok {
		fmt.Printf(" %s %-*s %s %s\n", okColor("[ OK ]"), colWidth, label, domain, dimColor("доступно"))
		return
	}

	key, _ := resultGroupKey(index, r.domain)
	group := groups[key]
	if group.soft {
		fmt.Printf(" %s %-*s %s %s\n", warnColor("[WARN]"), colWidth, label, domain, dimColor(reasonText(r.reason)))
		return
	}
	if group.anyOK && group.ok > 0 {
		fmt.Printf(" %s %-*s %s %s\n", warnColor("[SKIP]"), colWidth, label, domain, dimColor(reasonText(r.reason)+", зачтено по другому узлу"))
	} else {
		fmt.Printf(" %s %-*s %s %s\n", errorColor("[ERR ]"), colWidth, label, domain, reasonText(r.reason))
	}
}

func printFooter(ok bool, msg string) {
	fmt.Printf(" %s\n", dimColor(strings.Repeat("─", dividerWidth)))
	if ok {
		fmt.Printf(" %s %s\n", okColor("[ OK ]"), msg)
		return
	}
	fmt.Printf(" %s %s\n", errorColor("[ERR ]"), msg)
}

func displayName(domainOrURL string) string {
	switch displayDomain(domainOrURL) {
	case "googlevideo.com":
		return "YouTube Video CDN"
	case "ytimg.com":
		return "YouTube Images"
	case "discord.com":
		return "Discord"
	case "cloudflare.com":
		return "Cloudflare CDN"
	case "amazon.com":
		return "Amazon CDN"
	case "crabdance.com":
		return "GoodbyeZapret"
	default:
		return displayDomain(domainOrURL)
	}
}

func reasonText(reason string) string {
	switch reason {
	case "DNS":
		return "DNS не ответил"
	case "TIMEOUT":
		return "таймаут подключения"
	case "DPI_TIMEOUT":
		return "таймаут после ответа"
	case "RST":
		return "соединение сброшено"
	case "CONTENT":
		return "неожиданный ответ"
	case "SHORT":
		return "короткий ответ"
	case "":
		return ""
	default:
		if strings.HasPrefix(reason, "HTTP_") {
			return "HTTP " + strings.TrimPrefix(reason, "HTTP_")
		}
		return reason
	}
}

func buildResultGroups(results []domainResult, softDefaultInfra bool) map[string]resultGroup {
	groups := make(map[string]resultGroup, len(results))
	for i, r := range results {
		key, anyOK := resultGroupKey(i, r.domain)
		g := groups[key]
		g.total++
		g.anyOK = anyOK
		g.soft = softDefaultInfra && isDefaultInfraCheck(r.domain)
		if r.ok {
			g.ok++
		}
		groups[key] = g
	}
	return groups
}

func summarizeGroups(groups map[string]resultGroup) (int, int) {
	success := 0
	total := 0
	for _, g := range groups {
		if g.soft {
			continue
		}
		total++
		if g.anyOK {
			if g.ok > 0 {
				success++
			}
			continue
		}
		if g.ok == g.total {
			success++
		}
	}

	return success, total
}

func resultGroupKey(index int, domainOrURL string) (string, bool) {
	if displayDomain(domainOrURL) == "googlevideo.com" {
		return "googlevideo.com", true
	}
	return fmt.Sprintf("#%d:%s", index, domainOrURL), false
}

func isDefaultInfraCheck(domainOrURL string) bool {
	name := displayDomain(domainOrURL)
	return name == "cloudflare.com" || name == "amazon.com"
}

func loadDomains(customPath string) ([]string, error) {
	filePath := customPath
	if filePath == "" {
		exePath, err := os.Executable()
		if err != nil {
			return nil, fmt.Errorf("exe path error: %w", err)
		}
		filePath = filepath.Join(filepath.Dir(exePath), "domains.txt")
	}

	f, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	domains := make([]string, 0, 50)
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line != "" && !strings.HasPrefix(line, "#") {
			domains = append(domains, line)
		}
	}
	return domains, scanner.Err()
}

func writeRegistrySuccess(batFile string) {
	k, _, err := registry.CreateKey(registry.CURRENT_USER, registryPath, registry.SET_VALUE)
	if err != nil {
		return
	}
	defer k.Close()
	_ = k.SetStringValue("GoodbyeZapret_LastWorkConfig", batFile)
	_ = k.SetStringValue("GoodbyeZapret_LastStartConfig", batFile)
}

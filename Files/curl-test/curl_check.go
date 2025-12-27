package main

import (
	"bufio"
	"context"
	"crypto/tls"
	"errors"
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

const (
	// Таймауты
	fastDialTimeout    = 2 * time.Second
	fastTLSHandshake   = 2 * time.Second
	fastResponseHeader = 2500 * time.Millisecond

	// Read-timeout (аналог requests read_timeout)
	fastReadTimeout = 3 * time.Second
	slowReadTimeout = 6 * time.Second

	// Общий потолок на запрос (context timeout)
	fastTotalTimeout = 6 * time.Second
	slowTotalTimeout = 12 * time.Second

	// Конфигурация
	userAgent      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
	registryPath   = `Software\ALFiX inc.\GoodbyeZapret`
	githubCheckURI = "/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version"

	// Порог “успеха” как в Python-алгоритме
	baseThreshold = 64 * 1024
	chunkSize     = 4096
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
func buildHTTPTransport(readTimeout time.Duration) *http.Transport {
	d := &net.Dialer{
		Timeout:   fastDialTimeout,
		KeepAlive: -1,
	}

	return &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			conn, err := d.DialContext(ctx, network, addr)
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
		DisableKeepAlives:     true,
		DisableCompression:    true,
		MaxIdleConns:          100,
	}
}

type Checker struct {
	clientFast *http.Client
	clientSlow *http.Client

	githubPath string
}

func NewChecker(githubPath string) *Checker {
	trFast := buildHTTPTransport(fastReadTimeout)
	trSlow := buildHTTPTransport(slowReadTimeout)

	return &Checker{
		clientFast: &http.Client{Transport: trFast, Timeout: 0},
		clientSlow: &http.Client{Transport: trSlow, Timeout: 0},
		githubPath: githubPath,
	}
}

func (c *Checker) Check(domainOrURL string) (bool, string) {
	rawURL := c.buildURL(domainOrURL)
	rawURL = bypassURL(rawURL)

	// 1) Быстрая попытка
	r := c.checkOncePyLike(rawURL, c.clientFast, fastTotalTimeout)
	if r.err == nil {
		return true, ""
	}

	// 2) Retry (только если есть смысл)
	if shouldRetry(r.err) {
		r = c.checkOncePyLike(rawURL, c.clientSlow, slowTotalTimeout)
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

	// GitHub raw special-case
	if strings.EqualFold(domainOrURL, "raw.githubusercontent.com") {
		return "https://" + domainOrURL + c.githubPath
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
	downloaded int
	statusCode int
	gotFirst   bool
	err        error
}

func (c *Checker) checkOncePyLike(urlStr string, client *http.Client, totalTimeout time.Duration) checkRes {
	ctx, cancel := context.WithTimeout(context.Background(), totalTimeout)
	defer cancel()

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

	resp, err := client.Do(req)
	if err != nil {
		return checkRes{gotFirst: atomic.LoadInt32(&gotFirst) == 1, err: err}
	}
	defer resp.Body.Close()

	// Как в Python-алгоритме: HTTP>=400 считаем ошибкой
	if resp.StatusCode >= 400 {
		return checkRes{
			statusCode: resp.StatusCode,
			gotFirst:   true,
			err:        fmt.Errorf("http %d", resp.StatusCode),
		}
	}

	buf := make([]byte, chunkSize)
	downloaded := 0

	for downloaded < baseThreshold {
		n, rerr := resp.Body.Read(buf)
		if n > 0 {
			downloaded += n
		}
		if rerr == io.EOF {
			break
		}
		if rerr != nil {
			return checkRes{
				downloaded: downloaded,
				statusCode: resp.StatusCode,
				gotFirst:   atomic.LoadInt32(&gotFirst) == 1,
				err:        rerr,
			}
		}
	}

	return checkRes{
		downloaded: downloaded,
		statusCode: resp.StatusCode,
		gotFirst:   atomic.LoadInt32(&gotFirst) == 1,
		err:        nil,
	}
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

func main() {
	rand.New(rand.NewSource(time.Now().UnixNano()))

	var batFile string
	if len(os.Args) > 1 {
		batFile = os.Args[1]
	}

	domains, err := loadDomains()
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

	fmt.Printf(" Запуск проверки: потоков=%d, доменов=%d, CPU=%d\n",
		concurrency, len(domains), runtime.NumCPU())

	checker := NewChecker(githubCheckURI)

	var okCnt int32
	var wg sync.WaitGroup
	sem := make(chan struct{}, concurrency)

	fmt.Println(" " + strings.Repeat("-", 50))

	for _, d := range domains {
		wg.Add(1)
		sem <- struct{}{}

		go func(domainOrURL string) {
			defer wg.Done()
			defer func() { <-sem }()

			ok, reason := checker.Check(domainOrURL)
			printResult(domainOrURL, ok, reason)

			if ok {
				atomic.AddInt32(&okCnt, 1)
			}
		}(d)
	}

	wg.Wait()
	fmt.Println(" " + strings.Repeat("-", 50))

	total := len(domains)
	success := int(okCnt)
	msg := fmt.Sprintf(" Результат: %d/%d доменов доступны", success, total)

	if success == total {
		color.Green(msg)
		if batFile != "" {
			writeRegistrySuccess(batFile)
		}
		time.Sleep(1 * time.Second)
		os.Exit(0)
	} else {
		color.Red(msg)
		time.Sleep(3 * time.Second)
		os.Exit(1)
	}
}

const colWidth = 32

func printResult(domainOrURL string, ok bool, reason string) {
	name := displayDomain(domainOrURL)

	if ok {
		fmt.Printf(" %-*s %s\n", colWidth, name, color.GreenString("OK"))
	} else {
		fmt.Printf(" %-*s %s\n", colWidth, name, color.RedString("ERR [%s]", reason))
	}
}


func loadDomains() ([]string, error) {
	exePath, err := os.Executable()
	if err != nil {
		return nil, fmt.Errorf("exe path error: %w", err)
	}
	filePath := filepath.Join(filepath.Dir(exePath), "domains.txt")

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

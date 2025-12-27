//go:build windows
// +build windows

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
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/fatih/color"
	"golang.org/x/sys/windows/registry"
)

const (
	// Константы путей и версий
	githubPath   = "/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version"
	registryPath = `Software\ALFiX inc.\GoodbyeZapret`

	// "реальный" UA как в Python-версии
	userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

	// Тайминги
	fastDialTimeout    = 2 * time.Second
	fastTLSHandshake   = 2 * time.Second
	fastResponseHeader = 2500 * time.Millisecond

	// Read-timeout (аналог requests read_timeout)
	fastReadTimeout = 3 * time.Second
	slowReadTimeout = 6 * time.Second

	// Общий потолок на запрос
	fastTotalTimeout = 6 * time.Second
	slowTotalTimeout = 12 * time.Second

	// Пауза после запуска .bat файла перед проверкой
	serviceInitDelay = 1500 * time.Millisecond

	// Порог “успешной” загрузки (как BASE_THRESHOLD)
	baseThreshold = 64 * 1024
	chunkSize     = 4096
)

var (
	checkMark = color.GreenString("OK")
	crossMark = color.RedString("ERROR")

	realHeaders = map[string]string{
		"User-Agent":      userAgent,
		"Accept":          "*/*",
		"Connection":      "keep-alive",
		"Cache-Control":   "no-cache",
		"Pragma":          "no-cache",
		"Accept-Encoding": "identity",
	}
)

// timeoutConn ставит ReadDeadline перед каждым Read, имитируя read_timeout
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

// Transport параметризован read-timeout
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

		// Аналог verify=False (игнор SSL ошибок)
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, //nolint:gosec

		TLSHandshakeTimeout:   fastTLSHandshake,
		ResponseHeaderTimeout: fastResponseHeader,
		ForceAttemptHTTP2:     true,
		DisableKeepAlives:     true,
		DisableCompression:    true,
		MaxIdleConns:          100,
	}
}

type Finder struct {
	toolsDir      string
	projectDir    string
	configsDir    string
	domains       []string
	clientFast    *http.Client
	clientSlow    *http.Client
	almostWorking []string
}

func NewFinder() (*Finder, error) {
	domains, err := loadDomains()
	if err != nil {
		return nil, fmt.Errorf("ошибка чтения domains.txt: %w", err)
	}
	if len(domains) == 0 {
		return nil, errors.New("domains.txt пуст")
	}

	toolsDir, projectDir := resolveDirs()
	configsDir, err := findConfigsDir(projectDir)
	if err != nil {
		return nil, fmt.Errorf("папка с конфигами не найдена: %w", err)
	}

	trFast := buildHTTPTransport(fastReadTimeout)
	trSlow := buildHTTPTransport(slowReadTimeout)

	return &Finder{
		toolsDir:   toolsDir,
		projectDir: projectDir,
		configsDir: configsDir,
		domains:    domains,
		clientFast: &http.Client{Transport: trFast, Timeout: 0},
		clientSlow: &http.Client{Transport: trSlow, Timeout: 0},
	}, nil
}

func (f *Finder) Run() {
	list, err := filepath.Glob(filepath.Join(f.configsDir, "*.bat"))
	if err != nil || len(list) == 0 {
		color.Red("[ОШИБКА] В папке %q нет .bat файлов.", f.configsDir)
		return
	}
	sort.Strings(list)

	fmt.Println()
	color.Cyan("Поиск рабочего конфига в \"%s\" ...", f.configsDir)
	printSeparator()

	for _, cfgPath := range list {
		_ = f.testConfig(cfgPath)
	}

	f.printSummary()
}

// Возвращает true, если конфиг идеален и пользователь решил остановиться
func (f *Finder) testConfig(cfgPath string) bool {
	cfgName := filepath.Base(cfgPath)
	color.Cyan(" Запуск конфига %s ...", cfgName)

	runBatch(cfgPath)
	time.Sleep(serviceInitDelay)

	color.Cyan("  Проверка доступности доменов ...")
	okCount, failedList := f.testDomains()
	total := len(f.domains)

	defer func() {
		smartCleanup(f.toolsDir)
		color.Cyan("  Продолжаем поиск...")
		printSeparator()
		fmt.Println()
	}()

	if okCount == total {
		setRegistry(cfgName)
		printSeparator()
		fmt.Printf("            %s\n", color.GreenString("НАЙДЕН РАБОЧИЙ КОНФИГ: %s", cfgName))
		printSeparator()
		waitEnter2()
		return true
	} else if total-okCount == 1 {
		msg := fmt.Sprintf("конфиг %s (не работает: %s)", cfgName, strings.Join(failedList, ", "))
		f.almostWorking = append(f.almostWorking, msg)
		color.Yellow("  Конфиг %s почти работает. Недоступен всего 1 домен.", cfgName)
	} else {
		color.Red("  Конфиг %s: доступно %d/%d (FAIL)", cfgName, okCount, total)
	}

	return false
}

func (f *Finder) printSummary() {
	color.Yellow("[INFO] Автоматический поиск завершен.")
	if len(f.almostWorking) > 0 {
		fmt.Println()
		printSeparator()
		color.Yellow("         Кандидаты (1 ошибка):")
		printSeparator()
		for _, s := range f.almostWorking {
			fmt.Println("  ", s)
		}
		fmt.Println()
	}
}

func main() {
	rand.New(rand.NewSource(time.Now().UnixNano()))

	finder, err := NewFinder()
	if err != nil {
		color.Red("[ERROR] %v", err)
		waitEnter()
		return
	}

	finder.Run()
	waitEnter()
}

// ------------------------------------------------ LOGIC ---------------------------------------------------------

func (f *Finder) checkDomain(domain string) (bool, string) {
	raw := f.buildURL(domain)
	raw = bypassURL(raw)

	// 1) Быстрая проверка
	res := f.checkOncePyLike(raw, f.clientFast, fastTotalTimeout)
	if res.err == nil {
		return true, ""
	}

	// 2) Retry только на “сетевых”/таймаутных ошибках
	if shouldRetry(res.err) {
		res = f.checkOncePyLike(raw, f.clientSlow, slowTotalTimeout)
		if res.err == nil {
			return true, ""
		}
	}

	return false, classifyPyLike(res)
}

func (f *Finder) buildURL(domain string) string {
	// NEW: если в domains.txt уже полный URL — используем как есть
	if strings.HasPrefix(domain, "http://") || strings.HasPrefix(domain, "https://") {
		return domain
	}

	// NEW: googlevideo кэши YouTube лучше проверять через /generate_204
	if strings.HasSuffix(strings.ToLower(domain), ".googlevideo.com") {
		return "https://" + domain + "/generate_204"
	}

	// как было: спец-путь для github raw
	if strings.EqualFold(domain, "raw.githubusercontent.com") {
		return "https://" + domain + githubPath
	}

	return "https://" + domain
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

type checkRes struct {
	downloaded int
	statusCode int
	gotFirst   bool
	err        error
}

func (f *Finder) checkOncePyLike(urlStr string, client *http.Client, totalTimeout time.Duration) checkRes {
	ctx, cancel := context.WithTimeout(context.Background(), totalTimeout)
	defer cancel()

	var gotFirst int32
	trace := &httptrace.ClientTrace{
		GotFirstResponseByte: func() {
			atomic.StoreInt32(&gotFirst, 1)
		},
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

	// Как в Python: HTTP >= 400 считаем ошибкой (если нужно “любой HTTP = ок”, убери этот блок)
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

	// TIMEOUT vs DPI-blackhole (read timeout после первого байта)
	if isTimeoutErr(r.err) {
		if r.gotFirst {
			return "DPI_TIMEOUT"
		}
		return "TIMEOUT"
	}

	if isRSTErr(r.err) {
		return "RST"
	}

	var dnsErr *net.DNSError
	if errors.As(r.err, &dnsErr) {
		return "DNS"
	}

	return "BLOCKED"
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

// ------------------------------------------------ DOMAIN TESTING ------------------------------------------------

func (f *Finder) testDomains() (int, []string) {
	concurrency := runtime.NumCPU() * 4
	if concurrency < 32 {
		concurrency = 32
	}
	if concurrency > len(f.domains) {
		concurrency = len(f.domains)
	}

	sem := make(chan struct{}, concurrency)
	type res struct {
		ok     bool
		domain string
		reason string
	}
	results := make(chan res, len(f.domains))
	var wg sync.WaitGroup
	var okCnt int32

	for _, domain := range f.domains {
		wg.Add(1)
		sem <- struct{}{}
		go func(d string) {
			defer wg.Done()
			defer func() { <-sem }()
			ok, reason := f.checkDomain(d)
			if ok {
				atomic.AddInt32(&okCnt, 1)
			}
			results <- res{ok: ok, domain: d, reason: reason}
		}(domain)
	}

	wg.Wait()
	close(results)

	var failed []string
	outputBuffer := make([]res, 0, len(f.domains))
	for r := range results {
		outputBuffer = append(outputBuffer, r)
		if !r.ok {
			failed = append(failed, r.domain)
		}
	}

	sort.Slice(outputBuffer, func(i, j int) bool {
		return outputBuffer[i].domain < outputBuffer[j].domain
	})

	for _, r := range outputBuffer {
		if r.ok {
			fmt.Printf("  %-45s %s\n", r.domain, checkMark)
		} else {
			fmt.Printf("  %-45s %s (%s)\n", r.domain, crossMark, r.reason)
		}
	}
	fmt.Println()

	return int(okCnt), failed
}

// ------------------------------------------------ HELPERS ------------------------------------------------

func setRegistry(cfgName string) {
	k, _, err := registry.CreateKey(registry.CURRENT_USER, registryPath, registry.SET_VALUE)
	if err != nil {
		color.Red("  [WARN] Ошибка записи в реестр: %v", err)
		return
	}
	defer k.Close()
	_ = k.SetStringValue("GoodbyeZapret_LastWorkConfig", cfgName)
	_ = k.SetStringValue("GoodbyeZapret_LastStartConfig", cfgName)
}

func loadDomains() ([]string, error) {
	exePath, _ := os.Executable()
	exeDir := filepath.Dir(exePath)
	candidates := []string{filepath.Join(exeDir, "domains.txt"), "domains.txt"}

	var file *os.File
	var err error
	for _, p := range candidates {
		file, err = os.Open(p)
		if err == nil {
			break
		}
	}
	if file == nil {
		return nil, err
	}
	defer file.Close()

	var list []string
	s := bufio.NewScanner(file)
	for s.Scan() {
		line := strings.TrimSpace(s.Text())
		if line != "" && !strings.HasPrefix(line, "#") {
			list = append(list, line)
		}
	}
	return list, s.Err()
}

// --- Path Helpers ---

func resolveDirs() (toolsDir, projectDir string) {
	exePath, _ := os.Executable()
	exeDir := filepath.Dir(exePath)

	tryFind := func(base string) (string, string, bool) {
		if cfgDir, err := findConfigsDir(base); err == nil {
			projectRoot := filepath.Dir(filepath.Dir(cfgDir))
			return base, projectRoot, true
		}
		return "", "", false
	}

	if t, p, ok := tryFind(exeDir); ok {
		return t, p
	}
	if wd, err := os.Getwd(); err == nil {
		if t, p, ok := tryFind(wd); ok {
			return t, p
		}
	}
	return exeDir, exeDir
}

func findConfigsDir(startDir string) (string, error) {
	subPaths := []string{
		filepath.Join("configs", "Preset"),
		filepath.Join("Configs", "Preset"),
		filepath.Join("Project", "configs", "Preset"),
	}

	dir := startDir
	for i := 0; i < 5; i++ {
		for _, sub := range subPaths {
			p := filepath.Join(dir, sub)
			if info, err := os.Stat(p); err == nil && info.IsDir() {
				return p, nil
			}
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return "", fmt.Errorf("папка configs/Preset не найдена")
}

// --- Process Helpers ---

func runBatch(path string) {
	cmd := exec.Command("cmd", "/C", path)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	_ = cmd.Run()
}

func smartCleanup(toolsDir string) {
	if !processExists("winws.exe") && !serviceExists("GoodbyeZapret") {
		color.Cyan("  Очистка не требуется.")
		return
	}
	color.Cyan("  Очистка процессов...")

	candidates := []string{
		filepath.Join(toolsDir, "config_check", "delete_services_for_finder.bat"),
		filepath.Join(toolsDir, "delete_services_for_finder.bat"),
	}

	for _, script := range candidates {
		if _, err := os.Stat(script); err == nil {
			runBatch(script)
			return
		}
	}

	exec.Command("taskkill", "/F", "/IM", "winws.exe").Run()
}

func serviceExists(name string) bool {
	cmd := exec.Command("sc", "query", name)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	return cmd.Run() == nil
}

func processExists(proc string) bool {
	cmd := exec.Command("tasklist", "/FI", fmt.Sprintf("IMAGENAME eq %s", proc))
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	out, _ := cmd.Output()
	return strings.Contains(strings.ToLower(string(out)), strings.ToLower(proc))
}

func waitEnter() {
	fmt.Print("\nНажмите Enter для выхода...")
	bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func waitEnter2() {
	color.Cyan("  Нажмите Enter для продолжения...")
	bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func printSeparator() {
	fmt.Println(strings.Repeat("-", 79))
}

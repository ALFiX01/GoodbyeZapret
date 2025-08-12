//go:build windows
// +build windows

package main

import (
	"bufio"
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"
)

const (
	esc       = "\x1b"
	reset     = esc + "[0m"
	green     = esc + "[32m"
	yellow    = esc + "[33m"
	red       = esc + "[31m"
	cyan      = esc + "[36m"
	checkMark = green + "OK" + reset
	crossMark = red + "ERROR" + reset
)

// domains will be populated from domains.txt located next to the executable.
var domains []string

const githubPath = "/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version"

func main() {
	toolsDir, projectDir := resolveDirs()

	// ---------- читаем domains.txt ----------
	if d, err := loadDomains(); err != nil {
		fmt.Printf("%s[ERROR]%s Не удалось прочитать domains.txt: %v\n", red, reset, err)
		waitEnter()
		return
	} else if len(d) == 0 {
		fmt.Printf("%s[ERROR]%s domains.txt пуст или не содержит доменов.\n", red, reset)
		waitEnter()
		return
	} else {
		domains = d
	}

	configsDir, err := findConfigsDir(projectDir)
	if err != nil {
		fmt.Printf("%s[ERROR]%s Папка с конфигами не найдена. (%v)\n", red, reset, err)
		waitEnter()
		return
	}
	list, err := filepath.Glob(filepath.Join(configsDir, "*.bat"))
	if err != nil || len(list) == 0 {
		fmt.Printf("%s[ОШИБКА]%s В папке %q нет ни одного .bat файла.\n", red, reset, configsDir)
		waitEnter()
		return
	}
	sort.Strings(list)

	almostWorking := make([]string, 0)
	fmt.Println()
	fmt.Println(cyan, "Поиск рабочего конфига в \""+configsDir+"\" ...", reset)
	fmt.Println("-------------------------------------------------------------------------------")

	for _, cfg := range list {
		cfgName := filepath.Base(cfg)
		fmt.Printf("%s Запуск конфига %s ...%s\n", cyan, cfgName, reset)
		runBatch(cfg)
		time.Sleep(2 * time.Second) // wait a bit like in BAT

		fmt.Printf("  %sПроверка доступности доменов ...%s\n", cyan, reset)
		okCount, failedList := testDomains()
		total := len(domains)
		if okCount == total { // fully working
			setRegistry(cfgName)
			fmt.Println("-------------------------------------------------------------------------------")
			fmt.Printf("            %sНайден рабочий конфиг: %s%s\n", green, cfgName, reset)
			fmt.Println("-------------------------------------------------------------------------------")
			waitEnter2()
			smartCleanup(toolsDir)
			fmt.Printf("  %sПродолжаем поиск...%s\n", cyan, reset)
			fmt.Println("------------------------------------------------------------")
			fmt.Println()
		} else if total-okCount == 1 { // almost working
			almostWorking = append(almostWorking, fmt.Sprintf("конфиг %s не разблокировал: %s", cfgName, strings.Join(failedList, ", ")))
			fmt.Printf("  %sКонфиг %s почти работает. Не разблокирован только 1 домен.%s\n", yellow, cfgName, reset)
			smartCleanup(toolsDir)
			fmt.Printf("  %sПродолжаем поиск...%s\n", cyan, reset)
			fmt.Println("------------------------------------------------------------")
			fmt.Println()
		} else { // failed
			fmt.Printf("  %sКонфиг %s не прошёл проверку. Не разблокировано доменов: %d%s\n", red, cfgName, total-okCount, reset)
			smartCleanup(toolsDir)
			fmt.Printf("  %sПродолжаем поиск...%s\n", cyan, reset)
			fmt.Println("------------------------------------------------------------")
			fmt.Println()
		}
	}

	fmt.Printf("%s[INFO]%s Не удалось найти полностью рабочий конфиг.\n", yellow, reset)
	if len(almostWorking) > 0 {
		fmt.Println("\n-------------------------------------------------------------------------------")
		fmt.Printf("         %sНайдены почти рабочие конфиги (1 недоступный домен):%s\n", yellow, reset)
		fmt.Println("-------------------------------------------------------------------------------")
		for _, s := range almostWorking {
			fmt.Println("  ", s)
		}
		fmt.Println()
	}
	waitEnter()
}

// ------------------------------------------------ helpers ---------------------------------------------------------

func resolveDirs() (toolsDir, projectDir string) {
	// directory where executable resides (for installed binary)
	exePath, _ := os.Executable()
	exeDir := filepath.Dir(exePath)

	// helper that checks if configs can be located starting from `base` (walking upwards).
	try := func(base string) (string, string, bool) {
		if cfgDir, err := findConfigsDir(base); err == nil {
			// projectDir — родительская папка configs (..\configs\Preset -> project root)
			return base, filepath.Dir(filepath.Dir(cfgDir)), true
		}
		return "", "", false
	}

	if t, p, ok := try(exeDir); ok {
		return t, p
	}

	// useful for `go run` when exe in temp dir; try current working directory
	if wd, err := os.Getwd(); err == nil {
		if t, p, ok := try(wd); ok {
			return t, p
		}
	}

	// last resort — return exeDir and let caller handle error
	return exeDir, exeDir
}

// findConfigsDir walks up from startDir looking for known variants of configs/Preset.
func findConfigsDir(startDir string) (string, error) {
	type variantFunc func(base string) string

	variants := []variantFunc{
		func(b string) string { return filepath.Join(b, "configs", "Preset") },
		func(b string) string { return filepath.Join(b, "Configs", "Preset") },
		func(b string) string { return filepath.Join(b, "Project", "configs", "Preset") },
	}

	dir := startDir
	for {
		for _, v := range variants {
			p := v(dir)
			if info, err := os.Stat(p); err == nil && info.IsDir() {
				return p, nil
			}
		}
		parent := filepath.Dir(dir)
		if parent == dir { // reached filesystem root
			break
		}
		dir = parent
	}
	return "", fmt.Errorf("configs directory not found when walking up from %s", startDir)
}

func runBatch(path string) {
	cmd := exec.Command("cmd", "/C", path)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	_ = cmd.Run()
}

func testDomains() (okCount int, failed []string) {
	// ограничим степень параллелизма
	maxParallel := runtime.NumCPU() * 4
	if maxParallel < 8 {
		maxParallel = 8
	}
	if len(domains) < maxParallel {
		maxParallel = len(domains)
	}
	sem := make(chan struct{}, maxParallel)

	type res struct {
		ok     bool
		domain string
		reason string
	}

	results := make([]res, len(domains))
	var wg sync.WaitGroup

	for i, d := range domains {
		idx, domain := i, d
		wg.Add(1)
		sem <- struct{}{}
		go func() {
			defer wg.Done()
			defer func() { <-sem }()

			url := domain
			if strings.EqualFold(domain, "raw.githubusercontent.com") {
				url += githubPath
			}
			if !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
				url = "https://" + url
			}

			ok, reason := checkDomainRobust(domain, url)
			results[idx] = res{ok: ok, domain: domain, reason: reason}
		}()
	}

	wg.Wait()

	for _, r := range results {
		if r.ok {
			fmt.Printf("  %-45s %s\n", r.domain, checkMark)
			okCount++
		} else {
			if r.reason == "" {
				fmt.Printf("  %-45s %s\n", r.domain, crossMark)
			} else {
				fmt.Printf("  %-45s %s (%s)\n", r.domain, crossMark, r.reason)
			}
			failed = append(failed, r.domain)
		}
	}
	fmt.Println()
	return
}

// --- надёжная проверка домена с повтором и классификацией причин ---

func buildHTTPClient() *http.Client {
	return buildHTTPClientCustom(2*time.Second, 2*time.Second, 2500*time.Millisecond, 3500*time.Millisecond)
}

func buildHTTPClientCustom(dialTimeout, tlsTimeout, respHdrTimeout, overallTimeout time.Duration) *http.Client {
	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   dialTimeout,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		TLSHandshakeTimeout:   tlsTimeout,
		ResponseHeaderTimeout: respHdrTimeout,
		ExpectContinueTimeout: 300 * time.Millisecond,
		IdleConnTimeout:       30 * time.Second,
		MaxIdleConns:          100,
		MaxIdleConnsPerHost:   10,
		DisableCompression:    true,
		TLSClientConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
			NextProtos: []string{"h2", "http/1.1"},
		},
		ForceAttemptHTTP2: true,
	}
	return &http.Client{Transport: transport, Timeout: overallTimeout}
}

func checkDomainRobust(domain, url string) (bool, string) {
	dnsCtx, cancelDNS := context.WithTimeout(context.Background(), 1200*time.Millisecond)
	_, dnsErr := net.DefaultResolver.LookupIPAddr(dnsCtx, domain)
	cancelDNS()

	baseClient := buildHTTPClient()
	var lastErr error
	if ok, err := checkOnce(baseClient, domain, url); ok {
		return true, ""
	} else {
		lastErr = err
	}
	if shouldRetry(lastErr) {
		retryClient := buildHTTPClientCustom(3500*time.Millisecond, 3500*time.Millisecond, 3500*time.Millisecond, 5*time.Second)
		if ok2, err2 := checkOnce(retryClient, domain, url); ok2 {
			return true, ""
		} else {
			lastErr = err2
		}
	}

	if dnsErr != nil {
		return false, "DNS"
	}
	if lastErr != nil {
		if isTimeoutErr(lastErr) {
			return false, "TIMEOUT"
		}
		errStr := strings.ToLower(lastErr.Error())
		if strings.Contains(errStr, "reset") || strings.Contains(errStr, "connection reset") || strings.Contains(errStr, "rst") {
			return false, "RST"
		}
	}
	if !tcpReachable(domain, 1800*time.Millisecond) {
		return false, "TCP"
	}
	if !tlsHandshakeOk(domain, 2*time.Second) {
		return false, "TLS"
	}
	return false, "HTTP"
}

func checkOnce(client *http.Client, domain, url string) (bool, error) {
	// HEAD
	headCtx, cancelHead := context.WithTimeout(context.Background(), client.Timeout)
	headReq, _ := http.NewRequestWithContext(headCtx, http.MethodHead, url, nil)
	headReq.Header.Set("User-Agent", "GoodbyeZapretChecker")
	headReq.Header.Set("Accept", "*/*")
	headReq.Header.Set("Accept-Encoding", "identity")
	if resp, err := client.Do(headReq); err == nil {
		resp.Body.Close()
		cancelHead()
		return true, nil
	} else {
		cancelHead()
	}

	// GET с Range
	getCtx, cancelGet := context.WithTimeout(context.Background(), client.Timeout)
	getReq, _ := http.NewRequestWithContext(getCtx, http.MethodGet, url, nil)
	getReq.Header.Set("User-Agent", "GoodbyeZapretChecker")
	getReq.Header.Set("Range", "bytes=0-0")
	getReq.Header.Set("Accept-Encoding", "identity")
	if resp, err := client.Do(getReq); err == nil {
		resp.Body.Close()
		cancelGet()
		return true, nil
	} else {
		cancelGet()
		return false, err
	}
}

func tcpReachable(domain string, timeout time.Duration) bool {
	d := &net.Dialer{Timeout: timeout}
	conn, err := d.Dial("tcp", net.JoinHostPort(domain, "443"))
	if err != nil {
		return false
	}
	_ = conn.Close()
	return true
}

func tlsHandshakeOk(domain string, timeout time.Duration) bool {
	d := &net.Dialer{Timeout: timeout}
	conn, err := tls.DialWithDialer(d, "tcp", net.JoinHostPort(domain, "443"), &tls.Config{
		ServerName:         domain,
		MinVersion:         tls.VersionTLS12,
		InsecureSkipVerify: false,
		NextProtos:         []string{"h2", "http/1.1"},
	})
	if err != nil {
		return false
	}
	_ = conn.Close()
	return true
}

func shouldRetry(err error) bool {
	if err == nil {
		return false
	}
	if isTimeoutErr(err) {
		return true
	}
	errStr := strings.ToLower(err.Error())
	if strings.Contains(errStr, "temporary") || strings.Contains(errStr, "reset") {
		return true
	}
	return false
}

func isTimeoutErr(err error) bool {
	if err == nil {
		return false
	}
	if nErr, ok := err.(net.Error); ok {
		return nErr.Timeout()
	}
	return false
}

func smartCleanup(toolsDir string) {
	needCleanup := serviceExists("GoodbyeZapret") || processExists("winws.exe")
	if !needCleanup {
		fmt.Printf("  %sОчистка не требуется.%s\n", cyan, reset)
		return
	}
	fmt.Printf("  %sОчистка окружения ...%s\n", cyan, reset)
	script := filepath.Join(toolsDir, "delete_services_for_finder.bat")
	runBatch(script)
}

func serviceExists(name string) bool {
	cmd := exec.Command("sc", "query", name)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	if err := cmd.Run(); err != nil {
		return false
	}
	return true
}

func processExists(proc string) bool {
	cmd := exec.Command("tasklist", "/FI", fmt.Sprintf("IMAGENAME eq %s", proc))
	out, err := cmd.Output()
	if err != nil {
		return false
	}
	return strings.Contains(strings.ToLower(string(out)), strings.ToLower(proc))
}

func setRegistry(cfg string) {
	regCmd := fmt.Sprintf("reg add \"HKCU\\Software\\ALFiX inc.\\GoodbyeZapret\" /t REG_SZ /v \"GoodbyeZapret_LastWorkConfig\" /d \"%s\" /f", cfg)
	exec.Command("cmd", "/C", regCmd).Run()
	regCmd = fmt.Sprintf("reg add \"HKCU\\Software\\ALFiX inc.\\GoodbyeZapret\" /t REG_SZ /v \"GoodbyeZapret_LastStartConfig\" /d \"%s\" /f", cfg)
	exec.Command("cmd", "/C", regCmd).Run()
}

func waitEnter() {
	fmt.Print("Press Enter to exit...")
	_, _ = bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func waitEnter2() {
	fmt.Printf("  %sНажмите Enter, чтобы продолжить поиск...%s\n", cyan, reset)
	_, _ = bufio.NewReader(os.Stdin).ReadBytes('\n')
}

// loadDomains читает domains.txt в той же папке, где находится исполняемый файл
// (или в текущем каталоге при запуске `go run`) и возвращает список доменов.
func loadDomains() ([]string, error) {
	exePath, err := os.Executable()
	if err != nil {
		return nil, err
	}
	exeDir := filepath.Dir(exePath)

	// возможные места поиска: рядом с exe и в текущей директории (go run)
	candidates := []string{
		filepath.Join(exeDir, "domains.txt"),
		filepath.Join(".", "domains.txt"),
	}

	var f *os.File
	for _, p := range candidates {
		if file, err := os.Open(p); err == nil {
			f = file
			break
		}
	}
	if f == nil {
		return nil, fmt.Errorf("domains.txt не найден в %v", candidates)
	}
	defer f.Close()

	var list []string
	s := bufio.NewScanner(f)
	for s.Scan() {
		line := strings.TrimSpace(s.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		list = append(list, line)
	}
	if err := s.Err(); err != nil {
		return nil, err
	}
	return list, nil
}

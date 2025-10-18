//go:build windows
// +build windows

package main

import (
	"bufio"
	"context"
	"errors" // Добавлен для errors.As
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

	"github.com/fatih/color"
	"golang.org/x/sys/windows/registry" // Будем использовать для записи в реестр
)

// --- ИЗМЕНЕНИЕ 1: Конфигурация вынесена в константы ---
const (
	githubPath         = "/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version"
	goroutinesPerCPU   = 4
	minGoroutines      = 8
	fastDialTimeout    = 2 * time.Second
	fastTLSHandshake   = 2 * time.Second
	fastResponseHeader = 2500 * time.Millisecond
	fastClientTimeout  = 4 * time.Second
	slowDialTimeout    = 4 * time.Second
	slowTLSHandshake   = 4 * time.Second
	slowResponseHeader = 4 * time.Second
	slowClientTimeout  = 6 * time.Second
)

var (
	checkMark = color.GreenString("OK")
	crossMark = color.RedString("ERROR")
)

// --- ИЗМЕНЕНИЕ 2: Основная логика вынесена в структуру Finder ---
type Finder struct {
	toolsDir      string
	projectDir    string
	configsDir    string
	domains       []string
	fastClient    *http.Client
	retryClient   *http.Client
	almostWorking []string
}

// NewFinder создает и инициализирует новый экземпляр Finder.
func NewFinder() (*Finder, error) {
	domains, err := loadDomains()
	if err != nil {
		return nil, fmt.Errorf("не удалось прочитать domains.txt: %w", err)
	}
	if len(domains) == 0 {
		return nil, errors.New("domains.txt пуст или не содержит доменов")
	}

	toolsDir, projectDir := resolveDirs()
	configsDir, err := findConfigsDir(projectDir)
	if err != nil {
		return nil, fmt.Errorf("папка с конфигами не найдена: %w", err)
	}

	return &Finder{
		toolsDir:    toolsDir,
		projectDir:  projectDir,
		configsDir:  configsDir,
		domains:     domains,
		fastClient:  buildHTTPClient(fastDialTimeout, fastTLSHandshake, fastResponseHeader, fastClientTimeout),
		retryClient: buildHTTPClient(slowDialTimeout, slowTLSHandshake, slowResponseHeader, slowClientTimeout),
	}, nil
}

// Run запускает основной процесс поиска конфигураций.
func (f *Finder) Run() {
	list, err := filepath.Glob(filepath.Join(f.configsDir, "*.bat"))
	if err != nil || len(list) == 0 {
		color.Red("[ОШИБКА] В папке %q нет ни одного .bat файла.", f.configsDir)
		return
	}
	sort.Strings(list)

	fmt.Println()
	color.Cyan("Поиск рабочего конфига в \"%s\" ...", f.configsDir)
	printSeparator()

	for _, cfgPath := range list {
		f.testConfig(cfgPath)
	}

	f.printSummary()
}

// testConfig запускает и проверяет один конфигурационный файл.
func (f *Finder) testConfig(cfgPath string) {
	cfgName := filepath.Base(cfgPath)
	color.Cyan(" Запуск конфига %s ...", cfgName)
	runBatch(cfgPath)
	time.Sleep(2 * time.Second)

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
		fmt.Printf("            %s\n", color.GreenString("Найден рабочий конфиг: %s", cfgName))
		printSeparator()
		waitEnter2()
	} else if total-okCount == 1 {
		f.almostWorking = append(f.almostWorking, fmt.Sprintf("конфиг %s не разблокировал: %s", cfgName, strings.Join(failedList, ", ")))
		color.Yellow("  Конфиг %s почти работает. Не разблокирован только 1 домен.", cfgName)
	} else {
		color.Red("  Конфиг %s не прошёл проверку. Не разблокировано доменов: %d", cfgName, total-okCount)
	}
}

// printSummary выводит итоговую информацию после завершения поиска.
func (f *Finder) printSummary() {
	color.Yellow("[INFO] Не удалось найти полностью рабочий конфиг.")
	if len(f.almostWorking) > 0 {
		fmt.Println()
		printSeparator()
		color.Yellow("         Найдены почти рабочие конфиги (1 недоступный домен):")
		printSeparator()
		for _, s := range f.almostWorking {
			fmt.Println("  ", s)
		}
		fmt.Println()
	}
}

// --- ИЗМЕНЕНИЕ 3: Главная функция стала простой и понятной ---
func main() {
	finder, err := NewFinder()
	if err != nil {
		color.Red("[ERROR] %v", err)
		waitEnter()
		return
	}

	finder.Run()
	waitEnter()
}

// ------------------------------------------------ helpers ---------------------------------------------------------

// --- ИЗМЕНЕНИЕ 4: Радикально упрощенная и надежная проверка домена ---
func (f *Finder) checkDomain(domain string) (bool, string) {
	url := "https://" + domain
	if strings.EqualFold(domain, "raw.githubusercontent.com") {
		url += githubPath
	}

	err := f.checkOnce(f.fastClient, url)
	if err == nil {
		return true, ""
	}

	if shouldRetry(err) {
		err = f.checkOnce(f.retryClient, url)
		if err == nil {
			return true, ""
		}
	}

	return false, classifyError(err)
}

func (f *Finder) checkOnce(client *http.Client, url string) error {
	ctx, cancel := context.WithTimeout(context.Background(), client.Timeout)
	defer cancel()
	req, _ := http.NewRequestWithContext(ctx, http.MethodHead, url, nil)
	req.Header.Set("User-Agent", "GoodbyeZapretFinder")
	if resp, err := client.Do(req); err == nil {
		resp.Body.Close()
		return nil
	}
	// Если HEAD не удался, пробуем GET с Range
	req, _ = http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	req.Header.Set("User-Agent", "GoodbyeZapretFinder")
	req.Header.Set("Range", "bytes=0-0")
	if resp, err := client.Do(req); err == nil {
		resp.Body.Close()
		return nil
	} else {
		return err
	}
}

func (f *Finder) testDomains() (okCount int, failed []string) {
	maxParallel := runtime.NumCPU() * goroutinesPerCPU
	if maxParallel < minGoroutines {
		maxParallel = minGoroutines
	}
	if len(f.domains) < maxParallel {
		maxParallel = len(f.domains)
	}
	sem := make(chan struct{}, maxParallel)

	type res struct {
		ok     bool
		domain string
		reason string
	}
	results := make(chan res, len(f.domains))
	var wg sync.WaitGroup

	for _, domain := range f.domains {
		wg.Add(1)
		sem <- struct{}{}
		go func(d string) {
			defer wg.Done()
			defer func() { <-sem }()
			ok, reason := f.checkDomain(d)
			results <- res{ok: ok, domain: d, reason: reason}
		}(domain)
	}
	wg.Wait()
	close(results)

	for r := range results {
		if r.ok {
			fmt.Printf("  %-45s %s\n", r.domain, checkMark)
			okCount++
		} else {
			fmt.Printf("  %-45s %s (%s)\n", r.domain, crossMark, r.reason)
			failed = append(failed, r.domain)
		}
	}
	fmt.Println()
	return
}

// --- ИЗМЕНЕНИЕ 5: Идиоматичная работа с реестром через Go ---
func setRegistry(cfgName string) {
	keyPath := `Software\ALFiX inc.\GoodbyeZapret`
	k, _, err := registry.CreateKey(registry.CURRENT_USER, keyPath, registry.SET_VALUE)
	if err != nil {
		color.Red("  [WARN] Не удалось записать в реестр: %v", err)
		return
	}
	defer k.Close()
	_ = k.SetStringValue("GoodbyeZapret_LastWorkConfig", cfgName)
	_ = k.SetStringValue("GoodbyeZapret_LastStartConfig", cfgName)
}

// ... Остальные функции (загрузка доменов, поиск папок, запуск .bat и т.д.) ...
// Они в основном остаются без изменений, кроме classifyError и shouldRetry.

func classifyError(err error) string {
	if err == nil {
		return ""
	}
	var netErr net.Error
	if errors.As(err, &netErr) {
		if netErr.Timeout() {
			return "TIMEOUT"
		}
	}
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		return "DNS"
	}
	var opErr *net.OpError
	if errors.As(err, &opErr) {
		return strings.ToUpper(opErr.Op)
	}
	return "HTTP"
}

func shouldRetry(err error) bool {
	if err == nil {
		return false
	}
	var netErr net.Error
	return errors.As(err, &netErr) && (netErr.Timeout() || netErr.Temporary())
}

func buildHTTPClient(dialTimeout, tlsTimeout, respHdrTimeout, overallTimeout time.Duration) *http.Client {
	return &http.Client{
		Transport: &http.Transport{
			Proxy: http.ProxyFromEnvironment,
			DialContext: (&net.Dialer{
				Timeout: dialTimeout, KeepAlive: 30 * time.Second,
			}).DialContext,
			TLSHandshakeTimeout:   tlsTimeout,
			ResponseHeaderTimeout: respHdrTimeout,
			ForceAttemptHTTP2:     true,
		},
		Timeout: overallTimeout,
	}
}

func resolveDirs() (toolsDir, projectDir string) {
	exePath, _ := os.Executable()
	exeDir := filepath.Dir(exePath)
	try := func(base string) (string, string, bool) {
		if cfgDir, err := findConfigsDir(base); err == nil {
			return base, filepath.Dir(filepath.Dir(cfgDir)), true
		}
		return "", "", false
	}
	if t, p, ok := try(exeDir); ok {
		return t, p
	}
	if wd, err := os.Getwd(); err == nil {
		if t, p, ok := try(wd); ok {
			return t, p
		}
	}
	return exeDir, exeDir
}

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
		if parent == dir {
			break
		}
		dir = parent
	}
	return "", fmt.Errorf("папка configs не найдена при поиске от %s", startDir)
}

func runBatch(path string) {
	cmd := exec.Command("cmd", "/C", path)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	_ = cmd.Run()
}

func smartCleanup(toolsDir string) {
	needCleanup := serviceExists("GoodbyeZapret") || processExists("winws.exe")
	if !needCleanup {
		color.Cyan("  Очистка не требуется.")
		return
	}
	color.Cyan("  Очистка окружения ...")

	// теперь ищем скрипт в подпапке config_check
	script := filepath.Join(toolsDir, "config_check", "delete_services_for_finder.bat")

	runBatch(script)
}

func serviceExists(name string) bool {
	cmd := exec.Command("sc", "query", name)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	return cmd.Run() == nil
}

func processExists(proc string) bool {
	cmd := exec.Command("tasklist", "/FI", fmt.Sprintf("IMAGENAME eq %s", proc))
	out, err := cmd.Output()
	if err != nil {
		return false
	}
	return strings.Contains(strings.ToLower(string(out)), strings.ToLower(proc))
}

func waitEnter() {
	fmt.Print("\nНажмите Enter для выхода...")
	_, _ = bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func waitEnter2() {
	color.Cyan("  Нажмите Enter, чтобы продолжить поиск...")
	_, _ = bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func printSeparator() {
	fmt.Println("-------------------------------------------------------------------------------")
}

func loadDomains() ([]string, error) {
	exePath, _ := os.Executable()
	exeDir := filepath.Dir(exePath)
	candidates := []string{filepath.Join(exeDir, "domains.txt"), "./domains.txt"}
	var f *os.File
	for _, p := range candidates {
		if file, err := os.Open(p); err == nil {
			f = file
			break
		}
	}
	if f == nil {
		return nil, fmt.Errorf("domains.txt не найден")
	}
	defer f.Close()
	var list []string
	s := bufio.NewScanner(f)
	for s.Scan() {
		line := strings.TrimSpace(s.Text())
		if line != "" && !strings.HasPrefix(line, "#") {
			list = append(list, line)
		}
	}
	return list, s.Err()
}

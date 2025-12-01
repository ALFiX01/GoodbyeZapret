//go:build windows
// +build windows

package main

import (
	"bufio"
	"context"
	"errors"
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
	userAgent    = "GoodbyeZapretFinder/2.1"

	// Тайминги (синхронизированы с Checker)
	fastDialTimeout    = 2 * time.Second
	fastTLSHandshake   = 2 * time.Second
	fastResponseHeader = 2500 * time.Millisecond
	fastCheckTimeout   = 3 * time.Second // Таймаут для быстрой проверки
	slowCheckTimeout   = 6 * time.Second // Таймаут для retry (увеличен)

	// Пауза после запуска .bat файла перед проверкой
	serviceInitDelay = 1500 * time.Millisecond
)

var (
	checkMark = color.GreenString("OK")
	crossMark = color.RedString("ERROR")
)

// --- ИЗМЕНЕНИЕ 1: Единый Transport (как в Checker) ---
func buildHTTPTransport() *http.Transport {
	return &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout: fastDialTimeout,
			// Отключаем KeepAlive, т.к. мы делаем 1 запрос к домену
			// и тут же разрываем соединение. Это экономит ресурсы ОС.
			KeepAlive: -1,
		}).DialContext,
		TLSHandshakeTimeout:   fastTLSHandshake,
		ResponseHeaderTimeout: fastResponseHeader,
		ForceAttemptHTTP2:     true,
		DisableKeepAlives:     true, // Важно: закрывать сокет сразу
		DisableCompression:    true, // Экономим CPU
		MaxIdleConns:          100,
	}
}

type Finder struct {
	toolsDir      string
	projectDir    string
	configsDir    string
	domains       []string
	client        *http.Client // Один клиент для всего
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

	// Используем один клиент с Timeout=0 (таймауты контролируем через Context)
	tr := buildHTTPTransport()
	client := &http.Client{Transport: tr, Timeout: 0}

	return &Finder{
		toolsDir:   toolsDir,
		projectDir: projectDir,
		configsDir: configsDir,
		domains:    domains,
		client:     client,
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
		if !f.testConfig(cfgPath) {
			// Если найден идеальный конфиг, testConfig вернет true,
			// и мы можем остановить перебор (опционально).
			// Но текущая логика Finder подразумевает ожидание выбора пользователя,
			// поэтому продолжаем или выходим внутри testConfig.
		}
	}

	f.printSummary()
}

// Возвращает true, если конфиг идеален и пользователь решил остановиться
func (f *Finder) testConfig(cfgPath string) bool {
	cfgName := filepath.Base(cfgPath)
	color.Cyan(" Запуск конфига %s ...", cfgName)

	runBatch(cfgPath)
	time.Sleep(serviceInitDelay)

	color.Cyan("  Проверка доступности доменов ...")
	okCount, failedList := f.testDomains()
	total := len(f.domains)

	// Очистка после теста
	defer func() {
		smartCleanup(f.toolsDir)
		color.Cyan("  Продолжаем поиск...")
		printSeparator()
		fmt.Println()
	}()

	if okCount == total {
		setRegistry(cfgName)
		printSeparator()
		fmt.Printf("            %s\n", color.GreenString("НАЙДЕН РАБОЧИЙ КОНФИГ: %s", cfgName))
		printSeparator()
		// Здесь можно сделать return true, если хотим авто-выход
		waitEnter2()
		return true
	} else if total-okCount == 1 {
		msg := fmt.Sprintf("конфиг %s (не работает: %s)", cfgName, strings.Join(failedList, ", "))
		f.almostWorking = append(f.almostWorking, msg)
		color.Yellow("  Конфиг %s почти работает. Недоступен всего 1 домен.", cfgName)
	} else {
		color.Red("  Конфиг %s: доступно %d/%d (FAIL)", cfgName, okCount, total)
	}

	return false
}

func (f *Finder) printSummary() {
	color.Yellow("[INFO] Автоматический поиск завершен.")
	if len(f.almostWorking) > 0 {
		fmt.Println()
		printSeparator()
		color.Yellow("         Кандидаты (1 ошибка):")
		printSeparator()
		for _, s := range f.almostWorking {
			fmt.Println("  ", s)
		}
		fmt.Println()
	}
}

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

// ------------------------------------------------ LOGIC ---------------------------------------------------------

// --- ИЗМЕНЕНИЕ 2: Логика проверки 1-в-1 как в Checker ---
func (f *Finder) checkDomain(domain string) (bool, string) {
	url := f.buildURL(domain)

	// 1. Быстрая проверка
	err := f.checkOnce(url, fastCheckTimeout)
	if err == nil {
		return true, ""
	}

	// 2. Retry (медленная проверка), если ошибка сетевая
	if shouldRetry(err) {
		err = f.checkOnce(url, slowCheckTimeout)
		if err == nil {
			return true, ""
		}
	}

	return false, classifyError(err)
}

func (f *Finder) buildURL(domain string) string {
	if strings.EqualFold(domain, "raw.githubusercontent.com") {
		return "https://" + domain + githubPath
	}
	return "https://" + domain
}

func (f *Finder) checkOnce(url string, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	// Используем GET с Range 0-0 (самый надежный метод для DPI)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return err
	}

	req.Header.Set("User-Agent", userAgent)
	req.Header.Set("Range", "bytes=0-0")
	req.Header.Set("Accept-Encoding", "identity")

	resp, err := f.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Любой ответ от сервера (даже 403/500) означает, что DPI пробит и соединение есть
	return nil
}

// --- ИЗМЕНЕНИЕ 3: Улучшенный параллелизм ---
func (f *Finder) testDomains() (int, []string) {
	// Динамический расчет горутин: минимум 32, максимум len(domains)
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

	// Собираем результаты и сортируем неудачные для вывода
	var failed []string
	// Для красивого вывода нужно собрать всё, иначе при параллельном принте строки порвутся
	// (хотя fmt.Print атомарен, но лучше собрать)
	outputBuffer := make([]res, 0, len(f.domains))
	for r := range results {
		outputBuffer = append(outputBuffer, r)
		if !r.ok {
			failed = append(failed, r.domain)
		}
	}

	// Вывод (можно сортировать, чтобы список был стабильным)
	sort.Slice(outputBuffer, func(i, j int) bool {
		return outputBuffer[i].domain < outputBuffer[j].domain
	})

	for _, r := range outputBuffer {
		if r.ok {
			fmt.Printf("  %-45s %s\n", r.domain, checkMark)
		} else {
			fmt.Printf("  %-45s %s (%s)\n", r.domain, crossMark, r.reason)
		}
	}
	fmt.Println()

	return int(okCnt), failed
}

// ------------------------------------------------ HELPERS ------------------------------------------------

func setRegistry(cfgName string) {
	k, _, err := registry.CreateKey(registry.CURRENT_USER, registryPath, registry.SET_VALUE)
	if err != nil {
		color.Red("  [WARN] Ошибка записи в реестр: %v", err)
		return
	}
	defer k.Close()
	_ = k.SetStringValue("GoodbyeZapret_LastWorkConfig", cfgName)
	_ = k.SetStringValue("GoodbyeZapret_LastStartConfig", cfgName)
}

func classifyError(err error) string {
	if err == nil {
		return ""
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return "TIMEOUT"
	}
	var netErr net.Error
	if errors.As(err, &netErr) && netErr.Timeout() {
		return "TIMEOUT"
	}
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		return "DNS"
	}
	var opErr *net.OpError
	if errors.As(err, &opErr) {
		return strings.ToUpper(opErr.Op)
	}
	return "CONN"
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
			// Если нашли configs, предполагаем структуру Project/configs/Preset
			// Нам нужен корень Project (на 2 уровня выше configs)
			// configsDir = .../Project/configs/Preset
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
	// Варианты расположения папки с пресетами
	subPaths := []string{
		filepath.Join("configs", "Preset"),
		filepath.Join("Configs", "Preset"),
		filepath.Join("Project", "configs", "Preset"),
	}

	dir := startDir
	// Ищем вверх по дереву каталогов
	for i := 0; i < 5; i++ { // Ограничим глубину поиска вверх
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
	// Проверяем, запущены ли процессы, чтобы лишний раз не дергать скрипт
	if !processExists("winws.exe") && !serviceExists("GoodbyeZapret") {
		color.Cyan("  Очистка не требуется.")
		return
	}
	color.Cyan("  Очистка процессов...")
	
	// Пытаемся найти скрипт очистки в типичных местах
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
	
	// Фолбэк: если скрипта нет, пробуем убить процесс напрямую
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
	color.Cyan("  Нажмите Enter для продолжения...")
	bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func printSeparator() {
	fmt.Println(strings.Repeat("-", 79))
}

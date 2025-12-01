package main

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/fatih/color"
	"golang.org/x/sys/windows/registry"
)

const (
	// Таймауты
	fastDialTimeout    = 2 * time.Second
	fastTLSHandshake   = 2 * time.Second
	fastResponseHeader = 2500 * time.Millisecond
	fastClientTimeout  = 3 * time.Second

	slowClientTimeout = 6 * time.Second // Увеличил, чтобы retry имел больше шансов

	// Конфигурация
	userAgent      = "GoodbyeZapretChecker/2.1"
	registryPath   = `Software\ALFiX inc.\GoodbyeZapret`
	githubCheckURI = "/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version"
)

// --- Транспорт ---
func buildHTTPTransport() *http.Transport {
	return &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout: fastDialTimeout,
			// KeepAlive не нужен для разовых проверок разных доменов,
			// отключение экономит файловые дескрипторы
			KeepAlive: -1,
		}).DialContext,
		TLSHandshakeTimeout:   fastTLSHandshake,
		ResponseHeaderTimeout: fastResponseHeader,
		ForceAttemptHTTP2:     true,
		DisableKeepAlives:     true, // Важно: закрываем соединение сразу после запроса
		DisableCompression:    true,
		MaxIdleConns:          100,
	}
}

type Checker struct {
	client     *http.Client
	githubPath string
}

func NewChecker(githubPath string, tr *http.Transport) *Checker {
	return &Checker{
		// Используем один клиент, таймауты регулируем через Context
		client:     &http.Client{Transport: tr, Timeout: 0},
		githubPath: githubPath,
	}
}

func (c *Checker) Check(domain string) (bool, string) {
	url := c.buildURL(domain)

	// Попытка 1: Быстрая
	err := c.checkOnce(url, fastClientTimeout)
	if err == nil {
		return true, ""
	}

	// Попытка 2: Медленная (Retry), только если ошибка сетевая
	if shouldRetry(err) {
		err = c.checkOnce(url, slowClientTimeout)
		if err == nil {
			return true, ""
		}
	}

	return false, classifyError(err)
}

func (c *Checker) buildURL(domain string) string {
	if domain == "raw.githubusercontent.com" {
		return "https://" + domain + c.githubPath
	}
	return "https://" + domain
}

func (c *Checker) checkOnce(url string, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return err
	}

	req.Header.Set("User-Agent", userAgent)
	// Трюк с Range 0-0 отличный, он экономит трафик, оставляем
	req.Header.Set("Range", "bytes=0-0")
	req.Header.Set("Accept-Encoding", "identity")

	resp, err := c.client.Do(req)
	if err != nil {
		return err
	}
	// Обязательно закрываем Body через defer для гарантии
	defer resp.Body.Close()

	// Дополнительная проверка статуса, если нужно (например, не считать 500 OK)
	// Но для проверки DPI доступности даже 500 или 403 часто значит "доступ есть"
	return nil
}

func main() {
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

	// Упрощенная логика параллелизма.
	// Для сетевых задач можно брать N * CPU, но не меньше определенного числа.
	concurrency := runtime.NumCPU() * 4
	if concurrency < 32 {
		concurrency = 32
	}
	if concurrency > len(domains) {
		concurrency = len(domains)
	}

	fmt.Printf(" Запуск проверки: потоков=%d, доменов=%d, CPU=%d\n",
    	concurrency, len(domains), runtime.NumCPU())

	tr := buildHTTPTransport()
	checker := NewChecker(githubCheckURI, tr)

	var okCnt int32
	var wg sync.WaitGroup

	// Используем семафор для ограничения параллелизма
	sem := make(chan struct{}, concurrency)

	fmt.Println(" " + strings.Repeat("-", 50))

	for _, d := range domains {
		wg.Add(1)
		sem <- struct{}{} // Захват слота

		go func(domain string) {
			defer wg.Done()
			defer func() { <-sem }() // Освобождение слота

			ok, reason := checker.Check(domain)
			printResult(domain, ok, reason)

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
		// Небольшая пауза перед выходом, чтобы юзер успел прочитать
		time.Sleep(1 * time.Second)
		os.Exit(0)
	} else {
		color.Red(msg)
		time.Sleep(3 * time.Second)
		os.Exit(1)
	}
}

// Вывод результатов потокобезопасно (через fmt в одной горутине - нет,
// но fmt.Printf в Go атомарен для вывода строки, так что текст не смешается)
func printResult(domain string, ok bool, reason string) {
	// Форматирование с фиксированной шириной для красоты
	if ok {
		fmt.Printf(" %-40s %s\n", domain, color.GreenString("OK"))
	} else {
		fmt.Printf(" %-40s %s\n", domain, color.RedString("ERR [%s]", reason))
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

	// Преаллокация слайса (примерно), чтобы уменьшить перевыделение памяти
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
	// Рекомендуется ретраить при таймаутах или временных ошибках сети
	if errors.Is(err, context.DeadlineExceeded) {
		return true
	}
	var netErr net.Error
	if errors.As(err, &netErr) {
		return netErr.Timeout() || netErr.Temporary()
	}
	return false
}

func writeRegistrySuccess(batFile string) {
	k, _, err := registry.CreateKey(registry.CURRENT_USER, registryPath, registry.SET_VALUE)
	if err != nil {
		// Логирование ошибки реестра (опционально)
		return
	}
	defer k.Close()
	_ = k.SetStringValue("GoodbyeZapret_LastWorkConfig", batFile)
	_ = k.SetStringValue("GoodbyeZapret_LastStartConfig", batFile)
}

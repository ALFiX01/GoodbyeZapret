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

type Checker struct {
	fastClient  *http.Client
	retryClient *http.Client
	githubPath  string
}

func NewChecker(githubPath string) *Checker {
	return &Checker{
		fastClient:  buildHTTPClient(fastDialTimeout, fastTLSHandshake, fastResponseHeader, fastClientTimeout),
		retryClient: buildHTTPClient(slowDialTimeout, slowTLSHandshake, slowResponseHeader, slowClientTimeout),
		githubPath:  githubPath,
	}
}

func (c *Checker) Check(domain string) (bool, string) {
	url := c.buildURL(domain)
	err := c.checkOnce(c.fastClient, url)
	if err == nil {
		return true, ""
	}
	if shouldRetry(err) {
		err = c.checkOnce(c.retryClient, url)
		if err == nil {
			return true, ""
		}
	}
	return false, classifyError(err)
}

func (c *Checker) buildURL(domain string) string {
	target := domain
	if domain == "raw.githubusercontent.com" {
		target += c.githubPath
	}
	return "https://" + target
}

func (c *Checker) checkOnce(client *http.Client, url string) error {
	ctx, cancel := context.WithTimeout(context.Background(), client.Timeout)
	defer cancel()
	headReq, _ := http.NewRequestWithContext(ctx, http.MethodHead, url, nil)
	headReq.Header.Set("User-Agent", "GoodbyeZapretChecker/2.0")
	if resp, err := client.Do(headReq); err == nil {
		resp.Body.Close()
		return nil
	}
	getReq, _ := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	getReq.Header.Set("User-Agent", "GoodbyeZapretChecker/2.0")
	getReq.Header.Set("Range", "bytes=0-0")
	resp, err := client.Do(getReq)
	if err != nil {
		return err
	}
	resp.Body.Close()
	return nil
}

func main() {
	var batFile string
	if len(os.Args) > 1 {
		batFile = os.Args[1]
	}
	domains, err := loadDomains()
	if err != nil {
		color.Red("Ошибка чтения domains.txt: %v\n", err)
		os.Exit(1)
	}
	if len(domains) == 0 {
		color.Red("Файл domains.txt пуст\n")
		os.Exit(1)
	}
	checker := NewChecker("/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version")
	var okCnt int32
	var wg sync.WaitGroup
	maxParallel := runtime.NumCPU() * goroutinesPerCPU
	if maxParallel < minGoroutines {
		maxParallel = minGoroutines
	}
	if len(domains) < maxParallel {
		maxParallel = len(domains)
	}
	sem := make(chan struct{}, maxParallel)
	for _, d := range domains {
		wg.Add(1)
		sem <- struct{}{}
		go func(domain string) {
			defer wg.Done()
			defer func() { <-sem }()
			if ok, reason := checker.Check(domain); ok {
				fmt.Printf("  %-37s %s\n", domain, color.GreenString("OK"))
				atomic.AddInt32(&okCnt, 1)
			} else {
				fmt.Printf("  %-37s %s\n", domain, color.RedString("ОШИБКА (%s)", reason))
			}
		}(d)
	}
	wg.Wait()
	fmt.Println()

	// *** ВОТ ЭТО ИЗМЕНЕНИЕ ***
	// Выбираем цвет для итогового сообщения в зависимости от результата.
	if int(okCnt) == len(domains) {
		// Если все домены доступны - выводим зеленым.
		color.Green("Результат: %d/%d доменов доступны", okCnt, len(domains))
	} else {
		// Если есть хоть одна ошибка - выводим красным.
		color.Red("Результат: %d/%d доменов доступны", okCnt, len(domains))
	}

	fmt.Println()
	time.Sleep(2 * time.Second)
	if int(okCnt) == len(domains) {
		if batFile != "" {
			writeRegistrySuccess(batFile)
		}
		os.Exit(0)
	}
	os.Exit(1)
}

func loadDomains() ([]string, error) {
	exePath, err := os.Executable()
	if err != nil {
		return nil, fmt.Errorf("не удалось получить путь к exe: %w", err)
	}
	dir := filepath.Dir(exePath)
	filePath := filepath.Join(dir, "domains.txt")
	f, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("не удалось открыть %s: %w", filePath, err)
	}
	defer f.Close()
	var domains []string
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line != "" && !strings.HasPrefix(line, "#") {
			domains = append(domains, line)
		}
	}
	return domains, scanner.Err()
}

func buildHTTPClient(dialTimeout, tlsTimeout, respHdrTimeout, overallTimeout time.Duration) *http.Client {
	return &http.Client{
		Transport: &http.Transport{
			Proxy: http.ProxyFromEnvironment,
			DialContext: (&net.Dialer{
				Timeout:   dialTimeout,
				KeepAlive: 30 * time.Second,
			}).DialContext,
			TLSHandshakeTimeout:   tlsTimeout,
			ResponseHeaderTimeout: respHdrTimeout,
			ExpectContinueTimeout: 1 * time.Second,
			ForceAttemptHTTP2:     true,
			MaxIdleConns:          100,
			MaxIdleConnsPerHost:   10,
		},
		Timeout: overallTimeout,
	}
}

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
	if errors.As(err, &netErr) && (netErr.Timeout() || netErr.Temporary()) {
		return true
	}
	return false
}

func writeRegistrySuccess(batFile string) {
	k, _, err := registry.CreateKey(registry.CURRENT_USER, `Software\ALFiX inc.\GoodbyeZapret`, registry.SET_VALUE)
	if err != nil {
		return
	}
	defer k.Close()
	_ = k.SetStringValue("GoodbyeZapret_LastWorkConfig", batFile)
	_ = k.SetStringValue("GoodbyeZapret_LastStartConfig", batFile)
}
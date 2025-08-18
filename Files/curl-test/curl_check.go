package main

import (
	"bufio"
	"context"
	"crypto/tls"
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

	"golang.org/x/sys/windows/registry"
)

// Добавим ANSI-цвета для более наглядного вывода
const (
	colorReset  = "\033[0m"
	colorGreen  = "\033[32m"
	colorRed    = "\033[31m"
	colorYellow = "\033[33m"
)

func main() {
	// ― Имя бат-конфига первым аргументом
	var batFile string
	if len(os.Args) > 1 {
		batFile = os.Args[1]
	}

	// Загружаем список доменов из файла domains.txt рядом с исполняемым файлом
	domains, err := loadDomains()
	if err != nil {
		fmt.Printf("%sОшибка чтения domains.txt:%s %v\n", colorRed, colorReset, err)
		os.Exit(1)
	}

	if len(domains) == 0 {
		fmt.Printf("%sФайл domains.txt пуст или не содержит доменов%s\n", colorRed, colorReset)
		os.Exit(1)
	}

	// Используем корректный путь для raw.githubusercontent.com
	githubPath := "/ALFiX01/GoodbyeZapret/main/GoodbyeZapret_Version"

	var okCnt int32
	wg := sync.WaitGroup{}
	// Ограничим степень параллелизма, чтобы ускорить общее время за счёт меньшего контеншена
	maxParallel := runtime.NumCPU() * 4
	if maxParallel < 8 {
		maxParallel = 8
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

			// Составляем URL (для GitHub — с путём к файлу версии)
			target := domain
			if domain == "raw.githubusercontent.com" {
				target += githubPath
			}
			url := "https://" + target

			ok, reason := checkDomainRobust(domain, url)
			if ok {
				fmt.Printf("  %-37s OK\n", domain)
				atomic.AddInt32(&okCnt, 1)
			} else {
				fmt.Printf("  %-37s ОШИБКА (%s)\n", domain, reason)
			}
		}(d)
	}
	wg.Wait()

	// Выводим краткую сводку
	fmt.Printf("\n %sРезультат:%s %d/%d доменов доступны\n", colorYellow, colorReset, okCnt, len(domains))

	// Pause for 2 seconds before exiting to give the user a moment to see the results
	time.Sleep(2 * time.Second)

	if int(okCnt) == len(domains) {
		if batFile != "" {
			// Пишем в реестр, как делал .bat
			k, _, _ := registry.CreateKey(registry.CURRENT_USER, `Software\ALFiX inc.\GoodbyeZapret`, registry.SET_VALUE)
			_ = k.SetStringValue("GoodbyeZapret_LastWorkConfig", batFile)
			_ = k.SetStringValue("GoodbyeZapret_LastStartConfig", batFile)
			k.Close()
		}
		os.Exit(0)
	}
	os.Exit(1)
}

// loadDomains читает файл domains.txt в той же папке, где расположен exe,
// и возвращает список доменов (по одному в строке, допускаются комментарии #).
func loadDomains() ([]string, error) {
	exePath, err := os.Executable()
	if err != nil {
		return nil, err
	}
	dir := filepath.Dir(exePath)
	f, err := os.Open(filepath.Join(dir, "domains.txt"))
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var domains []string
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue // пропускаем пустые и закомментированные строки
		}
		domains = append(domains, line)
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	return domains, nil
}

// buildHTTPClient создаёт http.Client с более реалистичными таймаутами, снижающими ложные срабатывания
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

// checkDomainFast делает двухшаговую HTTP‑проверку с быстрыми таймаутами и понятной диагностикой.
// 1) Быстрый HEAD; 2) при неудаче — GET с Range: bytes=0-0 (некоторые сервера блокируют/не поддерживают HEAD)
// Дополнительно даёт краткую причину сбоя: DNS, TCP, HTTP, TIMEOUT
func checkDomainRobust(domain, url string) (bool, string) {
	// 0) DNS с чуть более щадящим таймаутом
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
		// Один повтор с увеличенными таймаутами
		retryClient := buildHTTPClientCustom(3500*time.Millisecond, 3500*time.Millisecond, 3500*time.Millisecond, 5*time.Second)
		if ok2, err2 := checkOnce(retryClient, domain, url); ok2 {
			return true, ""
		} else {
			lastErr = err2
		}
	}

	// Классифицируем последнюю ошибку
	// Перепроверим быстрый TCP → TLS, чтобы точнее понять границу сбоя
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
	// TCP
	if !tcpReachable(domain, 1800*time.Millisecond) {
		return false, "TCP"
	}

	// TLS
	if !tlsHandshakeOk(domain, 2*time.Second) {
		return false, "TLS"
	}

	// Если TCP/TLS в порядке, но HTTP не отвечает вовремя
	// Попробуем различить TIMEOUT и RST
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
		if isTimeoutErr(err) {
			// Продолжим к GET, затем вернём последнюю ошибку
		}
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
	// В редких случаях кратковременные сбои сети, позволим один повтор
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
	nErr, ok := err.(net.Error)
	return ok && nErr.Timeout()
}

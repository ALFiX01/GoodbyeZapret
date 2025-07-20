package main

import (
	"bufio"
	"fmt"
	"net"
	"net/http"
	"os"
	"path/filepath"
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

	githubPath := "/ALFiX01/GoodbyeZapret/refs/heads/main/GoodbyeZapret_Version"

	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   1 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		TLSHandshakeTimeout: 1 * time.Second,
	}

	client := &http.Client{
		Transport: transport,
		Timeout:   1500 * time.Millisecond,
	}

	var okCnt int32
	wg := sync.WaitGroup{}
	for _, d := range domains {
		wg.Add(1)
		go func(domain string) {
			defer wg.Done()
			url := domain
			if domain == "raw.githubusercontent.com" {
				url += githubPath
			}
			url = "https://" + url // HTTPS быстрее и надёжнее
			req, _ := http.NewRequest(http.MethodHead, url, nil)
			req.Header.Set("User-Agent", "GoodbyeZapretChecker")
			if _, err := client.Do(req); err == nil {
				fmt.Printf("  %-37s %sOK%s\n", domain, colorGreen, colorReset)
				atomic.AddInt32(&okCnt, 1)
			} else {
				fmt.Printf("  %-37s %sОШИБКА%s\n", domain, colorRed, colorReset)
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

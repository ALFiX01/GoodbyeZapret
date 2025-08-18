package main

import (
	"bytes"
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/getlantern/systray"
)

//go:embed icon.ico
var iconData []byte

func main() {
	if isAlreadyRunning() {
		fmt.Println("GoodbyeZapretTray.exe уже запущен. Второй экземпляр не нужен.")
		return
	}

	systray.Run(onReady, onExit)
}

func isAlreadyRunning() bool {
	exeName := filepath.Base(os.Args[0])
	cmd := exec.Command("tasklist", "/FI", "IMAGENAME eq "+exeName)
	out, err := cmd.Output()
	if err != nil {
		return false
	}
	// Считаем, сколько раз встречается exeName в выводе
	count := bytes.Count(bytes.ToLower(out), []byte(strings.ToLower(exeName)))
	return count > 1 // >1, т.к. текущий процесс тоже попадёт в список
}

func onReady() {
	systray.SetIcon(iconData)
	systray.SetTitle("GoodbyeZapret Control")
	systray.SetTooltip("Управление GoodbyeZapret")

	mOpenLauncher := systray.AddMenuItem("Открыть Launcher", "Открывает Launcher.bat")
	mOpenFolder := systray.AddMenuItem("Открыть папку GoodbyeZapret", "Открывает папку проекта в проводнике")
	systray.AddSeparator()
	mExitProc := systray.AddMenuItem("Выйти (остановить winws.exe)", "Остановить winws.exe")
	mDelete := systray.AddMenuItem("Удалить обход", "Удаляет службу GoodbyeZapret и связанные процессы")
	systray.AddSeparator()
	mQuit := systray.AddMenuItem("Завершить программу", "Закрыть трей-утилиту")

	go func() {
		for {
			select {
			case <-mOpenLauncher.ClickedCh:
				openLauncher()
			case <-mOpenFolder.ClickedCh:
				openParentFolder()
			case <-mExitProc.ClickedCh:
				killProcess("winws.exe")
			case <-mDelete.ClickedCh:
				deleteBypass()
			case <-mQuit.ClickedCh:
				systray.Quit()
			}
		}
	}()
}

func onExit() {
	// Очистка если надо
}

func openLauncher() {
	// Получаем текущий путь к exe файлу
	exePath, err := os.Executable()
	if err != nil {
		fmt.Println("Ошибка получения пути к exe:", err)
		return
	}

	// Получаем директорию exe файла
	exeDir := filepath.Dir(exePath)

	// Переходим на один уровень выше (родительская папка)
	parentDir := filepath.Dir(exeDir)

	// Формируем путь к Launcher.bat
	launcherPath := filepath.Join(parentDir, "Launcher.bat")

	// Проверяем существование файла
	if _, err := os.Stat(launcherPath); os.IsNotExist(err) {
		fmt.Println("Файл Launcher.bat не найден по пути:", launcherPath)
		return
	}

	// Запускаем Launcher.bat с повышенными правами через powershell, передавая путь к батнику
	runCmd("powershell", "-NoProfile", "-Command", "Start-Process -FilePath '"+launcherPath+"' -Verb RunAs -ArgumentList '--elevated'")
}

func openParentFolder() {
	exePath, err := os.Executable()
	if err != nil {
		fmt.Println("Ошибка получения пути к exe:", err)
		return
	}

	exeDir := filepath.Dir(exePath)
	parentDir := filepath.Dir(exeDir)

	// Проверяем, что папка существует
	if _, err := os.Stat(parentDir); os.IsNotExist(err) {
		fmt.Println("Папка не найдена:", parentDir)
		return
	}

	runCmd("explorer", parentDir)
}

func runCmd(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
}

func serviceExists(name string) bool {
	err := exec.Command("sc", "query", name).Run()
	return err == nil
}

func stopAndDeleteService(name string) {
	if serviceExists(name) {
		fmt.Println("Stopping service:", name)
		runCmd("sc", "stop", name)
		time.Sleep(3 * time.Second)
		fmt.Println("Deleting service:", name)
		runCmd("sc", "delete", name)
	} else {
		fmt.Println("Service not found:", name)
	}
}

func processExists(procName string) bool {
	out, _ := exec.Command("tasklist", "/FI", "IMAGENAME eq "+procName).Output()
	return bytes.Contains(bytes.ToLower(out), []byte(strings.ToLower(procName)))
}

func killProcess(procName string) {
	if processExists(procName) {
		fmt.Println("Terminating process:", procName)
		runCmd("taskkill", "/F", "/IM", procName)
	} else {
		fmt.Println("Process not found:", procName)
	}
}

func deleteBypass() {
	stopAndDeleteService("GoodbyeZapret")
	killProcess("winws.exe")
	for _, svc := range []string{"WinDivert", "monkey"} {
		stopAndDeleteService(svc)
	}
}

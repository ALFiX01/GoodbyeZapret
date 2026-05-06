package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"unsafe"
)

const th32csSnapProcess = 0x00000002

var (
	kernel32                    = syscall.NewLazyDLL("kernel32.dll")
	procCreateToolhelpSnapshot = kernel32.NewProc("CreateToolhelp32Snapshot")
	procProcess32First         = kernel32.NewProc("Process32FirstW")
	procProcess32Next          = kernel32.NewProc("Process32NextW")
)

type processEntry32 struct {
	Size              uint32
	CntUsage          uint32
	ProcessID         uint32
	DefaultHeapID     uintptr
	ModuleID          uint32
	CntThreads        uint32
	ParentProcessID   uint32
	PriClassBase      int32
	Flags             uint32
	ExeFile           [syscall.MAX_PATH]uint16
}

func trayProcessAlreadyRunning(exeName string) bool {
	snapshot, _, _ := procCreateToolhelpSnapshot.Call(th32csSnapProcess, 0)
	if snapshot == 0 || snapshot == uintptr(syscall.InvalidHandle) {
		return false
	}
	defer syscall.CloseHandle(syscall.Handle(snapshot))

	currentPID := uint32(os.Getpid())
	var entry processEntry32
	entry.Size = uint32(unsafe.Sizeof(entry))

	ok, _, _ := procProcess32First.Call(snapshot, uintptr(unsafe.Pointer(&entry)))
	for ok != 0 {
		name := syscall.UTF16ToString(entry.ExeFile[:])
		if entry.ProcessID != currentPID && strings.EqualFold(name, exeName) {
			return true
		}
		ok, _, _ = procProcess32Next.Call(snapshot, uintptr(unsafe.Pointer(&entry)))
	}

	return false
}

func main() {
	exe, err := os.Executable()
	if err != nil {
		os.Exit(1)
	}

	trayDir := filepath.Dir(exe)
	toolsDir := filepath.Dir(trayDir)
	runtimeDir := filepath.Join(toolsDir, "tray-runtime")
	realExe := filepath.Join(runtimeDir, "GoodbyeZapretTray.exe")
	tmpDir := filepath.Join(runtimeDir, "tmp")

	if _, err := os.Stat(realExe); err != nil {
		os.Exit(1)
	}

	if trayProcessAlreadyRunning(filepath.Base(realExe)) {
		os.Exit(0)
	}

	if err := os.MkdirAll(tmpDir, 0700); err != nil {
		os.Exit(1)
	}

	cmd := exec.Command(realExe, os.Args[1:]...)
	cmd.Dir = runtimeDir
	cmd.Env = append(os.Environ(),
		"TEMP="+tmpDir,
		"TMP="+tmpDir,
		"TMPDIR="+tmpDir,
	)

	if err := cmd.Start(); err != nil {
		os.Exit(1)
	}
}

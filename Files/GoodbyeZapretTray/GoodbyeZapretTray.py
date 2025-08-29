#!/usr/bin/env python3
"""
GoodbyeZapret Tray Application
Системный трей для управления GoodbyeZapret сервисами
"""

import sys
import os
import threading
import time
from typing import Optional, Tuple
from pathlib import Path
import logging

try:
    import pystray
    from pystray import MenuItem as item
    from PIL import Image
    import win32event
    import win32api
    import winerror
    import winreg
    import win32service
    import psutil
    import tkinter as tk
    from tkinter import messagebox, simpledialog
except ImportError as e:
    print(f"Ошибка импорта: {e}")
    print("Установите необходимые библиотеки:")
    print("pip install pystray pillow pywin32 psutil")
    sys.exit(1)

# Константы
MUTEX_NAME = "ALFiX-GoodbyeZapretTray-Mutex-9A8B7C6D"
APP_NAME = "GoodbyeZapret"
ICON_NAME = "GoodbyeZapret"
STATUS_CHECK_INTERVAL = 5  # Интервал проверки статуса в секундах

# Пути к скриптам
SCRIPT_NAMES = {
    'launcher': "Launcher.bat",
    'kill_wiws': "TRAY_kill_wiws.bat",
    'delete_services': "delete_services.bat",
    'updater': "Updater.exe",
    'start_service': "TRAY_start_service.bat"
}

ALLOWED_EXTENSIONS = {'.bat', '.exe'}


class GoodbyeZapretTray:
    """Основной класс приложения трея"""

    def __init__(self):
        self.mutex: Optional[int] = None
        self.icon: Optional[pystray.Icon] = None
        self.current_dir: Path
        self.parent_dir: Path
        self.active_icon: Optional[Image.Image] = None
        self.inactive_icon: Optional[Image.Image] = None
        self.winws_icon: Optional[Image.Image] = None
        self.status_check_thread: Optional[threading.Thread] = None
        self.stop_status_check = False
        self._setup_paths()
        self._setup_logging()

    def _setup_logging(self) -> None:
        """Настройка логирования"""
        logging.basicConfig(
            filename=str(self.current_dir / 'goodbyezapret_tray.log'),
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )

    def _setup_paths(self) -> None:
        """Настройка путей к директориям"""
        try:
            if getattr(sys, 'frozen', False):
                exe_path = Path(sys.executable)
                self.current_dir = exe_path.parent
                # Для exe в C:\GoodbyeZapret\tools\tray\
                # parent_dir должен быть C:\GoodbyeZapret\
                self.parent_dir = self.current_dir.parent.parent
            else:
                script_path = Path(__file__).resolve()
                self.current_dir = script_path.parent
                # Для скрипта в Files/GoodbyeZapretTray/
                # parent_dir должен быть Files/
                self.parent_dir = self.current_dir.parent

        except Exception as e:
            raise RuntimeError(f"Не удалось определить пути: {e}")

    def check_and_acquire_mutex(self) -> bool:
        """Проверка и получение мьютекса для единственного экземпляра"""
        try:
            self.mutex = win32event.CreateMutex(None, 1, MUTEX_NAME)
            if win32api.GetLastError() == winerror.ERROR_ALREADY_EXISTS:
                if self.mutex:
                    win32api.CloseHandle(self.mutex)
                self.mutex = None
                return False
            return True
        except Exception as e:
            logging.error(f"Ошибка при работе с мьютексом: {e}")
            return False

    def release_mutex(self) -> None:
        """Освобождение мьютекса"""
        if self.mutex:
            try:
                win32api.CloseHandle(self.mutex)
                self.mutex = None
                logging.info("Мьютекс успешно освобожден.")
            except Exception as e:
                logging.error(f"Ошибка при освобождении мьютекса: {e}")

    def _safe_startfile(self, file_path: Path, description: str) -> None:
        """Безопасный запуск файла: проверка пути и расширения"""
        try:
            file_path = file_path.resolve()

            # Проверка существования
            if not file_path.exists():
                logging.error(f"Файл не найден: {file_path}")
                return

            # Проверка, что путь внутри parent_dir
            if not str(file_path).startswith(str(self.parent_dir)):
                logging.error(f"Попытка запустить файл вне разрешенной папки: {file_path}")
                return

            # Проверка допустимого расширения
            if file_path.suffix.lower() not in ALLOWED_EXTENSIONS:
                logging.error(f"Недопустимое расширение: {file_path.suffix}")
                return

            os.startfile(str(file_path))
            logging.info(f"Запущен {description}: {file_path}")

        except Exception as e:
            logging.error(f"Не удалось запустить {description}: {e}")

    def _run_script(self, script_name: str, description: str) -> None:
        """Запуск скрипта с безопасной проверкой"""
        script_path = self.current_dir / SCRIPT_NAMES[script_name]
        self._safe_startfile(script_path, description)

    def open_launcher(self, icon: pystray.Icon, item) -> None:
        """Открытие Launcher.bat"""
        launcher_path = self.parent_dir / SCRIPT_NAMES['launcher']
        self._safe_startfile(launcher_path, "Launcher.bat")

    def open_main_folder(self, icon: pystray.Icon, item) -> None:
        """Открытие основной папки GoodbyeZapret"""
        try:
            os.startfile(str(self.parent_dir))
        except Exception as e:
            logging.error(f"Не удалось открыть папку: {e}")

    def stop_bypass_service(self, icon: pystray.Icon, item) -> None:
        """Остановка обхода"""
        self._run_script('kill_wiws', 'TRAY_kill_wiws.bat')

    def run_delete_script(self, icon: pystray.Icon, item) -> None:
        """Удаление сервисов"""
        self._run_script('delete_services', 'delete_services.bat')

    def run_update_script(self, icon: pystray.Icon, item) -> None:
        """Запуск обновления"""
        self._run_script('updater', 'Updater.exe')

    def resume_bypass(self, icon: pystray.Icon, item) -> None:
        """Возобновление обхода"""
        self._run_script('start_service', 'TRAY_start_service.bat')

    def exit_tray_app(self, icon: pystray.Icon, item) -> None:
        """Завершение приложения"""
        self.stop_status_check = True
        if self.status_check_thread and self.status_check_thread.is_alive():
            self.status_check_thread.join(timeout=2)
        icon.stop()

    def _check_service_status(self, service_name: str) -> Tuple[bool, bool]:
        """Проверка статуса Windows сервиса через Windows API"""
        try:
            # Проверка существования и статуса сервиса
            try:
                handle = win32service.OpenService(
                    win32service.OpenSCManager(None, None, win32service.SC_MANAGER_CONNECT),
                    service_name,
                    win32service.SERVICE_QUERY_STATUS
                )

                # Получение статуса сервиса
                status = win32service.QueryServiceStatus(handle)
                win32service.CloseServiceHandle(handle)

                exists = True
                running = status[1] == win32service.SERVICE_RUNNING

            except win32service.error as e:
                # ERROR_SERVICE_DOES_NOT_EXIST = 1060 (0x424)
                if e.winerror == 1060:
                    exists = False
                    running = False
                else:
                    logging.error(f"Ошибка при проверке сервиса {service_name}: {e}")
                    exists = False
                    running = False

            return exists, running

        except Exception as e:
            logging.error(f"Неожиданная ошибка при проверке сервиса {service_name}: {e}")
            return False, False

    def _check_process_status(self, process_name: str) -> bool:
        """Проверка статуса процесса через psutil"""
        try:
            for proc in psutil.process_iter(['name']):
                try:
                    if proc.info['name'].lower() == process_name.lower():
                        return True
                except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                    continue
            return False
        except Exception as e:
            logging.error(f"Ошибка при проверке процесса {process_name}: {e}")
            return False

    def _read_current_config(self) -> Optional[str]:
        """Чтение текущего конфига из реестра"""
        try:
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\ALFiX inc.\GoodbyeZapret", 0, winreg.KEY_READ)
            config, _ = winreg.QueryValueEx(key, "GoodbyeZapret_Config")
            winreg.CloseKey(key)
            return config if config != "None" else None
        except (FileNotFoundError, OSError):
            return None
        except Exception as e:
            logging.error(f"Ошибка при чтении реестра: {e}")
            return None

    def _read_goodbye_zapret_version(self) -> Optional[str]:
        """Чтение версии GoodbyeZapret из реестра"""
        try:
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\ALFiX inc.\GoodbyeZapret", 0, winreg.KEY_READ)
            version, _ = winreg.QueryValueEx(key, "GoodbyeZapret_Version")
            winreg.CloseKey(key)
            return version if version != "None" else None
        except (FileNotFoundError, OSError):
            return None
        except Exception as e:
            logging.error(f"Ошибка при чтении версии из реестра: {e}")
            return None

    def _find_netrogat_path(self) -> Optional[Path]:
        """Поиск пути к netrogat.txt"""
        candidates = [
            self.parent_dir / "lists" / "netrogat.txt",
            Path("C:/GoodbyeZapret/lists/netrogat.txt"),
            Path("C:/GoodbyeZapret/Project/lists/netrogat.txt"),
            self.current_dir / "lists" / "netrogat.txt",
            self.current_dir.parent / "lists" / "netrogat.txt",
            self.current_dir.parent.parent / "lists" / "netrogat.txt",
            self.current_dir.parent.parent.parent / "lists" / "netrogat.txt"
        ]
        for candidate in candidates:
            if candidate.exists():
                logging.info(f"Найден netrogat.txt по пути: {candidate}")
                return candidate
        logging.error("netrogat.txt не найден ни по одному пути")
        return None

    def add_exceptions(self, icon: pystray.Icon, item) -> None:
        """Добавление исключений в файл netrogat.txt (улучшенный интерфейс)"""
        root = None
        dialog = None
        try:
            root = tk.Tk()
            root.withdraw()

            dialog = tk.Toplevel(root)
            dialog.title("Добавить исключения")
            dialog.geometry("400x350")
            dialog.resizable(False, False)

            tk.Label(dialog, text="Введите домены (по одному на строку):", font=("Arial", 10)).pack(anchor="w", padx=10,
                                                                                                    pady=5)

            text_box = tk.Text(dialog, height=10, width=40)
            text_box.pack(padx=10, pady=5, fill=tk.BOTH, expand=True)

            button_frame = tk.Frame(dialog)
            button_frame.pack(pady=10)

            def paste_from_clipboard():
                try:
                    clipboard_text = root.clipboard_get()
                    if clipboard_text:
                        text_box.insert(tk.END, clipboard_text + "\n")
                except tk.TclError:
                    messagebox.showwarning("Ошибка", "Буфер обмена пуст или недоступен.", parent=dialog)

            def on_add():
                domains_input = text_box.get("1.0", tk.END).strip()
                if not domains_input:
                    messagebox.showwarning("Предупреждение", "Вы не ввели ни одного домена.", parent=dialog)
                    return

                domains = [d.strip() for d in domains_input.split('\n') if d.strip()]
                if not domains:
                    messagebox.showwarning("Предупреждение", "Список доменов пустой.", parent=dialog)
                    return

                netrogat_file = self._find_netrogat_path()
                if not netrogat_file:
                    messagebox.showerror("Ошибка", "Файл netrogat.txt не найден. Проверьте установку GoodbyeZapret.",
                                         parent=dialog)
                    return

                existing_domains = set()
                try:
                    with open(netrogat_file, 'r', encoding='utf-8') as f:
                        for line in f:
                            line = line.strip()
                            if line and not line.startswith('#'):
                                existing_domains.add(line)
                except Exception as e:
                    messagebox.showerror("Ошибка", f"Не удалось прочитать файл: {e}", parent=dialog)
                    return

                new_domains = [d for d in domains if d not in existing_domains]
                if not new_domains:
                    messagebox.showinfo("Информация", "Все указанные домены уже присутствуют.", parent=dialog)
                    return

                try:
                    with open(netrogat_file, 'w', encoding='utf-8') as f:
                        f.write("#Удалить, если браузер не поддерживает ECH\n")
                        for domain in sorted(existing_domains.union(new_domains)):
                            f.write(f"{domain}\n")
                        f.write("#Конец блока для удаления\n")

                    messagebox.showinfo("Успех",
                                        f"Добавлено {len(new_domains)} новых доменов:\n\n" + "\n".join(new_domains),
                                        parent=dialog)
                    dialog.destroy()

                except Exception as e:
                    messagebox.showerror("Ошибка", f"Не удалось записать файл: {e}", parent=dialog)

            def on_cancel():
                dialog.destroy()

            # Добавляем кнопки
            tk.Button(button_frame, text="Вставить из буфера", command=paste_from_clipboard, width=18).pack(
                side=tk.LEFT, padx=5)
            tk.Button(button_frame, text="Добавить", command=on_add, width=12).pack(side=tk.LEFT, padx=5)
            tk.Button(button_frame, text="Отмена", command=on_cancel, width=12).pack(side=tk.LEFT, padx=5)

            dialog.protocol("WM_DELETE_WINDOW", on_cancel)
            dialog.grab_set()
            dialog.wait_window()

        except Exception as e:
            messagebox.showerror("Ошибка", f"Произошла ошибка: {e}")
        finally:
            if dialog:
                dialog.destroy()
            if root:
                root.destroy()

    def _check_goodbye_zapret_status(self) -> str:
        """Проверка общего статуса GoodbyeZapret"""
        try:
            # Проверяем службу GoodbyeZapret
            gz_exists, _ = self._check_service_status("GoodbyeZapret")

            # Проверяем процесс winws.exe
            winws_running = self._check_process_status("winws.exe")

            # Возвращаем строковый статус
            if gz_exists and winws_running:
                return "active"
            elif winws_running:
                return "winws_only"
            else:
                return "inactive"

        except Exception as e:
            logging.error(f"Ошибка при проверке статуса GoodbyeZapret: {e}")
            return "error"

    def _update_icon_status(self) -> None:
        """Обновление иконки в зависимости от статуса"""
        if not self.icon:
            return

        try:
            # Проверяем отдельно службу и процесс
            gz_exists, _ = self._check_service_status("GoodbyeZapret")
            winws_running = self._check_process_status("winws.exe")

            # Получаем версию GoodbyeZapret
            version = self._read_goodbye_zapret_version()
            version_suffix = f" v{version}" if version else ""

            # Выбираем соответствующую иконку и подсказку
            if gz_exists and winws_running:
                # Служба установлена И winws.exe запущен
                new_icon = self.active_icon
                tooltip = f"{APP_NAME}{version_suffix} - Активен (служба + winws)"
            elif winws_running:
                # Только winws.exe запущен, служба не установлена
                new_icon = self.winws_icon
                tooltip = f"{APP_NAME}{version_suffix} - Winws работает (без службы)"
            else:
                # Ничего не работает
                new_icon = self.inactive_icon
                tooltip = f"{APP_NAME}{version_suffix} - Неактивен"

            # Проверяем, что иконка загружена
            if new_icon:
                self.icon.icon = new_icon
                self.icon.title = tooltip
            else:
                logging.warning("Не удалось загрузить иконку для текущего состояния")

        except Exception as e:
            logging.error(f"Ошибка при обновлении иконки: {e}")

    def _status_check_worker(self) -> None:
        """Рабочий поток для периодической проверки статуса"""
        while not self.stop_status_check:
            try:
                self._update_icon_status()
                time.sleep(STATUS_CHECK_INTERVAL)
            except Exception as e:
                logging.error(f"Ошибка в потоке проверки статуса: {e}")
                time.sleep(STATUS_CHECK_INTERVAL)

    def show_status(self, icon: pystray.Icon, item) -> None:
        """Отображение статуса всех компонентов"""
        root = None
        dialog = None
        try:
            # Статус GoodbyeZapret сервиса
            gz_exists, gz_running = self._check_service_status("GoodbyeZapret")
            if gz_exists:
                gz_status = "Установлен"
                gz_color = "green"
            else:
                gz_status = "Не установлен"
                gz_color = "red"
            gz_line = f"GoodbyeZapret: {gz_status}"

            # Статус winws.exe процесса
            winws_running = self._check_process_status("winws.exe")
            winws_status = "Работает" if winws_running else "Не работает"
            winws_color = "green" if winws_running else "red"
            winws_line = f"Winws.exe: {winws_status}"

            # Статус WinDivert/monkey
            divert_exists, divert_running = self._check_service_status("WinDivert")
            if not divert_exists:
                monkey_exists, monkey_running = self._check_service_status("monkey")
                if monkey_exists:
                    divert_line = "monkey: Установлен"
                    divert_color = "green"
                else:
                    divert_line = "WinDivert/monkey: Не установлен"
                    divert_color = "red"
            else:
                divert_line = "WinDivert: Установлен"
                divert_color = "green"

            # Информация о текущем конфиге
            current_config = self._read_current_config()
            if current_config:
                config_line = f"Конфиг: {current_config}"
            else:
                config_line = "Конфиг: Не определен"

            # Информация о версии
            version = self._read_goodbye_zapret_version()
            if version:
                version_line = f"Версия: {version}"
            else:
                version_line = "Версия: Не определена"

            # Общий статус
            if gz_exists and winws_running:
                overall_status = "Активен (служба + winws)"
                status_color = "green"
            elif winws_running:
                overall_status = "Winws работает (без службы)"
                status_color = "orange"
            else:
                overall_status = "Неактивен"
                status_color = "red"

            status_line = f"Общий статус: {overall_status}"

            # Создание кастомного окна
            root = tk.Tk()
            root.withdraw()

            dialog = tk.Toplevel(root)
            dialog.title(f"{APP_NAME}: Состояние")
            dialog.geometry("400x280")
            dialog.resizable(False, False)

            frame = tk.Frame(dialog)
            frame.pack(padx=20, pady=20, fill=tk.BOTH, expand=True)

            tk.Label(frame, text=status_line, font=("Arial", 12, "bold"), fg=status_color).pack(
                anchor="w", pady=5)
            tk.Label(frame, text=gz_line, font=("Arial", 10), fg=gz_color).pack(anchor="w", pady=2)
            tk.Label(frame, text=winws_line, font=("Arial", 10), fg=winws_color).pack(anchor="w", pady=2)
            tk.Label(frame, text=divert_line, font=("Arial", 10), fg=divert_color).pack(anchor="w", pady=2)
            tk.Label(frame, text=config_line, font=("Arial", 10)).pack(anchor="w", pady=2)
            tk.Label(frame, text=version_line, font=("Arial", 10)).pack(anchor="w", pady=2)

            button = tk.Button(dialog, text="OK", command=dialog.destroy, width=10)
            button.pack(pady=10)

            dialog.protocol("WM_DELETE_WINDOW", dialog.destroy)
            dialog.grab_set()
            dialog.wait_window()

        except Exception as e:
            logging.error(f"Ошибка при получении статуса: {e}")
            messagebox.showerror("Ошибка", f"Произошла ошибка при отображении статуса: {e}")
        finally:
            if dialog:
                dialog.destroy()
            if root:
                root.destroy()

    def _load_icons(self) -> None:
        """Загрузка иконок приложения"""
        try:
            # Попытка загрузки из ресурсов PyInstaller
            if hasattr(sys, '_MEIPASS'):
                base_path = Path(sys._MEIPASS)
            else:
                base_path = self.current_dir

            # Загружаем активную иконку (зеленая или обычная)
            active_icon_path = base_path / "icon_active.ico"
            if active_icon_path.exists():
                self.active_icon = Image.open(active_icon_path)
            else:
                # Если активной иконки нет, используем обычную
                icon_path = base_path / "icon.ico"
                if icon_path.exists():
                    self.active_icon = Image.open(icon_path)
                else:
                    raise FileNotFoundError(f"Файл иконки не найден: {icon_path}")

            # Загружаем неактивную иконку (красная или серая)
            inactive_icon_path = base_path / "icon_inactive.ico"
            if inactive_icon_path.exists():
                self.inactive_icon = Image.open(inactive_icon_path)
            else:
                # Если неактивной иконки нет, используем ту же обычную
                self.inactive_icon = self.active_icon

            # Загружаем иконку для состояния "Winws работает (без службы)"
            winws_icon_path = base_path / "icon_winws_running.ico"
            if winws_icon_path.exists():
                self.winws_icon = Image.open(winws_icon_path)
            else:
                # Если иконки winws нет, используем активную
                self.winws_icon = self.active_icon

            logging.info("Иконки успешно загружены")

        except Exception as e:
            logging.error(f"Не удалось загрузить иконки: {e}")
            raise RuntimeError(f"Не удалось загрузить иконки: {e}")

    def _create_menu(self) -> pystray.Menu:
        """Создание меню трея"""
        return pystray.Menu(
            item('Открыть Launcher', self.open_launcher, default=True),
            item('Открыть папку GoodbyeZapret', self.open_main_folder),
            item('Запустить Updater', self.run_update_script),
            item('Состояние GoodbyeZapret', self.show_status),
            pystray.Menu.SEPARATOR,
            item('Добавить исключения обхода', self.add_exceptions),
            pystray.Menu.SEPARATOR,
            item('Возобновить обход', self.resume_bypass),
            item('Удалить обход', self.run_delete_script),
            item('Остановить обход', self.stop_bypass_service),
            pystray.Menu.SEPARATOR,
            item('Завершить Tray программу', self.exit_tray_app)
        )

    def run(self) -> None:
        """Основной метод запуска приложения"""
        try:
            # Проверка единственного экземпляра
            if not self.check_and_acquire_mutex():
                logging.info("Приложение уже запущено. Завершаю работу дубликата.")
                return

            # Загрузка иконок
            self._load_icons()

            # Создание иконки трея с начальной иконкой
            initial_icon = self.active_icon if self.active_icon else self.inactive_icon
            self.icon = pystray.Icon(
                ICON_NAME,
                initial_icon,
                APP_NAME,
                self._create_menu()
            )

            # Запуск потока проверки статуса
            self.status_check_thread = threading.Thread(
                target=self._status_check_worker,
                daemon=True
            )
            self.status_check_thread.start()

            logging.info("Приложение запущено и свернуто в трей.")
            self.icon.run()

        except Exception as e:
            logging.error(f"Критическая ошибка: {e}")
        finally:
            self.stop_status_check = True
            if self.status_check_thread and self.status_check_thread.is_alive():
                self.status_check_thread.join(timeout=2)
            self.release_mutex()
            logging.info("Приложение завершило работу.")


def main():
    """Точка входа в приложение"""
    try:
        app = GoodbyeZapretTray()
        app.run()
    except KeyboardInterrupt:
        logging.info("\nПриложение прервано пользователем.")
    except Exception as e:
        logging.error(f"Неожиданная ошибка: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
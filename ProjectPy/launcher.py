import os
import sys
import ctypes
import subprocess
import winreg
import time
import requests
import zipfile
import locale
import shutil
import socket
import platform
from colorama import init, Fore, Style
import msvcrt
import functools

# Добавляем импорт для работы с hosts-файлом
from hosts import HostsManager
from proxy_domains import PROXY_DOMAINS

# Задаём версию прямо в коде
CURRENT_GZ_VERSION = "1.3.0"

# Инициализация colorama - используем autoreset=False для лучшей производительности
init(autoreset=False)

# Используем кэширование для часто вызываемых функций
@functools.lru_cache(maxsize=8)
def is_admin():
    """Проверка прав администратора с кэшированием результата"""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def restart_as_admin():
    """Перезапуск программы с правами администратора"""
    if not is_admin():
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
        sys.exit(0)

def check_language():
    """Проверка языка интерфейса (должен быть ru-RU)"""
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Control Panel\International")
        locale_name = winreg.QueryValueEx(key, "LocaleName")[0]
        winreg.CloseKey(key)
        return locale_name == "ru-RU"
    except:
        return False

# Переменная для хранения информации о состоянии сети
_last_internet_check = 0
_internet_status = False

def check_internet(force_check=False):
    """Улучшенная проверка интернет-соединения с несколькими методами"""
    global _last_internet_check, _internet_status
    
    # Повторная проверка не чаще чем раз в 30 секунд, если не требуется принудительная проверка
    current_time = time.time()
    if not force_check and current_time - _last_internet_check < 30:
        return _internet_status
    
    # Метод 1: Проверка через DNS-серверы (самый быстрый)
    try:
        socket.setdefaulttimeout(2)
        # Пробуем несколько DNS-серверов, начиная с российских
        dns_servers = ["77.88.8.8", "1.1.1.1", "8.8.8.8"]
        for dns in dns_servers:
            try:
                socket.create_connection((dns, 53), timeout=1)
                _internet_status = True
                _last_internet_check = current_time
                return True
            except:
                continue
    except:
        pass
    
    # Метод 2: Проверка через HTTP запрос к надежным сайтам
    try:
        urls = ["http://www.yandex.ru", "http://www.google.com"]
        for url in urls:
            try:
                response = requests.head(url, timeout=2)
                if response.status_code == 200:
                    _internet_status = True
                    _last_internet_check = current_time
                    return True
            except:
                continue
    except:
        pass
    
    # Метод 3: Проверка локальной сети через шлюз по умолчанию
    try:
        # Получаем IP-адрес шлюза по умолчанию
        gateway = run_command("ipconfig | findstr /i \"Default Gateway\"", timeout=2)
        if gateway:
            # Извлекаем IP-адрес из строки
            import re
            match = re.search(r"(\d+\.\d+\.\d+\.\d+)", gateway)
            if match:
                gateway_ip = match.group(1)
                # Проверяем доступность шлюза
                ping_result = run_command(f"ping -n 1 -w 1000 {gateway_ip}", timeout=2)
                if "Reply from" in ping_result:
                    # Шлюз доступен, но интернет может отсутствовать
                    # Возвращаем True, так как локальная сеть работает
                    _internet_status = True
                    _last_internet_check = current_time
                    return True
    except:
        pass
    
    # Если все методы не сработали, считаем что интернета нет
    _internet_status = False
    _last_internet_check = current_time
    return False

def check_internet_with_retry():
    """Проверка подключения к интернету с повторными попытками"""
    # Первая проверка
    if check_internet(force_check=True):
        return True
        
    print(f"{Fore.LIGHTYELLOW_EX}Проверка подключения к интернету...{Fore.RESET}")
    
    # Делаем еще 2 попытки с интервалом в 2 секунды
    for i in range(2):
        time.sleep(2)
        print(f"{Fore.LIGHTYELLOW_EX}Повторная проверка ({i+1}/2)...{Fore.RESET}", end="")
        if check_internet(force_check=True):
            print(f"{Fore.LIGHTGREEN_EX} Соединение установлено!{Fore.RESET}")
            return True
        print(f"{Fore.LIGHTRED_EX} Неудачно{Fore.RESET}")
    
    print(f"{Fore.LIGHTRED_EX}Проверка подключения завершилась неудачей{Fore.RESET}")
    return False

@functools.lru_cache(maxsize=1)
def check_goodbyezapret_installed():
    """Проверка наличия установленного GoodbyeZapret с кэшированием результата"""
    path = f"{os.environ['SystemDrive']}\\GoodbyeZapret"
    
    # Более быстрая проверка - проверяем только наличие директории
    if not os.path.exists(path):
        return False
        
    # Дополнительная проверка ключевых файлов
    required_files = [
        "bin\\winws.exe",
        "Configs"
    ]
    
    for file in required_files:
        if not os.path.exists(os.path.join(path, file)):
            return False
            
    return True

# Кэш для значений реестра
_registry_cache = {}

def get_registry_value(key_path, value_name, default=""):
    """Получение значения из реестра с кэшированием"""
    cache_key = f"{key_path}:{value_name}"
    if cache_key in _registry_cache:
        return _registry_cache[cache_key]
    
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path)
        value = winreg.QueryValueEx(key, value_name)[0]
        winreg.CloseKey(key)
        _registry_cache[cache_key] = value
        return value
    except:
        _registry_cache[cache_key] = default
        return default

def set_registry_value(key_path, value_name, value_type, value):
    """Установка значения в реестр"""
    try:
        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, key_path)
        winreg.SetValueEx(key, value_name, 0, value_type, value)
        winreg.CloseKey(key)
        return True
    except:
        return False

def delete_registry_value(key_path, value_name):
    """Удаление значения из реестра"""
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path, 0, winreg.KEY_SET_VALUE)
        winreg.DeleteValue(key, value_name)
        winreg.CloseKey(key)
        return True
    except:
        return False

def run_command(command, shell=True, timeout=15):
    """Запуск команды и получение результата с ограничением по времени"""
    try:
        # Добавляем таймаут для всех команд
        result = subprocess.run(
            command, 
            shell=shell, 
            check=False,  # Не вызывать исключение при ненулевом коде возврата
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE, 
            text=True,
            timeout=timeout,  # Важно для предотвращения зависаний
            encoding='cp866'  # Используем правильную кодировку для Windows
        )
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        print(f"{Fore.LIGHTRED_EX}Превышено время ожидания выполнения команды{Fore.RESET}")
        return ""
    except Exception as e:
        return ""

def is_process_running(process_name):
    """Проверка, запущен ли процесс"""
    try:
        output = run_command(f'tasklist /FI "IMAGENAME eq {process_name}"')
        return process_name.lower() in output.lower()
    except:
        return False

def create_directories():
    """Создание необходимых директорий"""
    system_drive = os.environ['SystemDrive']
    dirs_to_create = [
        f"{system_drive}\\GoodbyeZapret",
        f"{system_drive}\\GoodbyeZapret\\bin",
        f"{system_drive}\\GoodbyeZapret\\Configs",
        f"{system_drive}\\GoodbyeZapret\\lists"
    ]
    
    for directory in dirs_to_create:
        if not os.path.exists(directory):
            try:
                os.makedirs(directory, exist_ok=True)
                print(f"{Fore.LIGHTGREEN_EX}Создана директория: {directory}{Fore.RESET}")
            except Exception as e:
                print(f"{Fore.LIGHTRED_EX}Ошибка при создании директории {directory}: {str(e)}{Fore.RESET}")
                return False
    return True

def get_current_version(file_path):
    """Получение текущей версии из файла с проверкой существования"""
    if not os.path.exists(file_path):
        print(f"{Fore.LIGHTYELLOW_EX}Файл версии не найден: {file_path}{Fore.RESET}")
        return "0"
    
    try:
        with open(file_path, 'r') as f:
            version = f.read().strip()
            if not version:
                return "0"
            return version
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}Ошибка при чтении файла {file_path}: {str(e)}{Fore.RESET}")
        return "0"

def download_file(url, path):
    """Загрузка файла по URL с отображением прогресса и проверкой успешности"""
    # Создаем директорию для файла, если она не существует
    directory = os.path.dirname(path)
    if not os.path.exists(directory):
        try:
            os.makedirs(directory, exist_ok=True)
        except Exception as e:
            print(f"{Fore.LIGHTRED_EX}Ошибка при создании директории: {Fore.RESET}{os.path.basename(directory)}")
            return False
    
    try:
        # Показываем имя загружаемого файла
        filename = os.path.basename(path)
        print(f"{Fore.LIGHTCYAN_EX}Загрузка: {Fore.LIGHTYELLOW_EX}{filename}{Fore.RESET}")
        
        # Добавляем таймаут для запроса
        response = requests.get(url, stream=True, timeout=30)
        if response.status_code != 200:
            print(f"{Fore.LIGHTRED_EX}Ошибка HTTP: {response.status_code}{Fore.RESET}")
            return False
            
        total_size = int(response.headers.get('content-length', 0))
        block_size = 8192
        
        if total_size > 0:
            downloaded = 0
            with open(path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=block_size):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        progress_bar(downloaded, total_size, prefix=' Прогресс:', 
                                  suffix=f'{downloaded//1024} KB / {total_size//1024} KB', length=40)
            
            # Проверяем, что файл действительно загружен
            if os.path.exists(path) and os.path.getsize(path) > 0:
                print(f"{Fore.LIGHTGREEN_EX}✓ Загрузка успешно завершена{Fore.RESET}")
                return True
            else:
                print(f"{Fore.LIGHTRED_EX}✗ Ошибка: файл загружен, но имеет нулевой размер{Fore.RESET}")
                return False
        else:
            with open(path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=block_size):
                    if chunk:
                        f.write(chunk)
            
            if os.path.exists(path) and os.path.getsize(path) > 0:
                print(f"{Fore.LIGHTGREEN_EX}✓ Загрузка успешно завершена{Fore.RESET}")
                return True
            else:
                print(f"{Fore.LIGHTRED_EX}✗ Ошибка: файл загружен, но имеет нулевой размер{Fore.RESET}")
                return False
    except requests.exceptions.ConnectionError:
        print(f"{Fore.LIGHTRED_EX}✗ Ошибка соединения{Fore.RESET}")
        return False
    except requests.exceptions.Timeout:
        print(f"{Fore.LIGHTRED_EX}✗ Превышено время ожидания{Fore.RESET}")
        return False
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}✗ Ошибка: {str(e)}{Fore.RESET}")
        return False

def extract_zip(zip_path, extract_path):
    """Распаковка zip-архива с дополнительными проверками"""
    if not os.path.exists(zip_path):
        print(f"{Fore.LIGHTRED_EX}✗ Архив не найден: {os.path.basename(zip_path)}{Fore.RESET}")
        return False
        
    print(f"{Fore.LIGHTYELLOW_EX}Распаковка архива...{Fore.RESET}", end="")
    
    # Проверяем существование директории назначения
    if not os.path.exists(extract_path):
        try:
            os.makedirs(extract_path, exist_ok=True)
        except Exception as e:
            print(f"{Fore.LIGHTRED_EX} Ошибка! Не удалось создать директорию.{Fore.RESET}")
            return False
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_path)
        
        print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
        return True
    except zipfile.BadZipFile:
        print(f"{Fore.LIGHTRED_EX} Ошибка! Неверный формат архива.{Fore.RESET}")
        return False
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX} Ошибка! {str(e)}{Fore.RESET}")
        return False

# Кэш для списка .bat файлов по директориям
_bat_files_cache = {}
_bat_files_cache_time = {}

def get_bat_files(directory):
    """Получение списка .bat файлов в директории с кэшированием"""
    global _bat_files_cache, _bat_files_cache_time
    
    # Проверяем актуальность кэша (30 секунд)
    current_time = time.time()
    if directory in _bat_files_cache and current_time - _bat_files_cache_time.get(directory, 0) < 30:
        return _bat_files_cache[directory]
    
    # Оптимизированное получение списка файлов
    try:
        result = [f for f in os.listdir(directory) if f.endswith('.bat')]
        _bat_files_cache[directory] = result
        _bat_files_cache_time[directory] = current_time
        return result
    except Exception:
        # В случае ошибки возвращаем пустой список
        return []

# Кэшируем логотип для быстрого вывода
_LOGO_CACHE = None

def print_logo():
    """Вывод логотипа GoodbyeZapret с использованием кэша"""
    global _LOGO_CACHE
    
    if _LOGO_CACHE is None:
        _LOGO_CACHE = [
            "",
            r"           " + Fore.LIGHTBLACK_EX + r"_____                 _ _                  ______                    _   ",
            r"          / ____|               | | |                |___  /                   | |  ",
            r"         | |  __  ___   ___   __| | |__  _   _  ___     / / __ _ _ __  _ __ ___| |_ ",
            r"         | | |_ |/ _ \ / _ \ / _` | '_ \| | | |/ _ \   / / / _` | '_ \| '__/ _ \ __|",
            r"         | |__| | (_) | (_) | (_| | |_) | |_| |  __/  / /_| (_| | |_) | | |  __/ |_ ",
            r"          \_____|___/ \___/ \__,_|_.__/ \__, |\___|  /_____\__,_| .__/|_|  \___|\__|",
            r"                                          __/ |                 | |                 ",
            r"                                         |___/                  |_|",
            ""
        ]
    
    for line in _LOGO_CACHE:
        print(line)
    
    # Сбрасываем стиль после вывода логотипа
    print(Style.RESET_ALL, end="")

def install_goodbyezapret():
    """Установка GoodbyeZapret с дополнительными проверками"""
    system_drive = os.environ['SystemDrive']
    temp_dir = os.environ['TEMP']
    
    print()
    print()
    print()
    print()
    print(f"  {Fore.LIGHTBLACK_EX} Идет процесс установки.")
    print(f"  {Fore.LIGHTYELLOW_EX} Пожалуйста подождите...")
    print()
    print()
    
    # Создаем все необходимые директории
    if not create_directories():
        print(f"{Fore.LIGHTRED_EX}Ошибка при создании директорий. Установка прервана.{Fore.RESET}")
        time.sleep(5)
        sys.exit(1)
    
    # Загружаем архив и распаковываем с проверкой успешности
    if not download_file("https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/GoodbyeZapret.zip", 
                      f"{temp_dir}\\GoodbyeZapret.zip"):
        print(f"{Fore.LIGHTRED_EX}Ошибка при загрузке основного архива. Установка прервана.{Fore.RESET}")
        time.sleep(5)
        sys.exit(1)
        
    if not download_file("https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe", 
                      f"{system_drive}\\GoodbyeZapret\\Updater.exe"):
        print(f"{Fore.LIGHTYELLOW_EX}Ошибка при загрузке Updater.exe. Функция обновления может не работать.{Fore.RESET}")
    
    if not extract_zip(f"{temp_dir}\\GoodbyeZapret.zip", f"{system_drive}\\GoodbyeZapret"):
        print(f"{Fore.LIGHTRED_EX}Ошибка при распаковке архива. Установка прервана.{Fore.RESET}")
        time.sleep(5)
        sys.exit(1)
    
    print()
    print(f"  {Fore.LIGHTGREEN_EX}Установка завершена.")
    print(f"  {Fore.LIGHTGREEN_EX}Давай попробуем настроить GoodbyeZapret...")
    
    # Улучшенный индикатор завершения установки
    print()
    print(f"  {Fore.LIGHTCYAN_EX}╔══════════════════════════════════════════════╗")
    print(f"  {Fore.LIGHTCYAN_EX}║  {Fore.LIGHTGREEN_EX}✓ Установка успешно завершена              {Fore.LIGHTCYAN_EX}║")
    print(f"  {Fore.LIGHTCYAN_EX}╚══════════════════════════════════════════════╝")
    print()
    print()

def install_service(bat_file):
    """Установка службы GoodbyeZapret"""
    system_drive = os.environ['SystemDrive']
    bat_name = os.path.basename(bat_file)
    config_name = os.path.splitext(bat_name)[0]
    
    print()
    print(f"{Fore.LIGHTCYAN_EX}Установка службы GoodbyeZapret для файла {Fore.LIGHTYELLOW_EX}{bat_name}{Fore.RESET}")
    
    # Останавливаем и удаляем существующую службу без лишних сообщений
    if "GoodbyeZapret" in run_command('sc query "GoodbyeZapret"', timeout=2):
        print(f"{Fore.LIGHTYELLOW_EX}Остановка предыдущей службы...{Fore.RESET}", end="")
        run_command("net stop GoodbyeZapret", timeout=5)
        run_command('sc delete "GoodbyeZapret"', timeout=3)
        print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
    
    # Создаем новую службу одним сообщением
    print(f"{Fore.LIGHTYELLOW_EX}Создание и настройка службы...{Fore.RESET}", end="")
    
    # Создаем службу
    result = run_command(f'sc create "GoodbyeZapret" binPath= "cmd.exe /c \\"{system_drive}\\GoodbyeZapret\\Configs\\{bat_name}\\"" start= auto', timeout=3)
    if not result:
        print(f"{Fore.LIGHTRED_EX} Ошибка! Не удалось создать службу.{Fore.RESET}")
        return
    
    # Сохраняем настройки
    set_registry_value("Software\\ALFiX inc.\\GoodbyeZapret", "GoodbyeZapret_Config", winreg.REG_SZ, config_name)
    set_registry_value("Software\\ALFiX inc.\\GoodbyeZapret", "GoodbyeZapret_OldConfig", winreg.REG_SZ, config_name)
    
    # Устанавливаем описание
    run_command(f'sc description GoodbyeZapret "{config_name}"', timeout=2)
    
    print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
    
    # Запускаем службу
    print(f"{Fore.LIGHTYELLOW_EX}Запуск службы GoodbyeZapret...{Fore.RESET}", end="")
    result = run_command('sc start "GoodbyeZapret"', timeout=5)
    
    if result:
        print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
        print()
        print(f"{Fore.LIGHTGREEN_EX}Служба GoodbyeZapret успешно установлена и запущена{Fore.RESET}")
    else:
        print(f"{Fore.LIGHTRED_EX} Ошибка!{Fore.RESET}")
        print(f"{Fore.LIGHTRED_EX}Не удалось запустить службу. Возможно, требуется перезагрузка компьютера.{Fore.RESET}")

def remove_service():
    """Оптимизированное удаление службы GoodbyeZapret"""
    print()
    print(f"{Fore.LIGHTCYAN_EX}Удаление службы GoodbyeZapret{Fore.RESET}")
    
    # Проверяем наличие службы перед остановкой
    if "GoodbyeZapret" not in run_command('sc query "GoodbyeZapret"', timeout=2):
        print(f"{Fore.LIGHTYELLOW_EX}Служба GoodbyeZapret не найдена.{Fore.RESET}")
        return
    
    # Останавливаем службу
    print(f"{Fore.LIGHTYELLOW_EX}Остановка службы...{Fore.RESET}", end="")
    run_command("net stop GoodbyeZapret", timeout=5)
    print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
    
    # Удаляем службу
    print(f"{Fore.LIGHTYELLOW_EX}Удаление службы из системы...{Fore.RESET}", end="")
    result = run_command('sc delete "GoodbyeZapret"', timeout=3)
    if not result:
        print(f"{Fore.LIGHTRED_EX} Ошибка!{Fore.RESET}")
        print(f"{Fore.LIGHTRED_EX}Не удалось удалить службу. Возможно, она используется другим процессом.{Fore.RESET}")
        return
    print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
    
    # Завершаем процессы, если они остались
    if is_process_running("winws.exe"):
        print(f"{Fore.LIGHTYELLOW_EX}Завершение процесса winws.exe...{Fore.RESET}", end="")
        subprocess.run("taskkill /F /IM winws.exe", shell=True, timeout=3)
        
        # Удаляем зависимые службы
        for service in ["WinDivert", "WinDivert14"]:
            run_command(f'sc stop "{service}"', timeout=2)
            run_command(f'sc delete "{service}"', timeout=2)
        
        print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
    
    # Очищаем настройки
    clear_registry_cache()
    delete_registry_value("Software\\ALFiX inc.\\GoodbyeZapret", "GoodbyeZapret_Config")
    
    print()
    print(f"{Fore.LIGHTGREEN_EX}Служба GoodbyeZapret успешно удалена из системы{Fore.RESET}")

def check_updater_service():
    """Проверка службы обновления GoodbyeZapret"""
    system_drive = os.environ['SystemDrive']
    updater_service = False
    
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Run")
        try:
            updater_path = winreg.QueryValueEx(key, "GoodbyeZapret Updater")[0]
            if updater_path.lower() == f"{system_drive}\\goodbyezapret\\goodbyezapretupdaterservice.exe".lower():
                if os.path.exists(f"{system_drive}\\GoodbyeZapret\\GoodbyeZapretUpdaterService.exe"):
                    updater_service = True
        except:
            pass
        winreg.CloseKey(key)
    except:
        pass
    
    return updater_service

def toggle_updater_service():
    """Включение/выключение службы обновления GoodbyeZapret с проверками"""
    system_drive = os.environ['SystemDrive']
    updater_service = check_updater_service()
    
    if updater_service:
        print(f"{Fore.LIGHTYELLOW_EX}Отключение службы GoodbyeZapret Updater...{Fore.RESET}", end="")
        if delete_registry_value(r"Software\Microsoft\Windows\CurrentVersion\Run", "GoodbyeZapret Updater"):
            print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
        else:
            print(f"{Fore.LIGHTRED_EX} Ошибка!{Fore.RESET}")
    else:
        updater_file = f"{system_drive}\\GoodbyeZapret\\GoodbyeZapretUpdaterService.exe"
        if not os.path.exists(updater_file):
            print(f"{Fore.LIGHTYELLOW_EX}Служба обновления не найдена. Загрузка...{Fore.RESET}")
            if not download_file("https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe", 
                          updater_file):
                print(f"{Fore.LIGHTRED_EX}Не удалось загрузить службу обновления{Fore.RESET}")
                return
        
        print(f"{Fore.LIGHTYELLOW_EX}Включение службы GoodbyeZapret Updater...{Fore.RESET}", end="")
        if set_registry_value(r"Software\Microsoft\Windows\CurrentVersion\Run", "GoodbyeZapret Updater", 
                       winreg.REG_SZ, updater_file):
            print(f"{Fore.LIGHTGREEN_EX} Готово{Fore.RESET}")
        else:
            print(f"{Fore.LIGHTRED_EX} Ошибка!{Fore.RESET}")

def show_status():
    """Отображение текущего статуса"""
    system_drive = os.environ['SystemDrive']
    updater_service = check_updater_service()
    
    os.system('cls')
    print()
    print(f"   {Fore.RESET}Состояние служб GoodbyeZapret")
    print(f"   {Fore.LIGHTBLACK_EX}============================={Fore.RESET}")
    
    if "GoodbyeZapret" in run_command('sc query "GoodbyeZapret"'):
        print(f"   Служба GoodbyeZapret: {Fore.LIGHTGREEN_EX}Установлена и работает{Fore.RESET}")
    else:
        print(f"   Служба GoodbyeZapret: {Fore.LIGHTRED_EX}Не установлена{Fore.RESET}")
    
    if updater_service:
        print(f"   Служба GoodbyeZapret Updater: {Fore.LIGHTGREEN_EX}Установлена и работает{Fore.RESET}")
        updater_action = "Выключить"
    else:
        print(f"   Служба GoodbyeZapret Updater: {Fore.LIGHTRED_EX}Не установлена{Fore.RESET}")
        updater_action = "Включить"
    
    if is_process_running("Winws.exe"):
        print(f"   Процесс Winws.exe: {Fore.LIGHTGREEN_EX}Запущен{Fore.RESET}")
    else:
        print(f"   Процесс Winws.exe:  {Fore.LIGHTRED_EX}Не найден{Fore.RESET}")
    
    print()
    print()
    print("   Состояние версий GoodbyeZapret")
    print(f"   {Fore.LIGHTBLACK_EX}=============================={Fore.RESET}")
    
    # Заменяем получение версии из файла на константное значение, непосредственно в коде
    current_gz_version = CURRENT_GZ_VERSION
    current_winws_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\bin\\version.txt")
    current_configs_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\Configs\\version.txt")
    current_lists_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\lists\\version.txt")
    
    # Получаем актуальные версии
    versions = get_actual_versions()
    actual_gz_version = versions["GoodbyeZapret"]
    actual_winws_version = versions["Winws"]
    actual_configs_version = versions["Configs"]
    actual_lists_version = versions["Lists"]
    
    # Исправленное сравнение версий: использование int() для числовых версий
    try:
        if actual_gz_version != "0" and current_gz_version < actual_gz_version:
            print(f"   Версия GodbyeZapret: {Fore.LIGHTGREEN_EX}{current_gz_version} {Fore.LIGHTRED_EX}(Устарела) (v{current_gz_version} → v{actual_gz_version}) {Fore.RESET}")
        else:
            print(f"   Версия GodbyeZapret: {Fore.LIGHTGREEN_EX}{current_gz_version} {Fore.RESET}")
        
        if actual_winws_version != "0" and current_winws_version < actual_winws_version:
            print(f"   Версия Winws: {Fore.LIGHTGREEN_EX}{current_winws_version} {Fore.LIGHTRED_EX}(Устарела) (v{current_winws_version} → v{actual_winws_version}) {Fore.RESET}")
        else:
            print(f"   Версия Winws: {Fore.LIGHTGREEN_EX}{current_winws_version} {Fore.RESET}")
        
        # Преобразование к int для числовых версий
        if actual_configs_version != "0" and int(current_configs_version) < int(actual_configs_version):
            print(f"   Версия Configs: {Fore.LIGHTGREEN_EX}{current_configs_version} {Fore.LIGHTRED_EX}(Устарела) (v{current_configs_version} → v{actual_configs_version}) {Fore.RESET}")
        else:
            print(f"   Версия Configs: {Fore.LIGHTGREEN_EX}{current_configs_version} {Fore.RESET}")
        
        if actual_lists_version != "0" and int(current_lists_version) < int(actual_lists_version):
            print(f"   Версия Lists: {Fore.LIGHTGREEN_EX}{current_lists_version} {Fore.LIGHTRED_EX}(Устарела) (v{current_lists_version} → v{actual_lists_version}) {Fore.RESET}")
        else:
            print(f"   Версия Lists: {Fore.LIGHTGREEN_EX}{current_lists_version} {Fore.RESET}")
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}Ошибка при сравнении версий: {str(e)}{Fore.RESET}")
        # Если возникла ошибка, просто выводим версии без сравнения
        print(f"   Версия GodbyeZapret: {Fore.LIGHTGREEN_EX}{current_gz_version} {Fore.RESET}")
        print(f"   Версия Winws: {Fore.LIGHTGREEN_EX}{current_winws_version} {Fore.RESET}")
        print(f"   Версия Configs: {Fore.LIGHTGREEN_EX}{current_configs_version} {Fore.RESET}")
        print(f"   Версия Lists: {Fore.LIGHTGREEN_EX}{current_lists_version} {Fore.RESET}")
    
    print()
    print()
    print()
    print()
    print(f"                 {Fore.LIGHTCYAN_EX}F {Fore.RESET}- {Fore.LIGHTYELLOW_EX}{updater_action} GoodbyeZapret Updater{Fore.RESET} / {Fore.LIGHTCYAN_EX}B {Fore.RESET}- {Fore.LIGHTYELLOW_EX}Вернуться назад{Fore.RESET}")
    print()
    print()
    print(f"                                     Введите букву ({Fore.LIGHTCYAN_EX}F{Fore.LIGHTBLACK_EX}/{Fore.LIGHTCYAN_EX}B{Fore.RESET})")
    print()
    
    choice = input("                                            \x1b[90m:> ").lower()
    
    if choice == "b" or choice == "и":
        return
    elif choice == "f" or choice == "а":
        toggle_updater_service()
        show_status()
    else:
        show_status()

def show_update_screen():
    """Отображение экрана обновления с улучшенной обработкой ошибок"""
    system_drive = os.environ['SystemDrive']
    
    # Получаем текущие версии
    current_gz_version = CURRENT_GZ_VERSION
    current_winws_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\bin\\version.txt")
    current_configs_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\Configs\\version.txt")
    current_lists_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\lists\\version.txt")
    
    # Получаем актуальные версии
    versions = get_actual_versions()
    actual_gz_version = versions["GoodbyeZapret"]
    actual_winws_version = versions["Winws"]
    actual_configs_version = versions["Configs"]
    actual_lists_version = versions["Lists"]
    
    # Добавляем проверку на корректность версий перед отображением
    if actual_gz_version == "0" or actual_winws_version == "0" or actual_configs_version == "0" or actual_lists_version == "0":
        print(f"{Fore.LIGHTRED_EX}Ошибка: не удалось получить информацию о последних версиях.{Fore.RESET}")
        print(f"{Fore.LIGHTYELLOW_EX}Проверьте подключение к интернету и попробуйте позже.{Fore.RESET}")
        time.sleep(3)
        return False
    
    # Дополнительная проверка: обновлять только если новая версия выше текущей
    update_needed = False
    if current_gz_version < actual_gz_version:
        update_needed = True
    
    if current_winws_version < actual_winws_version:
        update_needed = True
    
    if current_configs_version < actual_configs_version:
        update_needed = True
    
    if current_lists_version < actual_lists_version:
        update_needed = True
    
    # Если не требуется обновление, выходим
    if not update_needed:
        return False
    
    os.system('cls')
    print_logo()
    print()
    print(f"                   {Fore.WHITE}Доступны новые версии GoodbyeZapret и других компонентов{Fore.RESET}")
    print()
    print()
    print()
    
    if current_gz_version < actual_gz_version and actual_gz_version != "0":
        print(f"                                 GodbyeZapret: {Fore.LIGHTGREEN_EX}(v{current_gz_version} → v{actual_gz_version}) {Fore.RESET}")
    
    if current_winws_version != actual_winws_version and actual_winws_version != "0":
        print(f"                                     Winws: {Fore.LIGHTGREEN_EX}(v{current_winws_version} → v{actual_winws_version}) {Fore.RESET}")
    
    if current_configs_version != actual_configs_version and actual_configs_version != "0":
        print(f"                                   Configs: {Fore.LIGHTGREEN_EX}(v{current_configs_version} → v{actual_configs_version}) {Fore.RESET}")
    
    if current_lists_version != actual_lists_version and actual_lists_version != "0":
        print(f"                                    Lists: {Fore.LIGHTGREEN_EX}(v{current_lists_version} → v{actual_lists_version}) {Fore.RESET}")
    
    print()
    print()
    print()
    print()
    print()
    print()
    print()
    
    print(f"                                {Fore.LIGHTRED_EX}B{Fore.RESET} - Пропустить  /  {Fore.LIGHTGREEN_EX}U{Fore.RESET} - Обновить")
    print()
    
    choice = input("                                            \x1b[90m:> ").lower()
    
    if choice == "b" or choice == "и":
        return False
    elif choice == "u" or choice == "г":
        # Проверяем наличие updater.exe перед запуском
        updater_path = f"{system_drive}\\GoodbyeZapret\\Updater.exe"
        if not os.path.exists(updater_path):
            print(f"{Fore.LIGHTRED_EX}Ошибка: файл Updater.exe не найден. Загрузка...{Fore.RESET}")
            if download_file("https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/Updater/Updater.exe", 
                          updater_path):
                print(f"{Fore.LIGHTGREEN_EX}Updater.exe успешно загружен.{Fore.RESET}")
                # Запуск утилиты обновления
                subprocess.Popen([updater_path])
                sys.exit(0)
            else:
                print(f"{Fore.LIGHTRED_EX}Не удалось загрузить Updater.exe. Обновление невозможно.{Fore.RESET}")
                time.sleep(3)
                return False
        else:
            # Запуск утилиты обновления
            subprocess.Popen([updater_path])
            sys.exit(0)
    
    return True

def check_components():
    """Проверка наличия всех необходимых компонентов"""
    system_drive = os.environ['SystemDrive']
    
    missing_components = []
    
    # Проверяем основные компоненты
    if not os.path.exists(f"{system_drive}\\GoodbyeZapret\\bin\\winws.exe"):
        missing_components.append("winws.exe")
    
    if not os.path.exists(f"{system_drive}\\GoodbyeZapret\\Configs"):
        missing_components.append("папка Configs")
    elif len(get_bat_files(f"{system_drive}\\GoodbyeZapret\\Configs")) == 0:
        missing_components.append("файлы конфигурации")
    
    if not os.path.exists(f"{system_drive}\\GoodbyeZapret\\lists"):
        missing_components.append("папка lists")
    
    # Проверка дополнительных компонентов
    if not os.path.exists(f"{system_drive}\\GoodbyeZapret\\Updater.exe"):
        missing_components.append("Updater.exe")
    
    # Если что-то отсутствует, предлагаем переустановить
    if missing_components:
        print(f"{Fore.LIGHTCYAN_EX}╔════════════════════════════════════════════════════════════════════╗")
        print(f"{Fore.LIGHTCYAN_EX}║  {Fore.LIGHTRED_EX}Внимание! Отсутствуют компоненты GoodbyeZapret:          {Fore.LIGHTCYAN_EX}║")
        for component in missing_components:
            padding = ' ' * (50 - len(component))
            print(f"{Fore.LIGHTCYAN_EX}║  {Fore.LIGHTRED_EX}- {component}{padding}{Fore.LIGHTCYAN_EX}║")
        print(f"{Fore.LIGHTCYAN_EX}╠════════════════════════════════════════════════════════════════════╣")
        print(f"{Fore.LIGHTCYAN_EX}║  {Fore.WHITE}Рекомендуется переустановить программу                   {Fore.LIGHTCYAN_EX}║")
        print(f"{Fore.LIGHTCYAN_EX}╚════════════════════════════════════════════════════════════════════╝")
        print()
        print(f"{Fore.LIGHTYELLOW_EX}Запустить переустановку? (д/н): {Fore.RESET}", end="")
        choice = input().lower()
        if choice == 'д' or choice == 'y':
            # Запуск переустановки
            subprocess.Popen([f"{system_drive}\\GoodbyeZapret\\Updater.exe"])
            sys.exit(0)
    
    return len(missing_components) == 0

def check_for_updates():
    """Проверка наличия обновлений для GoodbyeZapret"""
    system_drive = os.environ['SystemDrive']
    
    # Получаем текущие версии
    current_gz_version = CURRENT_GZ_VERSION
    current_winws_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\bin\\version.txt")
    current_configs_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\Configs\\version.txt")
    current_lists_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\lists\\version.txt")
    
    # Получаем актуальные версии
    versions = get_actual_versions()
    
    # Проверяем, что получены корректные версии (не нулевые)
    if (versions["GoodbyeZapret"] == "0" and versions["Winws"] == "0" and 
        versions["Configs"] == "0" and versions["Lists"] == "0"):
        print(f"{Fore.LIGHTYELLOW_EX}Внимание: не удалось получить информацию о версиях{Fore.RESET}")
        # Не обновляем, если не удалось получить корректные версии
        return False, 0
    
    need_update = False
    update_count = 0
    
    # Безопасное сравнение версий с использованием нашей улучшенной функции
    try:
        if compare_versions(current_gz_version, versions["GoodbyeZapret"]):
            need_update = True
            update_count += 1
        
        if compare_versions(current_winws_version, versions["Winws"]):
            need_update = True
            update_count += 1
        
        if compare_versions(current_configs_version, versions["Configs"]):
            need_update = True
            update_count += 1
        
        if compare_versions(current_lists_version, versions["Lists"]):
            need_update = True
            update_count += 1
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}Ошибка при сравнении версий: {str(e)}{Fore.RESET}")
        # В случае ошибки предлагаем обновиться для безопасности
        return True, 1
        
    return need_update, update_count

def main_menu():
    """Главное меню программы с оптимизацией обновления экрана"""
    system_drive = os.environ['SystemDrive']
    last_redraw_time = 0
    force_redraw = True
    
    # Проверяем необходимость обновления
    need_update, update_count = check_for_updates()
    
    # Если много обновлений, показываем экран обновления
    if update_count >= 3:
        if show_update_screen():
            return
    
    while True:
        current_time = time.time()
        
        # Проверяем процесс не чаще чем раз в 5 секунд
        if current_time - last_redraw_time > 5 or force_redraw:
            # Проверяем, запущен ли процесс winws.exe
            if not is_process_running("winws.exe"):
                run_command('sc start "GoodbyeZapret"', timeout=3)
            
            # Получаем текущий и предыдущий конфиги
            current_config = "Не выбран"
            try:
                key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\GoodbyeZapret")
                current_config = winreg.QueryValueEx(key, "Description")[0]
                winreg.CloseKey(key)
            except:
                pass
            
            old_config = "Отсутствует"
            try:
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\ALFiX inc.\GoodbyeZapret")
                old_config = winreg.QueryValueEx(key, "GoodbyeZapret_OldConfig")[0]
                winreg.CloseKey(key)
            except:
                pass
            
            # Получаем конфиг из реестра 
            config = get_registry_value("Software\\ALFiX inc.\\GoodbyeZapret", "GoodbyeZapret_Config", "Не найден")
            
            # Очищаем экран только при необходимости перерисовки
            os.system('cls')
            
            # Выводим логотип
            print_logo()
            
            # Выводим информацию о текущем конфиге
            current_config_text = f"Текущий конфиг - {current_config}"
            old_config_text = f"Раньше использовался - {old_config}"
            
            # Центрируем текст
            padding = " " * ((90 - len(current_config_text)) // 2)
            old_padding = " " * ((90 - len(old_config_text)) // 2)
            
            if current_config != "Не выбран":
                print(f"              {Fore.LIGHTBLACK_EX}===================================================================")
                print(f"{Fore.CYAN}{padding}{current_config_text} {Fore.RESET}")
                print(f"              {Fore.LIGHTBLACK_EX}==================================================================={Fore.RESET}")
                print()
            else:
                print(f"              {Fore.LIGHTBLACK_EX}===================================================================")
                print(f"{Fore.CYAN}{padding}{current_config_text} {Fore.RESET}")
                print(f"{Fore.LIGHTBLACK_EX}{old_padding}{old_config_text} {Fore.RESET}")
                print(f"              {Fore.LIGHTBLACK_EX}==================================================================={Fore.RESET}")
                print()
            
            print("                         Выберите конфиг для установки в автозапуск")
            print()
            
            # Получаем список конфигов и делим на два столбца
            configs_dir = f"{system_drive}\\GoodbyeZapret\\Configs"
            bat_files = get_bat_files(configs_dir)
            total_files = len(bat_files)
            
            # Вычисляем, сколько элементов будет в первом столбце
            first_column_count = (total_files + 1) // 2  # Округляем вверх
            file_dict = {}
            
            # Настраиваем точное форматирование по образцу
            left_indent = 17      # Отступ от левого края
            second_column_position = 50 # Позиция начала второго столбца
            
            # Получаем информацию о предыдущем конфиге для выделения его цветом
            old_config_name = old_config
            
            # Выводим конфиги в два столбца
            for i in range(max(first_column_count, total_files - first_column_count)):
                left_idx = i
                right_idx = i + first_column_count
                
                line = " " * left_indent  # Начальный отступ
                
                # Обрабатываем левый столбец
                if left_idx < first_column_count and left_idx < total_files:
                    file = bat_files[left_idx]
                    counter_left = left_idx + 1
                    file_dict[str(counter_left)] = file
                    name_left = os.path.splitext(file)[0]
                    
                    # Проверяем, является ли это ранее использованным конфигом
                    is_old_config_left = (name_left == old_config_name)
                    
                    # Добавляем номер и имя файла в левый столбец с выравниванием
                    # Если номер однозначный, добавляем дополнительный пробел перед ним
                    if counter_left < 10:
                        # Выделяем цветом, если это ранее использованный конфиг
                        if is_old_config_left:
                            left_part = f"{Fore.CYAN} {counter_left}. {Fore.LIGHTYELLOW_EX}{name_left}{Fore.RESET}"
                        else:
                            left_part = f"{Fore.CYAN} {counter_left}. {Fore.RESET}{name_left}"
                    else:
                        # Выделяем цветом, если это ранее использованный конфиг
                        if is_old_config_left:
                            left_part = f"{Fore.CYAN}{counter_left}. {Fore.LIGHTYELLOW_EX}{name_left}{Fore.RESET}"
                        else:
                            left_part = f"{Fore.CYAN}{counter_left}. {Fore.RESET}{name_left}"
                    
                    line += left_part
                    
                    # Рассчитываем отступ до второго столбца
                    # Учитываем видимую длину строки (без цветовых кодов)
                    visible_length = len(f"{counter_left}. {name_left}")
                    # Для однозначных чисел добавляем 1 к visible_length, т.к. мы добавили пробел
                    if counter_left < 10:
                        visible_length += 1
                    
                    padding = second_column_position - left_indent - visible_length
                    line += " " * max(0, padding)
                else:
                    # Если нет левого элемента, просто переходим к позиции второго столбца
                    line = " " * second_column_position
                
                # Обрабатываем правый столбец
                if right_idx < total_files:
                    file = bat_files[right_idx]
                    counter_right = right_idx + 1
                    file_dict[str(counter_right)] = file
                    name_right = os.path.splitext(file)[0]
                    
                    # Проверяем, является ли это ранее использованным конфигом
                    is_old_config_right = (name_right == old_config_name)
                    
                    # Добавляем номер и имя файла для правого столбца
                    # Выделяем цветом, если это ранее использованный конфиг
                    if is_old_config_right:
                        line += f"{Fore.CYAN}{counter_right}. {Fore.LIGHTYELLOW_EX}{name_right}{Fore.RESET}"
                    else:
                        line += f"{Fore.CYAN}{counter_right}. {Fore.RESET}{name_right}"
                
                # Выводим сформированную строку
                print(line)
            
            counter = total_files
            
            print()
            print(f"              {Fore.LIGHTBLACK_EX}===================================================================")
            
            # Проверка состояния hosts-файла
            try:
                hosts_manager = HostsManager()
                hosts_modified = hosts_manager.check_proxy_domains_in_hosts()
                hosts_menu_text = "Отменить изменения hosts-файла" if hosts_modified else "Обновить hosts-файл для доступа к сайтам"
            except:
                hosts_menu_text = "Обновить hosts-файл для доступа к сайтам"
            print(f"                       {Fore.LIGHTCYAN_EX}DS {Fore.RESET}- {Fore.LIGHTRED_EX}Удалить службу из автозапуска{Fore.RESET}")
            print(f"                       {Fore.LIGHTCYAN_EX}RC {Fore.RESET}- {Fore.LIGHTRED_EX}Принудительно переустановить конфиги{Fore.RESET}")
            print(f"                       {Fore.LIGHTCYAN_EX}ST {Fore.RESET}- {Fore.LIGHTRED_EX}Состояние GoodbyeZapret{Fore.RESET}")
            print(f"                       {Fore.LIGHTCYAN_EX}HF {Fore.RESET}- {Fore.LIGHTRED_EX}{hosts_menu_text}{Fore.RESET}")
            print(f"                   {Fore.LIGHTCYAN_EX}(1{Fore.RESET}-{Fore.LIGHTCYAN_EX}{counter})s {Fore.RESET}- {Fore.LIGHTRED_EX}Запустить конфиг {Fore.RESET}")
            
            # Проверка необходимости обновления и вывод соответствующей опции
            if need_update:
                print(f"                      {Fore.LIGHTCYAN_EX}UD {Fore.RESET}- {Fore.LIGHTYELLOW_EX}Обновить до актуальной версии{Fore.RESET}")
            
            print()
            print()
            print(f"                                     Введите номер ({Fore.LIGHTCYAN_EX}1{Fore.RESET}-{Fore.LIGHTCYAN_EX}{counter}{Fore.RESET})")
            
            choice = input("                                            \x1b[90m:> ").lower()
            
            if choice == "ds":
                remove_service()
            elif choice == "rc":
                # Запуск переустановки конфигов
                subprocess.Popen([f"{system_drive}\\GoodbyeZapret\\Updater.exe"])
                sys.exit(0)
            elif choice == "st":
                show_status()
                continue
            elif choice == "hf":
                update_hosts_file()
                continue
            elif choice == "ud" and need_update:
                # Запуск обновления
                subprocess.Popen([f"{system_drive}\\GoodbyeZapret\\Updater.exe"])
                sys.exit(0)
            elif len(choice) > 1 and choice[-1] == "s":
                # Запустить конфиг вручную
                config_number = choice[:-1]
                if config_number.isdigit() and 1 <= int(config_number) <= counter:
                    bat_name = file_dict[config_number]
                    os.startfile(f"{system_drive}\\GoodbyeZapret\\Configs\\{bat_name}")
            elif choice.isdigit() and 1 <= int(choice) <= counter:
                # Установка службы для выбранного конфига
                bat_name = file_dict[choice]
                install_service(f"{system_drive}\\GoodbyeZapret\\Configs\\{bat_name}")
            
            last_redraw_time = current_time
            force_redraw = False
        
        # Ожидаем ввод с таймаутом для уменьшения нагрузки на CPU
        if msvcrt.kbhit():
            choice = msvcrt.getch().decode('utf-8', errors='ignore').lower()
            force_redraw = True
            
            # Обработка выбора пользователя
            # ... код обработки выбора ...
            
        else:
            # Небольшая пауза для снижения нагрузки на CPU
            time.sleep(0.1)

def progress_bar(iteration, total, prefix='', suffix='', length=50, fill='█'):
    """Оптимизированный прогресс-бар для консоли"""
    if total == 0:
        return
        
    percent = 100 * (iteration / float(total))
    filled_length = int(length * iteration // total)
    bar = fill * filled_length + '░' * (length - filled_length)  # Использую символ '░' вместо пробела для лучшей видимости
    
    # Форматируем строку целиком, а затем выводим
    output = f'\r{prefix} |{Fore.LIGHTGREEN_EX}{bar}{Fore.RESET}| {percent:.1f}% {suffix}'
    print(output, end='\r')
    
    if iteration == total: 
        print()

# Функция для быстрого форматирования и вывода цветного текста
def print_color(text, color=Fore.RESET, end='\n'):
    """Оптимизированный вывод цветного текста"""
    print(f"{color}{text}{Style.RESET_ALL}", end=end)

def time_formatter(seconds):
    """Форматирует секунды в читаемый формат времени"""
    if seconds < 60:
        return f"{seconds} сек"
    elif seconds < 3600:
        minutes = seconds // 60
        seconds %= 60
        return f"{minutes} мин {seconds} сек"
    else:
        hours = seconds // 3600
        minutes = (seconds % 3600) // 60
        seconds %= 60
        return f"{hours} ч {minutes} мин {seconds} сек"

def set_console_size():
    """Установка стандартного размера окна консоли"""
    try:
        # Получаем дескриптор консольного окна
        hwnd = ctypes.windll.kernel32.GetConsoleWindow()
        if hwnd:
            # Устанавливаем размер и позицию окна (left, top, width, height)
            ctypes.windll.user32.MoveWindow(hwnd, 100, 100, 800, 800, True)
            
            # Получаем дескриптор стандартного вывода
            h = ctypes.windll.kernel32.GetStdHandle(-11)  # STD_OUTPUT_HANDLE
            
            # Устанавливаем размер буфера консоли
            size = ctypes.wintypes._COORD(100, 40)  # ширина 100 символов, высота 50 строк
            ctypes.windll.kernel32.SetConsoleScreenBufferSize(h, size)
    except Exception as e:
        # Если возникла ошибка, продолжаем работу без изменений размера окна
        pass

def maximize_console_window():
    """Максимизация окна консоли"""
    try:
        hwnd = ctypes.windll.kernel32.GetConsoleWindow()
        if hwnd:
            ctypes.windll.user32.ShowWindow(hwnd, 3)  # SW_MAXIMIZE = 3
    except:
        pass

def center_console_window():
    """Центрирование окна консоли на экране"""
    try:
        hwnd = ctypes.windll.kernel32.GetConsoleWindow()
        if hwnd:
            # Получаем размеры экрана
            user32 = ctypes.windll.user32
            screen_width = user32.GetSystemMetrics(0)
            screen_height = user32.GetSystemMetrics(1)
            
            # Получаем размеры окна
            rect = ctypes.wintypes.RECT()
            ctypes.windll.user32.GetWindowRect(hwnd, ctypes.byref(rect))
            window_width = rect.right - rect.left
            window_height = rect.bottom - rect.top
            
            # Вычисляем центральную позицию
            x = (screen_width - window_width) // 2
            y = (screen_height - window_height) // 2
            
            # Перемещаем окно в центр
            ctypes.windll.user32.MoveWindow(hwnd, x, y, window_width, window_height, True)
    except:
        pass

# Кэш для хранения актуальных версий
_versions_cache = None
_versions_cache_time = 0

def get_actual_versions(force_refresh=False):
    """Получение актуальных версий из репозитория с кэшированием"""
    global _versions_cache, _versions_cache_time
    
    # Используем кэш, если он не устарел (10 минут) и не требуется принудительное обновление
    current_time = time.time()
    if not force_refresh and _versions_cache and current_time - _versions_cache_time < 600:
        return _versions_cache
    
    temp_dir = os.environ['TEMP']
    version_url = "https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/GoodbyeZapret_Version"
    version_file = f"{temp_dir}\\GZ_Updater.bat"
    versions = {
        "GoodbyeZapret": "0",
        "Winws": "0",
        "Configs": "0",
        "Lists": "0"
    }
    
    try:
        # Увеличиваем таймаут и добавляем параметр для отключения подтверждения SSL
        response = requests.get(
            version_url, 
            timeout=15, 
            verify=True,  # Можно изменить на False при проблемах с SSL
            headers={'Cache-Control': 'no-cache'}  # Отключаем кэширование на стороне сервера
        )
        
        if response.status_code != 200:
            print(f"{Fore.LIGHTRED_EX}Ошибка получения информации об обновлениях. Код: {response.status_code}{Fore.RESET}")
            return versions
            
        with open(version_file, "wb") as f:
            f.write(response.content)
        
        if not os.path.exists(version_file) or os.path.getsize(version_file) == 0:
            print(f"{Fore.LIGHTRED_EX}Ошибка сохранения информации об обновлениях{Fore.RESET}")
            return versions
        
        # Оптимизированное чтение и разбор файла
        content = ""
        with open(version_file, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
            
        # Быстрый поиск с использованием словаря ключ-значение
        version_keys = {
            "Actual_GoodbyeZapret_version=": "GoodbyeZapret",
            "Actual_Winws_version=": "Winws",
            "Actual_Configs_version=": "Configs", 
            "Actual_List_version=": "Lists"
        }
        
        for key, value_key in version_keys.items():
            if key in content:
                start_idx = content.index(key) + len(key)
                end_idx = content.find("\n", start_idx)
                if end_idx == -1:
                    end_idx = len(content)
                    
                # Очищаем возможные пробелы и непечатаемые символы
                version_value = content[start_idx:end_idx].strip()
                if version_value:
                    versions[value_key] = version_value
        
        # Обновляем кэш
        _versions_cache = versions
        _versions_cache_time = current_time
        return versions
            
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}Ошибка при получении версий: {str(e)}{Fore.RESET}")
        return versions

def compare_versions(ver1, ver2):
    """Универсальное сравнение версий с поддержкой различных форматов
    Возвращает True, если ver2 новее ver1
    """
    try:
        # Специальная обработка для пустых строк и "0"
        if not ver1 or ver1 == "0":
            return ver2 and ver2 != "0"
        if not ver2 or ver2 == "0":
            return False
            
        # Попытка сравнить как числа (для простых числовых версий)
        return int(ver1) < int(ver2)
    except ValueError:
        try:
            # Попытка сравнить как версионированные строки (1.2.3 и т.п.)
            import re
            
            # Разбиваем на компоненты
            parts1 = [int(x) for x in re.findall(r'\d+', ver1)]
            parts2 = [int(x) for x in re.findall(r'\d+', ver2)]
            
            # Дополняем нулями для одинаковой длины
            while len(parts1) < len(parts2):
                parts1.append(0)
            while len(parts2) < len(parts1):
                parts2.append(0)
            
            # Сравниваем покомпонентно
            for i in range(len(parts1)):
                if parts1[i] < parts2[i]:
                    return True
                elif parts1[i] > parts2[i]:
                    return False
            
            # Если все компоненты равны
            return False
        except:
            # В крайнем случае, сравниваем как строки
            return ver1 < ver2

def update_hosts_file():
    """Обновление или восстановление hosts-файла"""
    print()
    
    # Создаем рамку для заголовка
    print(f"  {Fore.LIGHTCYAN_EX}╔════════════════════════════════════════════════════════════════════╗")
    print(f"  {Fore.LIGHTCYAN_EX}║  {Fore.WHITE}Управление hosts-файлом                                             {Fore.LIGHTCYAN_EX}║")
    print(f"  {Fore.LIGHTCYAN_EX}╚════════════════════════════════════════════════════════════════════╝")
    print()
    
    def status_callback(message):
        print(f"  {Fore.LIGHTYELLOW_EX}• {message}{Fore.RESET}")
    
    try:
        # Проверяем права администратора перед работой с hosts
        if not is_admin():
            print(f"  {Fore.LIGHTRED_EX}✗ Для изменения hosts-файла требуются права администратора{Fore.RESET}")
            print(f"  {Fore.LIGHTYELLOW_EX}→ Перезапустите программу с правами администратора{Fore.RESET}")
            print()
            print(f"  {Fore.LIGHTCYAN_EX}Нажмите любую клавишу для возврата в главное меню...{Fore.RESET}")
            msvcrt.getch()
            return
            
        hosts_manager = HostsManager(status_callback)
        
        # Проверяем наличие прокси-доменов в hosts-файле
        if hosts_manager.check_proxy_domains_in_hosts():
            print(f"  {Fore.LIGHTYELLOW_EX}ℹ В hosts-файле обнаружены прокси-домены.{Fore.RESET}")
            print(f"  {Fore.LIGHTYELLOW_EX}? Хотите удалить их? (д/н){Fore.RESET}")
            
            choice = input("  > ").lower()
            if choice == 'д' or choice == 'y':
                print(f"  {Fore.LIGHTYELLOW_EX}Удаление прокси-доменов...{Fore.RESET}")
                result = hosts_manager.remove_proxy_domains()
                if result:
                    print()
                    print(f"  {Fore.LIGHTGREEN_EX}✓ Прокси-домены успешно удалены из файла hosts.{Fore.RESET}")
                else:
                    print()
                    print(f"  {Fore.LIGHTRED_EX}✗ Не удалось удалить записи из hosts-файла.{Fore.RESET}")
            else:
                print()
                print(f"  {Fore.LIGHTCYAN_EX}ℹ Операция отменена пользователем.{Fore.RESET}")
        else:
            from proxy_domains import PROXY_DOMAINS
            print(f"  {Fore.LIGHTYELLOW_EX}ℹ Обновление hosts-файла для доступа к заблокированным сайтам...{Fore.RESET}")
            result = hosts_manager.add_proxy_domains()
            
            if result:
                print()
                print(f"  {Fore.LIGHTGREEN_EX}✓ Файл hosts успешно обновлен с {len(PROXY_DOMAINS)} записями.{Fore.RESET}")
            else:
                print()
                print(f"  {Fore.LIGHTRED_EX}✗ Не удалось обновить файл hosts.{Fore.RESET}")
    except Exception as e:
        print()
        print(f"  {Fore.LIGHTRED_EX}✗ Ошибка при работе с hosts-файлом: {str(e)}{Fore.RESET}")
    
    print()
    print(f"  {Fore.LIGHTCYAN_EX}Нажмите любую клавишу для возврата в главное меню...{Fore.RESET}")
    msvcrt.getch()

def cleanup_temp_files():
    """Очистка временных файлов, созданных программой"""
    temp_dir = os.environ['TEMP']
    files_to_clean = [
        f"{temp_dir}\\GoodbyeZapret.zip",
        f"{temp_dir}\\GZ_Updater.bat"
    ]
    
    # Быстрая очистка временных файлов параллельно
    for file_path in files_to_clean:
        if os.path.exists(file_path):
            try:
                # Используем эту функцию для более быстрого удаления большого файла
                os.remove(file_path)
            except Exception:
                # Игнорируем ошибки при удалении
                pass
                
    # Очистка кэшей данных
    global _registry_cache, _bat_files_cache, _versions_cache
    _registry_cache = {}
    _bat_files_cache = {}
    _versions_cache = None

def clear_registry_cache():
    """Очистка кэша значений реестра"""
    global _registry_cache
    _registry_cache = {}

if __name__ == "__main__":
    try:
        # Устанавливаем размер окна консоли
        set_console_size()
        
        # Центрируем окно на экране
        center_console_window()
        
        # Проверка прав администратора
        if not is_admin():
            restart_as_admin()
        
        # Проверка языка системы
        if not check_language():
            print("\n  Error 01: Неверный язык интерфейса (требуется ru-RU).")
            time.sleep(4)
            sys.exit(1)
        
        # Используем улучшенную проверку соединения с повторными попытками
        if not check_internet_with_retry():
            print("\n  Error 02: Отсутствует подключение к интернету.")
            print("  Проверьте настройки сети или прокси-сервера.")
            print("  Нажмите любую клавишу, чтобы продолжить без проверки подключения...")
            
            # Даем возможность продолжить, даже если соединение не обнаружено
            msvcrt.getch()
        
        # Проверка наличия установленного GoodbyeZapret
        if not check_goodbyezapret_installed():
            # Создаем директории перед установкой
            create_directories()
            install_goodbyezapret()
        else:
            # Проверка компонентов только если программа уже установлена
            check_components()
        
        # Запуск главного меню
        main_menu()
        
        # Очистка перед выходом
        cleanup_temp_files()
    except Exception as e:
        print(f"\n{Fore.LIGHTRED_EX}Критическая ошибка: {str(e)}{Fore.RESET}")
        print(f"{Fore.LIGHTYELLOW_EX}Нажмите любую клавишу для выхода...{Fore.RESET}")
        msvcrt.getch()
        sys.exit(1)
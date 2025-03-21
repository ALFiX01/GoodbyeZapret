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

# Встраиваем proxy_domains вместо импорта
PROXY_DOMAINS = {
    "www.aomeitech.com": "0.0.0.0",
    "mail.proton.me": "3.66.189.153",
    "facebook.com": "31.13.72.36",
    "www.facebook.com": "31.13.72.36",
    "static.xx.fbcdn.net": "31.13.72.12",
    "external-hel3-1.xx.fbcdn.net": "31.13.72.12",
    "www.instagram.com": "157.240.225.174",
    "instagram.com": "157.240.225.174",
    "scontent.cdninstagram.com": "157.240.247.63",
    "scontent-hel3-1.cdninstagram.com": "157.240.247.63",
    "b.i.instagram.com": "157.240.245.174",
    "z-p42-chat-e2ee-ig.facebook.com": "157.240.245.174",
    "protonmail.com": "3.66.189.153",
    "mail.proton.me": "3.66.189.153",
    "chatgpt.com": "204.12.192.222",
    "ab.chatgpt.com": "204.12.192.222",
    "auth.openai.com": "204.12.192.222",
    "auth0.openai.com": "204.12.192.222",
    "platform.openai.com": "204.12.192.222",
    "cdn.oaistatic.com": "204.12.192.222",
    "files.oaiusercontent.com": "204.12.192.222",
    "cdn.auth0.com": "204.12.192.222",
    "tcr9i.chat.openai.com": "204.12.192.222",
    "webrtc.chatgpt.com": "204.12.192.222",
    "android.chat.openai.com": "204.12.192.222",
    "api.openai.com": "204.12.192.222",
    "gemini.google.com": "138.201.204.218",
    "aistudio.google.com": "204.12.192.222",
    "generativelanguage.googleapis.com": "204.12.192.222",
    "alkalimakersuite-pa.clients6.google.com": "204.12.192.222",
    "aitestkitchen.withgoogle.com": "204.12.192.222",
    "aisandbox-pa.googleapis.com": "204.12.192.222",
    "webchannel-alkalimakersuite-pa.clients6.google.com": "204.12.192.222",
    "proactivebackend-pa.googleapis.com": "204.12.192.222",
    "o.pki.goog": "204.12.192.222",
    "labs.google": "204.12.192.222",
    "notebooklm.google": "204.12.192.222",
    "notebooklm.google.com": "204.12.192.222",
    "copilot.microsoft.com": "204.12.192.222",
    "www.bing.com": "204.12.192.222",
    "sydney.bing.com": "204.12.192.222",
    "edgeservices.bing.com": "204.12.192.222",
    "rewards.bing.com": "50.7.85.221",
    "xsts.auth.xboxlive.com": "204.12.192.222",
    "api.spotify.com": "204.12.192.222",
    "xpui.app.spotify.com": "204.12.192.222",
    "appresolve.spotify.com": "204.12.192.222",
    "login5.spotify.com": "204.12.192.222",
    "gew1-spclient.spotify.com": "204.12.192.222",
    "gew1-dealer.spotify.com": "204.12.192.222",
    "spclient.wg.spotify.com": "204.12.192.222",
    "api-partner.spotify.com": "204.12.192.222",
    "aet.spotify.com": "204.12.192.222",
    "www.spotify.com": "204.12.192.222",
    "accounts.spotify.com": "204.12.192.222",
    "spotifycdn.com": "204.12.192.222",
    "open-exp.spotifycdn.com": "204.12.192.222",
    "www-growth.scdn.co": "204.12.192.222",
    "o22381.ingest.sentry.io": "204.12.192.222",
    "login.app.spotify.com": "50.7.87.84",
    "encore.scdn.co": "138.201.204.218",
    "accounts.scdn.co": "204.12.192.222",
    "ap-gew1.spotify.com": "138.201.204.218",
    "www.notion.so": "94.131.119.85",
    "www.canva.com": "50.7.85.222",
    "www.intel.com": "204.12.192.222",
    "www.dell.com": "204.12.192.219",
    "developer.nvidia.com": "204.12.192.220",
    "codeium.com": "50.7.87.85",
    "inference.codeium.com": "50.7.85.219",
    "www.tiktok.com": "50.7.85.219",
    "api.github.com": "50.7.87.84",
    "api.individual.githubcopilot.com": "50.7.85.221",
    "proxy.individual.githubcopilot.com": "50.7.87.83",
    "datalore.jetbrains.com": "50.7.85.221",
    "plugins.jetbrains.com": "107.150.34.100",
    "elevenlabs.io": "204.12.192.222",
    "api.us.elevenlabs.io": "204.12.192.222",
    "elevenreader.io": "204.12.192.222",
    "truthsocial.com": "204.12.192.221",
    "static-assets-1.truthsocial.com": "204.12.192.221",
    "grok.com": "185.250.151.49",
    "accounts.x.ai": "185.250.151.49",
    "autodesk.com": "94.131.119.85",
    "accounts.autodesk.com": "94.131.119.85",
    "claude.ai": "204.12.192.222",
    "only-fans.uk": "0.0.0.0",
    "only-fans.me": "0.0.0.0",
    "only-fans.wtf": "0.0.0.0"
}

# Встраиваем класс HostsManager вместо импорта
class HostsManager:
    def __init__(self, status_callback=None):
        self.status_callback = status_callback
    
    def set_status(self, message):
        """Отображает статусное сообщение"""
        if self.status_callback:
            self.status_callback(message)
        else:
            print(message)

    def show_popup_message(self, title, message):
        """Показывает всплывающее окно с сообщением, без использования PyQt5"""
        try:
            ctypes.windll.user32.MessageBoxW(0, message, title, 0x40)
        except:
            print(f"{title}: {message}")
    
    def check_proxy_domains_in_hosts(self):
        """Проверяет наличие прокси-доменов в hosts-файле
        Возвращает True, если домены найдены, и False в противном случае
        """
        hosts_path = r"C:\Windows\System32\drivers\etc\hosts"
        domains_found = 0
        
        try:
            with open(hosts_path, 'r', encoding='utf-8') as file:
                content = file.read()
                
            for domain in PROXY_DOMAINS.keys():
                if domain in content:
                    domains_found += 1
                    
            # Если найдено более 30% доменов, считаем что hosts-файл содержит наши записи
            return domains_found > len(PROXY_DOMAINS) * 0.3
        except:
            return False
                
    def modify_hosts_file(self, domain_ip_dict):
        hosts_path = r"C:\Windows\System32\drivers\etc\hosts"
        try:
            with open(hosts_path, 'r', encoding='utf-8') as file:
                original_lines = file.readlines()
            
            final_lines = []
            for line in original_lines:
                line_stripped = line.strip()                
                if not line_stripped or line_stripped.startswith('#'):
                    final_lines.append(line)
                    continue
                    
                parts = line_stripped.split()
                if len(parts) >= 2:
                    _, domain = parts[0], parts[1]
                    if domain in domain_ip_dict:
                        continue
                    else:
                        final_lines.append(line)
            
            new_records = []
            for domain, ip in domain_ip_dict.items():
                new_records.append(f"{ip} {domain}\n")
            
            new_content = new_records + final_lines
            
            with open(hosts_path, 'w', encoding='utf-8') as file:
                file.writelines(new_content)
            
            self.set_status(f"Файл hosts обновлен: добавлено/обновлено {len(domain_ip_dict)} записей")
            
            self.show_popup_message(
                "Файл hosts обновлен",
                "Для применения изменений ОБЯЗАТЕЛЬНО СЛЕДУЕТ закрыть и открыть веб-браузер (не только сайт, а всю программу) и/или приложение Spotify!"
            )
            return True
        except PermissionError:
            self.set_status("Ошибка доступа: требуются права администратора")
            return False
        except Exception as e:
            error_msg = f"Ошибка при обновлении hosts: {str(e)}"
            print(error_msg)
            self.set_status(error_msg)
            return False
    
    def remove_proxy_domains(self):
        """Удаляет прокси-домены из hosts-файла"""
        hosts_path = r"C:\Windows\System32\drivers\etc\hosts"
        
        try:
            with open(hosts_path, 'r', encoding='utf-8') as file:
                lines = file.readlines()
            
            # Отфильтровываем строки, содержащие наши домены
            new_lines = []
            for line in lines:
                line_stripped = line.strip()
                if not line_stripped or line_stripped.startswith('#'):
                    new_lines.append(line)
                    continue
                
                parts = line_stripped.split()
                if len(parts) >= 2:
                    domain = parts[1]
                    if domain in PROXY_DOMAINS:
                        continue
                new_lines.append(line)
            
            with open(hosts_path, 'w', encoding='utf-8') as file:
                file.writelines(new_lines)
            
            self.set_status("Прокси-домены успешно удалены из файла hosts")
            self.show_popup_message(
                "Файл hosts обновлен",
                "Прокси-домены удалены из файла hosts. Для применения изменений перезапустите браузер."
            )
            return True
        except PermissionError:
            self.set_status("Ошибка доступа: требуются права администратора")
            return False
        except Exception as e:
            error_msg = f"Ошибка при обновлении hosts: {str(e)}"
            self.set_status(error_msg)
            return False

    def add_proxy_domains(self):
        """Добавляет или обновляет прокси домены в файле hosts"""
        return self.modify_hosts_file(PROXY_DOMAINS)

# Инициализация colorama
init(autoreset=True)

def is_admin():
    """Проверка прав администратора"""
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

def check_internet():
    """Проверка интернет-соединения"""
    try:
        socket.create_connection(("google.ru", 80), timeout=3)
        return True
    except:
        return False

def check_goodbyezapret_installed():
    """Проверка наличия установленного GoodbyeZapret"""
    return os.path.exists(f"{os.environ['SystemDrive']}\\GoodbyeZapret")

def get_registry_value(key_path, value_name, default=""):
    """Получение значения из реестра"""
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path)
        value = winreg.QueryValueEx(key, value_name)[0]
        winreg.CloseKey(key)
        return value
    except:
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

def run_command(command, shell=True):
    """Запуск команды и получение результата"""
    try:
        result = subprocess.run(command, shell=shell, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except:
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
            print(f"{Fore.LIGHTRED_EX}Ошибка при создании директории {directory}: {str(e)}{Fore.RESET}")
            return False
    
    try:
        response = requests.get(url, stream=True)
        if response.status_code != 200:
            print(f"{Fore.LIGHTRED_EX}Ошибка при загрузке файла: HTTP статус {response.status_code}{Fore.RESET}")
            return False
            
        total_size = int(response.headers.get('content-length', 0))
        block_size = 8192
        
        print(f"{Fore.LIGHTCYAN_EX}Загрузка {os.path.basename(path)}...")
        
        if total_size > 0:
            downloaded = 0
            with open(path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=block_size):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        progress_bar(downloaded, total_size, prefix=f' {Fore.LIGHTCYAN_EX}Прогресс:{Fore.RESET}', 
                                   suffix=f'{downloaded//(1024)} KB / {total_size//(1024)} KB', length=40)
            
            # Проверяем, что файл действительно загружен
            if os.path.exists(path) and os.path.getsize(path) > 0:
                print(f"{Fore.LIGHTGREEN_EX}Загрузка успешно завершена{Fore.RESET}")
                return True
            else:
                print(f"{Fore.LIGHTRED_EX}Ошибка: файл загружен, но имеет нулевой размер{Fore.RESET}")
                return False
        else:
            with open(path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=block_size):
                    if chunk:
                        f.write(chunk)
            
            if os.path.exists(path) and os.path.getsize(path) > 0:
                print(f"{Fore.LIGHTGREEN_EX}Загрузка завершена{Fore.RESET}")
                return True
            else:
                print(f"{Fore.LIGHTRED_EX}Ошибка: файл загружен, но имеет нулевой размер{Fore.RESET}")
                return False
    except requests.exceptions.ConnectionError:
        print(f"{Fore.LIGHTRED_EX}Ошибка соединения при загрузке файла{Fore.RESET}")
        return False
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}Ошибка при загрузке файла: {str(e)}{Fore.RESET}")
        return False

def extract_zip(zip_path, extract_path):
    """Распаковка zip-архива с дополнительными проверками"""
    if not os.path.exists(zip_path):
        print(f"{Fore.LIGHTRED_EX}Архив не найден: {zip_path}{Fore.RESET}")
        return False
        
    # Проверяем существование директории назначения
    if not os.path.exists(extract_path):
        try:
            os.makedirs(extract_path, exist_ok=True)
        except Exception as e:
            print(f"{Fore.LIGHTRED_EX}Ошибка при создании директории {extract_path}: {str(e)}{Fore.RESET}")
            return False
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_path)
        
        print(f"{Fore.LIGHTGREEN_EX}Архив успешно распакован в {extract_path}{Fore.RESET}")
        return True
    except zipfile.BadZipFile:
        print(f"{Fore.LIGHTRED_EX}Ошибка: неверный формат ZIP-архива{Fore.RESET}")
        return False
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}Ошибка при распаковке архива: {str(e)}{Fore.RESET}")
        return False

def get_bat_files(directory):
    """Получение списка .bat файлов в директории"""
    return [f for f in os.listdir(directory) if f.endswith('.bat')]

def print_logo():
    """Вывод логотипа GoodbyeZapret"""
    print()
    print(r"           " + Fore.LIGHTBLACK_EX + r"_____                 _ _                  ______                    _   ")
    print(r"          / ____|               | | |                |___  /                   | |  ")
    print(r"         | |  __  ___   ___   __| | |__  _   _  ___     / / __ _ _ __  _ __ ___| |_ ")
    print(r"         | | |_ |/ _ \ / _ \ / _` | '_ \| | | |/ _ \   / / / _` | '_ \| '__/ _ \ __|")
    print(r"         | |__| | (_) | (_) | (_| | |_) | |_| |  __/  / /_| (_| | |_) | | |  __/ |_ ")
    print(r"          \_____|___/ \___/ \__,_|_.__/ \__, |\___|  /_____\__,_| .__/|_|  \___|\__|")
    print(r"                                          __/ |                 | |                 ")
    print(r"                                         |___/                  |_|")
    print()

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
    print(f"Устанавливаю службу GoodbyeZapret для файла {bat_name}...")
    print(f"{Fore.LIGHTYELLOW_EX}Нажмите Enter для подтверждения{Fore.RESET}")
    input()
    
    # Индикаторы статуса операций
    print(f"Создание службы... ", end="")
    result = run_command(f'sc create "GoodbyeZapret" binPath= "cmd.exe /c \\"{system_drive}\\GoodbyeZapret\\Configs\\{bat_name}\\"" start= auto')
    if result:
        print(f"{Fore.LIGHTGREEN_EX}Успешно{Fore.RESET}")
    else:
        print(f"{Fore.LIGHTRED_EX}Ошибка{Fore.RESET}")
    
    print(f"Сохранение настроек... ", end="")
    set_registry_value("Software\\ALFiX inc.\\GoodbyeZapret", "GoodbyeZapret_Config", winreg.REG_SZ, config_name)
    set_registry_value("Software\\ALFiX inc.\\GoodbyeZapret", "GoodbyeZapret_OldConfig", winreg.REG_SZ, config_name)
    print(f"{Fore.LIGHTGREEN_EX}Успешно{Fore.RESET}")
    
    print(f"Установка описания службы... ", end="")
    result = run_command(f'sc description GoodbyeZapret "{config_name}"')
    if result:
        print(f"{Fore.LIGHTGREEN_EX}Успешно{Fore.RESET}")
    else:
        print(f"{Fore.LIGHTRED_EX}Ошибка{Fore.RESET}")
    
    print("Запускаю службу GoodbyeZapret...")
    result = run_command('sc start "GoodbyeZapret"')
    if result:
        print(f"{Fore.LIGHTGREEN_EX}Служба GoodbyeZapret успешно запущена{Fore.RESET}")
    else:
        print(f"{Fore.LIGHTRED_EX}Ошибка при запуске службы{Fore.RESET}")

def remove_service():
    """Удаление службы GoodbyeZapret"""
    print()
    print("Остановка службы GoodbyeZapret...")
    run_command("net stop GoodbyeZapret")
    print("Служба успешно остановлена.")
    
    print("Удаление службы GoodbyeZapret...")
    if "GoodbyeZapret" in run_command('sc query "GoodbyeZapret"'):
        result = run_command('sc delete "GoodbyeZapret"')
        if result:
            print("Служба GoodbyeZapret успешно удалена")
            if is_process_running("winws.exe"):
                print("Файл winws.exe в данный момент выполняется.")
                run_command("taskkill /F /IM winws.exe")
                run_command('net stop "WinDivert"')
                run_command('sc delete "WinDivert"')
                run_command('net stop "WinDivert14"')
                run_command('sc delete "WinDivert14"')
                print("Файл winws.exe был остановлен.")
            else:
                print("Файл winws.exe в данный момент не выполняется.")
            print(f"{Fore.LIGHTGREEN_EX}Удаление успешно завершено.{Fore.RESET}")
        else:
            print("Ошибка при удалении службы")
    else:
        print("Служба GoodbyeZapret не найдена")
    
    delete_registry_value("Software\\ALFiX inc.\\GoodbyeZapret", "GoodbyeZapret_Config")

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
        if delete_registry_value(r"Software\Microsoft\Windows\CurrentVersion\Run", "GoodbyeZapret Updater"):
            print(f"{Fore.LIGHTGREEN_EX}Служба GoodbyeZapret Updater успешно отключена{Fore.RESET}")
        else:
            print(f"{Fore.LIGHTRED_EX}Ошибка при отключении службы GoodbyeZapret Updater{Fore.RESET}")
    else:
        updater_file = f"{system_drive}\\GoodbyeZapret\\GoodbyeZapretUpdaterService.exe"
        if not os.path.exists(updater_file):
            print(f"{Fore.LIGHTYELLOW_EX}Служба GoodbyeZapret Updater не найдена. Загрузка...{Fore.RESET}")
            if not download_file("https://github.com/ALFiX01/GoodbyeZapret/raw/refs/heads/main/Files/UpdateService/UpdateService.exe", 
                          updater_file):
                print(f"{Fore.LIGHTRED_EX}Ошибка загрузки службы обновления{Fore.RESET}")
                return
                
        if set_registry_value(r"Software\Microsoft\Windows\CurrentVersion\Run", "GoodbyeZapret Updater", 
                       winreg.REG_SZ, updater_file):
            print(f"{Fore.LIGHTGREEN_EX}Служба GoodbyeZapret Updater успешно включена{Fore.RESET}")
        else:
            print(f"{Fore.LIGHTRED_EX}Ошибка при включении службы GoodbyeZapret Updater{Fore.RESET}")

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
    
    current_gz_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\version.txt")
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
    current_gz_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\version.txt")
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
    current_gz_version = get_current_version(f"{system_drive}\\GoodbyeZapret\\version.txt")
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
    
    # Безопасное сравнение версий с правильной обработкой числовых версий
    try:
        # GoodbyeZapret и Winws могут иметь формат X.Y.Z
        if versions["GoodbyeZapret"] != "0" and current_gz_version < versions["GoodbyeZapret"]:
            need_update = True
            update_count += 1
        
        if versions["Winws"] != "0" and current_winws_version < versions["Winws"]:
            need_update = True
            update_count += 1
        
        # Configs и Lists обычно числовые, нужно сравнивать как числа
        if versions["Configs"] != "0" and int(current_configs_version) < int(versions["Configs"]):
            need_update = True
            update_count += 1
        
        if versions["Lists"] != "0" and int(current_lists_version) < int(versions["Lists"]):
            need_update = True
            update_count += 1
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}Ошибка при сравнении версий: {str(e)}{Fore.RESET}")
        # В случае ошибки предлагаем обновиться для безопасности
        return True, 1
        
    return need_update, update_count

def main_menu():
    """Главное меню программы"""
    system_drive = os.environ['SystemDrive']
    
    # Проверяем необходимость обновления
    need_update, update_count = check_for_updates()
    
    # Если много обновлений, показываем экран обновления
    if update_count >= 3:
        if show_update_screen():
            return
    
    while True:
        # Проверяем, запущен ли процесс winws.exe
        if not is_process_running("winws.exe"):
            run_command('sc start "GoodbyeZapret"')
        
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
        config = "Не найден"
        try:
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\ALFiX inc.\GoodbyeZapret")
            config = winreg.QueryValueEx(key, "GoodbyeZapret_Config")[0]
            winreg.CloseKey(key)
        except:
            try:
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\ASX\Info")
                config = winreg.QueryValueEx(key, "GoodbyeZapret_Config")[0]
                set_registry_value("Software\\ALFiX inc.\\GoodbyeZapret", "GoodbyeZapret_Config", winreg.REG_SZ, config)
                delete_registry_value("Software\\ASX\\Info", "GoodbyeZapret_Config")
                winreg.CloseKey(key)
            except:
                pass
        
        # Очищаем экран
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
            print(f"                     {Fore.LIGHTBLACK_EX}===================================================")
            print(f"{Fore.CYAN}{padding}{current_config_text} {Fore.RESET}")
            print(f"                     {Fore.LIGHTBLACK_EX}==================================================={Fore.RESET}")
            print()
        else:
            print(f"                     {Fore.LIGHTBLACK_EX}===================================================")
            print(f"{Fore.CYAN}{padding}{current_config_text} {Fore.RESET}")
            print(f"{Fore.LIGHTBLACK_EX}{old_padding}{old_config_text} {Fore.RESET}")
            print(f"                     {Fore.LIGHTBLACK_EX}==================================================={Fore.RESET}")
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
        left_indent = 21      # Отступ от левого края
        second_column_position = 50 # Позиция начала второго столбца
        
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
                
                # Добавляем номер и имя файла в левый столбец
                left_part = f"{Fore.CYAN}{counter_left}. {Fore.RESET}{name_left}"
                line += left_part
                
                # Рассчитываем отступ до второго столбца
                # Учитываем видимую длину строки (без цветовых кодов)
                visible_length = len(f"{counter_left}. {name_left}")
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
                
                # Добавляем номер и имя файла для правого столбца
                line += f"{Fore.CYAN}{counter_right}. {Fore.RESET}{name_right}"
            
            # Выводим сформированную строку
            print(line)
        
        counter = total_files
        
        print(f"                     {Fore.LIGHTBLACK_EX}===================================================")
        
        # Проверка состояния hosts-файла
        try:
            hosts_manager = HostsManager()
            hosts_modified = hosts_manager.check_proxy_domains_in_hosts()
            hosts_menu_text = "Отменить изменения hosts-файла" if hosts_modified else "Обновить hosts-файл для доступа к сайтам"
        except:
            hosts_menu_text = "Обновить hosts-файл для доступа к сайтам"
        
        print(f"                      {Fore.LIGHTCYAN_EX}DS {Fore.RESET}- {Fore.LIGHTRED_EX}Удалить службу из автозапуска{Fore.RESET}")
        print(f"                      {Fore.LIGHTCYAN_EX}RC {Fore.RESET}- {Fore.LIGHTRED_EX}Принудительно переустановить конфиги{Fore.RESET}")
        print(f"                      {Fore.LIGHTCYAN_EX}ST {Fore.RESET}- {Fore.LIGHTRED_EX}Состояние GoodbyeZapret{Fore.RESET}")
        print(f"                      {Fore.LIGHTCYAN_EX}HF {Fore.RESET}- {Fore.LIGHTRED_EX}{hosts_menu_text}{Fore.RESET}")
        print(f"                  {Fore.LIGHTCYAN_EX}(1{Fore.RESET}-{Fore.LIGHTCYAN_EX}{counter})s {Fore.RESET}- {Fore.LIGHTRED_EX}Запустить конфиг {Fore.RESET}")
        
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
            
        print("\nНажмите Enter чтобы продолжить...")
        input()

def progress_bar(iteration, total, prefix='', suffix='', length=50, fill='█'):
    """Отображение прогресс-бара в консоли"""
    percent = ("{0:.1f}").format(100 * (iteration / float(total)))
    filled_length = int(length * iteration // total)
    bar = fill * filled_length + ' ' * (length - filled_length)
    print(f'\r{prefix} |{Fore.LIGHTGREEN_EX}{bar}{Fore.RESET}| {percent}% {suffix}', end='\r')
    if iteration == total: 
        print()

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

def get_actual_versions():
    """Получение актуальных версий из репозитория с поддержкой различных форматов файла"""
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
        response = requests.get(version_url, timeout=15)
        
        if response.status_code != 200:
            print(f"{Fore.LIGHTRED_EX}Ошибка получения информации об обновлениях. Код: {response.status_code}{Fore.RESET}")
            return versions
            
        with open(version_file, "wb") as f:
            f.write(response.content)
        
        if not os.path.exists(version_file) or os.path.getsize(version_file) == 0:
            print(f"{Fore.LIGHTRED_EX}Ошибка сохранения информации об обновлениях{Fore.RESET}")
            return versions
        
        # Получаем содержимое файла
        with open(version_file, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
            
        # Разбираем содержимое, которое может быть как в разных строках, так и в одной строке
        if "Actual_GoodbyeZapret_version=" in content:
            try:
                start_idx = content.index("Actual_GoodbyeZapret_version=") + len("Actual_GoodbyeZapret_version=")
                end_idx = start_idx
                while end_idx < len(content) and content[end_idx] not in [' ', '\n', '\r']:
                    end_idx += 1
                versions["GoodbyeZapret"] = content[start_idx:end_idx]
            except Exception as e:
                print(f"{Fore.LIGHTRED_EX}Ошибка при парсинге версии GoodbyeZapret: {str(e)}{Fore.RESET}")
        
        if "Actual_Winws_version=" in content:
            try:
                start_idx = content.index("Actual_Winws_version=") + len("Actual_Winws_version=")
                end_idx = start_idx
                while end_idx < len(content) and content[end_idx] not in [' ', '\n', '\r']:
                    end_idx += 1
                versions["Winws"] = content[start_idx:end_idx]
            except Exception as e:
                print(f"{Fore.LIGHTRED_EX}Ошибка при парсинге версии Winws: {str(e)}{Fore.RESET}")
        
        if "Actual_Configs_version=" in content:
            try:
                start_idx = content.index("Actual_Configs_version=") + len("Actual_Configs_version=")
                end_idx = start_idx
                while end_idx < len(content) and content[end_idx] not in [' ', '\n', '\r']:
                    end_idx += 1
                versions["Configs"] = content[start_idx:end_idx]
            except Exception as e:
                print(f"{Fore.LIGHTRED_EX}Ошибка при парсинге версии Configs: {str(e)}{Fore.RESET}")
        
        if "Actual_List_version=" in content:
            try:
                start_idx = content.index("Actual_List_version=") + len("Actual_List_version=")
                end_idx = start_idx
                while end_idx < len(content) and content[end_idx] not in [' ', '\n', '\r']:
                    end_idx += 1
                versions["Lists"] = content[start_idx:end_idx]
            except Exception as e:
                print(f"{Fore.LIGHTRED_EX}Ошибка при парсинге версии Lists: {str(e)}{Fore.RESET}")
        
        return versions
            
    except requests.exceptions.ConnectionError:
        print(f"{Fore.LIGHTRED_EX}Ошибка соединения при получении версий{Fore.RESET}")
        return versions
    except requests.exceptions.Timeout:
        print(f"{Fore.LIGHTRED_EX}Таймаут при получении версий{Fore.RESET}")
        return versions
    except Exception as e:
        print(f"{Fore.LIGHTRED_EX}Ошибка при получении версий: {str(e)}{Fore.RESET}")
        return versions

def compare_versions(ver1, ver2):
    """Универсальное сравнение версий с поддержкой различных форматов
    Возвращает True, если ver2 новее ver1
    """
    try:
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
    
    def status_callback(message):
        print(f"  {Fore.LIGHTYELLOW_EX}{message}{Fore.RESET}")
    
    try:
        hosts_manager = HostsManager(status_callback)
        
        # Проверяем наличие наших прокси-доменов в hosts-файле
        if hosts_manager.check_proxy_domains_in_hosts():
            # Если домены найдены, предлагаем отменить изменения
            print(f"  {Fore.LIGHTCYAN_EX}╔════════════════════════════════════════════════════════════════════╗")
            print(f"  {Fore.LIGHTCYAN_EX}║  {Fore.WHITE}Отмена изменений hosts-файла                                  {Fore.LIGHTCYAN_EX}║")
            print(f"  {Fore.LIGHTCYAN_EX}╚════════════════════════════════════════════════════════════════════╝")
            print()
            print(f"  {Fore.LIGHTYELLOW_EX}В hosts-файле обнаружены прокси-домены. Хотите удалить их? (д/н){Fore.RESET}")
            
            choice = input("  > ").lower()
            if choice == 'д' or choice == 'y':
                result = hosts_manager.remove_proxy_domains()
                if result:
                    print()
                    print(f"  {Fore.LIGHTGREEN_EX}Прокси-домены успешно удалены из файла hosts.{Fore.RESET}")
                else:
                    print()
                    print(f"  {Fore.LIGHTRED_EX}Не удалось удалить записи из hosts-файла. Проверьте права администратора.{Fore.RESET}")
            else:
                print()
                print(f"  {Fore.LIGHTCYAN_EX}Операция отменена пользователем.{Fore.RESET}")
        else:
            # Если доменов нет, предлагаем добавить их
            print(f"  {Fore.LIGHTCYAN_EX}╔════════════════════════════════════════════════════════════════════╗")
            print(f"  {Fore.LIGHTCYAN_EX}║  {Fore.WHITE}Обновление hosts-файла для доступа к заблокированным сайтам  {Fore.LIGHTCYAN_EX}║")
            print(f"  {Fore.LIGHTCYAN_EX}╚════════════════════════════════════════════════════════════════════╝")
            print()
            
            result = hosts_manager.add_proxy_domains()
            
            if result:
                print()
                print(f"  {Fore.LIGHTGREEN_EX}Файл hosts успешно обновлен с {len(PROXY_DOMAINS)} записями.{Fore.RESET}")
            else:
                print()
                print(f"  {Fore.LIGHTRED_EX}Не удалось обновить файл hosts. Проверьте права администратора.{Fore.RESET}")
    except Exception as e:
        print()
        print(f"  {Fore.LIGHTRED_EX}Ошибка при работе с hosts-файлом: {str(e)}{Fore.RESET}")
    
    print()
    print(f"  {Fore.LIGHTCYAN_EX}Нажмите любую клавишу для возврата в главное меню...{Fore.RESET}")
    msvcrt.getch()

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
        
        # Проверка интернет-соединения
        if not check_internet():
            print("\n  Error 02: Отсутствует подключение к интернету.")
            time.sleep(4)
            sys.exit(1)
        
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
    except Exception as e:
        print(f"\n{Fore.LIGHTRED_EX}Критическая ошибка: {str(e)}{Fore.RESET}")
        print(f"{Fore.LIGHTYELLOW_EX}Нажмите любую клавишу для выхода...{Fore.RESET}")
        msvcrt.getch()
        sys.exit(1)
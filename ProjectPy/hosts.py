import ctypes
import os
import sys
import platform
import logging
from typing import Optional, Callable, Dict, List, Tuple

# Set up basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Define constants
LOCK_FILE_NAME = "hosts_manager.lock"

def get_hosts_path() -> str:
    """Determines the hosts file path based on the operating system."""
    if platform.system() == "Windows":
        return os.path.join(os.environ.get("SystemRoot", "C:\\Windows"), "System32\\drivers\\etc\\hosts")
    # Assume Unix-like systems (Linux, macOS)
    return "/etc/hosts"

class HostsManagerError(Exception):
    """Custom exception for HostsManager errors."""
    pass

class HostsManager:
    """
    Manages entries in the system's hosts file.

    Provides functionality to check, add, modify, and remove specific domain entries,
    primarily focused on proxy domains. Includes locking to prevent concurrent modifications
    and status reporting via callback or printing.
    """
    def __init__(self, status_callback: Optional[Callable[[str], None]] = None):
        """
        Initializes the HostsManager.

        Args:
            status_callback: An optional function to call with status messages.
                             If None, messages are printed to stdout.
        """
        self.status_callback = status_callback
        # Determine lock file path relative to the script or a temp dir for better robustness
        try:
            # Prefer script directory if writable, otherwise use temp dir
            script_dir = os.path.dirname(os.path.abspath(__file__))
            self._lock_file_path = os.path.join(script_dir, LOCK_FILE_NAME)
            # Test writability
            with open(self._lock_file_path, "a") as f: pass
            os.remove(self._lock_file_path)
        except (OSError, NameError, AttributeError): # Handle issues finding __file__ or permissions
             # Fallback to user's temp directory
            import tempfile
            self._lock_file_path = os.path.join(tempfile.gettempdir(), LOCK_FILE_NAME)

        self._hosts_path: str = get_hosts_path()
        logging.info(f"Using hosts file: {self._hosts_path}")
        logging.info(f"Using lock file: {self._lock_file_path}")


    def set_status(self, message: str, level: str = "info"):
        """Logs a message and optionally calls the status callback."""
        if level == "error":
            logging.error(message)
        elif level == "warning":
            logging.warning(message)
        else:
            logging.info(message)

        if self.status_callback:
            try:
                self.status_callback(message)
            except Exception as e:
                logging.error(f"Status callback failed: {e}")
        else:
            # Print errors and warnings to stderr, info to stdout
            print(message, file=sys.stderr if level in ["error", "warning"] else sys.stdout)

    def show_popup_message(self, title: str, message: str):
        """
        Shows a popup message box (Windows only).
        Falls back to printing if not on Windows or if ctypes fails.
        """
        if platform.system() == "Windows":
            try:
                ctypes.windll.user32.MessageBoxW(0, message, title, 0x40 | 0x1000) # MB_ICONINFORMATION | MB_SETFOREGROUND
                logging.info(f"Displayed popup: Title='{title}', Message='{message}'")
                return
            except Exception as e:
                logging.error(f"Failed to show Windows popup: {e}")
        # Fallback for non-Windows or ctypes failure
        self.set_status(f"--- POPUP ---\nTitle: {title}\nMessage: {message}\n-------------", level="warning")

    def _acquire_lock(self) -> bool:
        """
        Acquires an exclusive lock using a lock file.

        Returns:
            True if the lock was acquired successfully, False otherwise.
        """
        try:
            # Use os.O_CREAT | os.O_EXCL for atomic file creation check
            fd = os.open(self._lock_file_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.close(fd)
            logging.debug(f"Lock acquired: {self._lock_file_path}")
            return True
        except FileExistsError:
            logging.warning(f"Lock file {self._lock_file_path} already exists. Another operation may be running.")
            return False
        except OSError as e:
            self.set_status(f"Ошибка при попытке блокировки файла: {e}", level="error")
            # Raise a specific error to indicate a potential configuration/permission issue
            raise HostsManagerError(f"Не удалось создать файл блокировки: {e}") from e
        except Exception as e: # Catch any other unexpected error during lock acquisition
             self.set_status(f"Неожиданная ошибка при блокировке: {e}", level="error")
             raise HostsManagerError(f"Неожиданная ошибка при блокировке: {e}") from e


    def _release_lock(self):
        """Releases the lock by deleting the lock file."""
        try:
            if os.path.exists(self._lock_file_path):
                os.remove(self._lock_file_path)
                logging.debug(f"Lock released: {self._lock_file_path}")
        except OSError as e:
            # Log error but don't prevent further operations if lock release fails
            self.set_status(f"Ошибка при освобождении блокировки файла {self._lock_file_path}: {e}", level="error")
        except Exception as e:
             self.set_status(f"Неожиданная ошибка при освобождении блокировки: {e}", level="error")


    def _read_hosts_file(self) -> List[str]:
        """Reads the hosts file content with appropriate error handling."""
        try:
            with open(self._hosts_path, 'r', encoding='utf-8') as file:
                return file.readlines()
        except FileNotFoundError:
            self.set_status(f"Ошибка: Файл hosts не найден по пути {self._hosts_path}", level="error")
            raise HostsManagerError(f"Файл hosts не найден: {self._hosts_path}")
        except IOError as e:
            self.set_status(f"Ошибка чтения файла hosts: {e}", level="error")
            raise HostsManagerError(f"Ошибка чтения файла hosts: {e}") from e
        except Exception as e:
             self.set_status(f"Неожиданная ошибка при чтении hosts: {e}", level="error")
             raise HostsManagerError(f"Неожиданная ошибка при чтении hosts: {e}") from e

    def _write_hosts_file(self, lines: List[str]):
        """Writes lines to the hosts file with appropriate error handling."""
        try:
            with open(self._hosts_path, 'w', encoding='utf-8') as file:
                file.writelines(lines)
            logging.info(f"Successfully wrote {len(lines)} lines to {self._hosts_path}")
        except PermissionError:
            self.set_status("Ошибка доступа: Недостаточно прав для записи в файл hosts. Запустите программу от имени администратора.", level="error")
            raise HostsManagerError("Permission denied writing to hosts file. Run as administrator.")
        except IOError as e:
            self.set_status(f"Ошибка записи в файл hosts: {e}", level="error")
            raise HostsManagerError(f"Ошибка записи в файл hosts: {e}") from e
        except Exception as e:
            self.set_status(f"Неожиданная ошибка при записи в hosts: {e}", level="error")
            raise HostsManagerError(f"Неожиданная ошибка при записи в hosts: {e}") from e

    def _parse_line(self, line: str) -> Tuple[Optional[str], List[str]]:
        """Parses a hosts file line into IP (optional) and domains."""
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            return None, [] # Skip comments and empty lines

        # Remove inline comments
        parts = stripped.split('#', 1)
        entry_part = parts[0].strip()

        # Split by whitespace
        elements = entry_part.split()
        if len(elements) < 2:
            return None, [] # Invalid entry format

        ip_address = elements[0]
        domains = elements[1:]
        # Basic check if first part looks like an IP (v4 or v6 simplified)
        # This isn't a strict validation but helps filter malformed lines.
        if '.' not in ip_address and ':' not in ip_address:
             logging.warning(f"Ignoring malformed line (potential IP missing): {line.strip()}")
             return None, []

        return ip_address, domains

    def check_proxy_domains_in_hosts(self, proxy_domains_dict: Dict[str, str]) -> bool:
        """
        Checks if a significant portion (>30%) of proxy domains exist in the hosts file.

        Args:
            proxy_domains_dict: Dictionary of {domain: ip} to check for.

        Returns:
            True if more than 30% of the domains are found, False otherwise.
        """
        if not proxy_domains_dict:
            self.set_status("Список прокси-доменов для проверки пуст.", level="warning")
            return False

        try:
            lines = self._read_hosts_file()
        except HostsManagerError:
            return False # Error already reported by _read_hosts_file

        domains_found_count = 0
        target_domain_set = set(proxy_domains_dict.keys())

        for line in lines:
            _, domains_in_line = self._parse_line(line)
            for domain in domains_in_line:
                if domain in target_domain_set:
                    domains_found_count += 1
                    # Optimization: If a line matches, no need to check other domains on the same line
                    # against the count, but continue checking other lines.
                    # We count unique *domains* found across all lines. Let's refine logic slightly.
        
        # Count unique domains found
        found_domains_set = set()
        for line in lines:
             _, domains_in_line = self._parse_line(line)
             for domain in domains_in_line:
                 if domain in target_domain_set:
                     found_domains_set.add(domain)

        domains_found_count = len(found_domains_set)
        total_domains_to_check = len(target_domain_set)
        threshold = total_domains_to_check * 0.3

        is_present = domains_found_count > threshold
        self.set_status(
            f"Проверка hosts: Найдено {domains_found_count} из {total_domains_to_check} прокси-доменов. "
            f"Порог: >{threshold:.1f}. Результат: {'Записи присутствуют' if is_present else 'Записи отсутствуют или их мало'}"
        )
        return is_present

    def modify_hosts_file(self, domain_ip_dict: Dict[str, str], add_section_markers: bool = True) -> bool:
        """
        Adds or updates specified domain-IP mappings in the hosts file.
        Existing entries for the specified domains are removed before adding the new ones.

        Args:
            domain_ip_dict: Dictionary of {domain: ip} mappings to add/update.
            add_section_markers: If True, add comments indicating the managed section.

        Returns:
            True on success, False on failure.
        """
        if not self._acquire_lock():
            self.set_status("Другая операция уже выполняется. Пожалуйста, подождите.", level="warning")
            self.show_popup_message(
                "Операция не выполнена",
                "Другая операция уже выполняется. Пожалуйста, дождитесь её завершения."
            )
            return False

        success = False
        try:
            original_lines = self._read_hosts_file()
            target_domain_set = set(domain_ip_dict.keys())
            new_lines = []
            modified = False

            # Filter out existing lines containing the target domains
            for line in original_lines:
                ip, domains_in_line = self._parse_line(line)
                is_target_entry = False
                if domains_in_line: # Check if it's a valid entry line we parsed
                    for domain in domains_in_line:
                        if domain in target_domain_set:
                            is_target_entry = True
                            break # This line contains a domain we manage

                if is_target_entry:
                    modified = True # Mark that we are removing something
                    logging.debug(f"Removing existing line: {line.strip()}")
                else:
                    # Keep lines that are comments, empty, or don't contain target domains
                    new_lines.append(line)

            # Ensure last line has a newline if it doesn't
            if new_lines and not new_lines[-1].endswith(('\n', '\r')):
                 new_lines[-1] += os.linesep

            # Add the new domain entries
            if domain_ip_dict:
                modified = True # Mark that we are adding something
                if add_section_markers:
                     # Add a blank line before the section if needed
                    if new_lines and new_lines[-1].strip():
                         new_lines.append(os.linesep)
                    new_lines.append(f"# --- Managed by HostsManager START ---{os.linesep}")

                for domain, ip in domain_ip_dict.items():
                    # Use tab for alignment, common practice in hosts files
                    new_lines.append(f"{ip}\t{domain}{os.linesep}")
                    logging.debug(f"Adding entry: {ip} {domain}")

                if add_section_markers:
                    new_lines.append(f"# --- Managed by HostsManager END ---{os.linesep}")

            # Write back only if changes were made
            if modified:
                self._write_hosts_file(new_lines)
                self.set_status(f"Файл hosts обновлен: добавлено/обновлено {len(domain_ip_dict)} записей.", level="info")
                self.show_popup_message(
                    "Файл hosts обновлен",
                    "Изменения внесены в файл hosts.\n\n"
                    "ВАЖНО: Для применения изменений может потребоваться:\n"
                    "- Очистить кэш DNS (`ipconfig /flushdns` в командной строке от имени администратора)\n"
                    "- Перезапустить веб-браузеры и другие затронутые приложения (например, Spotify)."
                )
            else:
                self.set_status("Файл hosts уже содержит необходимые записи или не требовал изменений.", level="info")

            success = True

        except HostsManagerError as e:
            # Error already logged by helper methods or acquire_lock
            self.set_status(f"Операция с файлом hosts не удалась: {e}", level="error")
            success = False
        except Exception as e:
            self.set_status(f"Неожиданная ошибка при изменении hosts: {e}", level="error")
            logging.exception("Unexpected error during modify_hosts_file") # Log full traceback for unexpected errors
            success = False
        finally:
            self._release_lock()

        return success

    def remove_proxy_domains(self, proxy_domains_dict: Dict[str, str]) -> bool:
        """
        Removes specified proxy domains from the hosts file.

        Args:
            proxy_domains_dict: Dictionary of {domain: ip} whose domains should be removed.

        Returns:
            True on success (or if domains were already absent), False on failure.
        """
        if not self._acquire_lock():
            self.set_status("Другая операция уже выполняется. Пожалуйста, подождите.", level="warning")
            self.show_popup_message(
                "Операция не выполнена",
                "Другая операция уже выполняется. Пожалуйста, дождитесь её завершения."
            )
            return False

        success = False
        try:
            original_lines = self._read_hosts_file()
            target_domain_set = set(proxy_domains_dict.keys())
            new_lines = []
            removed_count = 0

            # Filter out lines containing the target domains
            for line in original_lines:
                ip, domains_in_line = self._parse_line(line)
                is_target_entry = False
                if domains_in_line: # Check if it's a valid entry line we parsed
                    for domain in domains_in_line:
                        if domain in target_domain_set:
                            is_target_entry = True
                            break # This line contains a domain to be removed

                if is_target_entry:
                    removed_count += 1
                    logging.debug(f"Removing line: {line.strip()}")
                else:
                    # Keep lines that are comments, empty, or don't contain target domains
                    new_lines.append(line)

            # Write back only if changes were made
            if removed_count > 0:
                self._write_hosts_file(new_lines)
                self.set_status(f"Прокси-домены ({removed_count} строк(и) удалено) успешно удалены из файла hosts.", level="info")
                self.show_popup_message(
                    "Файл hosts обновлен",
                    f"Прокси-домены удалены из файла hosts ({removed_count} строк(и)).\n\n"
                    "Для полного применения изменений перезапустите браузеры и другие затронутые приложения."
                )
            else:
                self.set_status("Указанные прокси-домены не найдены в файле hosts. Удаление не требуется.", level="info")

            success = True

        except HostsManagerError as e:
            # Error already logged
             self.set_status(f"Операция удаления из файла hosts не удалась: {e}", level="error")
             success = False
        except Exception as e:
            self.set_status(f"Неожиданная ошибка при удалении из hosts: {e}", level="error")
            logging.exception("Unexpected error during remove_proxy_domains")
            success = False
        finally:
            self._release_lock()

        return success

    def add_proxy_domains(self, proxy_domains_dict: Dict[str, str]) -> bool:
        """
        Adds or updates proxy domains in the hosts file using the provided dictionary.
        This is a convenience wrapper around `modify_hosts_file`.

        Args:
            proxy_domains_dict: Dictionary of {domain: ip} mappings to add/update.

        Returns:
            True on success, False on failure.
        """
        if not proxy_domains_dict:
             self.set_status("Нет доменов для добавления.", level="warning")
             return False # Or True, arguably, as the state is achieved? False seems better.

        self.set_status(f"Добавление/обновление {len(proxy_domains_dict)} прокси-доменов в файл hosts...")
        return self.modify_hosts_file(proxy_domains_dict, add_section_markers=True)

    def check_all_configurations(self, proxy_domains_dict: Dict[str, str]):
        """
        Performs a series of checks related to hosts file configuration.
        Currently only checks for the presence of proxy domains.

         Args:
            proxy_domains_dict: Dictionary of {domain: ip} to check for.
        """
        if not self._acquire_lock():
            self.set_status("Другая операция уже выполняется. Пожалуйста, подождите.", level="warning")
            self.show_popup_message(
                "Проверка не выполнена",
                "Другая операция уже выполняется. Пожалуйста, дождитесь её завершения."
            )
            return # Indicate failure or inability to run? Let's just return.

        try:
            self.set_status("Начинаем проверку конфигураций...")

            # Check 1: Presence of proxy domains in hosts file
            self.check_proxy_domains_in_hosts(proxy_domains_dict)
            # Status message is already set within check_proxy_domains_in_hosts

            # --- Placeholder for future checks ---
            # Example: Check DNS resolution for a specific domain
            # self.set_status("Проверка разрешения DNS для example.com...")
            # try:
            #     ip = socket.gethostbyname("example.com")
            #     self.set_status(f"example.com разрешается в {ip}")
            # except socket.gaierror as e:
            #     self.set_status(f"Не удалось разрешить example.com: {e}", level="warning")

            # Example: Check connectivity to a proxy server (if applicable)
            # self.set_status("Проверка доступности прокси...")
            # is_proxy_reachable = check_proxy_connectivity("proxy.example.com", 8080)
            # self.set_status(f"Прокси сервер {'доступен' if is_proxy_reachable else 'не доступен'}")
            # --- End Placeholder ---

            self.set_status("Проверка конфигураций завершена.")

        except HostsManagerError as e:
             # Errors during checks (e.g., reading hosts file) are caught here
             self.set_status(f"Ошибка во время проверки конфигураций: {e}", level="error")
        except Exception as e:
            self.set_status(f"Неожиданная ошибка при проверке конфигураций: {e}", level="error")
            logging.exception("Unexpected error during check_all_configurations")
        finally:
            self._release_lock()


# Example Usage (assuming proxy_domains.py exists with a PROXY_DOMAINS dict)
if __name__ == "__main__":
    # Dummy callback function
    def my_status_callback(message: str):
        print(f"[CALLBACK] {message}")

    # Dummy proxy domains for testing
    try:
        # Attempt to import actual domains if available for a more realistic test
        from proxy_domains import PROXY_DOMAINS
        print("Using PROXY_DOMAINS from proxy_domains.py")
    except ImportError:
        print("proxy_domains.py not found, using dummy data.")
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
        "www.notion.so": "94.131.119.85", # 204.12.192.222
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
        "grok.com": "185.250.151.49", # 50.7.85.221
        "accounts.x.ai": "185.250.151.49", # 50.7.87.85
        "autodesk.com": "94.131.119.85",
        "accounts.autodesk.com": "94.131.119.85",
        "claude.ai": "204.12.192.222",
        "only-fans.uk": "0.0.0.0",
        "only-fans.me": "0.0.0.0",
        "only-fans.wtf": "0.0.0.0"
        }

    manager = HostsManager(status_callback=my_status_callback)

    print("\n--- Running Checks ---")
    manager.check_all_configurations(PROXY_DOMAINS)

    # print("\n--- Attempting to Add Domains ---")
    # Note: This requires administrator privileges to succeed on most systems.
    # manager.add_proxy_domains(PROXY_DOMAINS)

    # print("\n--- Running Checks Again ---")
    # manager.check_all_configurations(PROXY_DOMAINS)

    # print("\n--- Attempting to Remove Domains ---")
    # Note: This also requires administrator privileges.
    # manager.remove_proxy_domains(PROXY_DOMAINS)

    # print("\n--- Running Checks Final Time ---")
    # manager.check_all_configurations(PROXY_DOMAINS)

    print("\n--- Testing Lock ---")
    if manager._acquire_lock():
        print("Main script acquired lock.")
        # Try acquiring lock again (should fail)
        if not manager._acquire_lock():
             print("Second acquire failed as expected.")
        else:
             print("ERROR: Second acquire succeeded unexpectedly!")
        manager._release_lock()
        print("Main script released lock.")
    else:
        print("Main script failed to acquire lock (unexpected).")

    print("\n--- Example Finished ---")
import ctypes

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
        from proxy_domains import PROXY_DOMAINS
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
        from proxy_domains import PROXY_DOMAINS
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
        """Добавляет или обновляет прокси домены в файле hosts, используя внешний словарь PROXY_DOMAINS"""
        from proxy_domains import PROXY_DOMAINS
        return self.modify_hosts_file(PROXY_DOMAINS)

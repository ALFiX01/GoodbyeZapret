# GoodbyeZapret

<div align="center">
  <a href="https://github.com/ALFiX01/GoodbyeZapret">
    <img src="https://github.com/ALFiX01/GoodbyeZapret/blob/main/Files/Image/Design3.png?raw=true" alt="GoodbyeZapret Logo Banner" >
  </a>
  <br />
  <p><strong>Инструмент для обхода DPI-блокировок в Windows.</strong></p>

  <p>
    <a href="https://github.com/ALFiX01/GoodbyeZapret/releases/latest"><img src="https://img.shields.io/github/v/release/ALFiX01/GoodbyeZapret?style=plastic" alt="GitHub Release"></a>
    <a href="https://github.com/ALFiX01/GoodbyeZapret/stargazers"><img src="https://img.shields.io/github/stars/ALFiX01/GoodbyeZapret?style=plastic" alt="GitHub Stars"></a>
    <a href="https://github.com/ALFiX01/GoodbyeZapret/releases"><img src="https://img.shields.io/github/downloads/ALFiX01/GoodbyeZapret/total?style=plastic" alt="GitHub Downloads"></a>
    <a href="https://github.com/ALFiX01/GoodbyeZapret/releases"><img src="https://img.shields.io/github/downloads/ALFiX01/GoodbyeZapret/GoodbyeZapret.zip?style=plastic" alt="GitHub EXE Downloads"></a>
  </p>
  
</div>

> **Важно:** GoodbyeZapret не предназначен для использования в целях обхода законных ограничений или нарушений условий обслуживания интернет-провайдеров. Проект создан исключительно в образовательных и исследовательских целях, в том числе для изучения работы сетевых протоколов и механизмов фильтрации. Ответственность за любое использование программного обеспечения лежит исключительно на конечном пользователе.

---

**GoodbyeZapret** — это инструмент с открытым исходным кодом на базе [zapret-win-bundle/zapret-winws](https://github.com/bol-van/zapret-win-bundle/tree/master/zapret-winws), предназначенный для обхода блокировок на основе DPI (Deep Packet Inspection) в Windows. 

*Инструмент изменяет сетевые пакеты так, чтобы DPI-системы не могли корректно определить заблокированный ресурс.*

---
## ⚠️ Важное предупреждение об антивирусах

> [!CAUTION]
> **WinDivert и Launcher могут определяться как `HackTool`, `RiskTool` или `trojan`**, поскольку:

1. `WinDivert` Перехватывает и модифицирует сетевые пакеты
2. `Launcher` Вносит изменения в реестр для автозапуска и изменения параметров контроля учётных записей (UAC)

**Решение:**

- Добавьте папку `<Системный диск>:\GoodbyeZapret` в исключения антивируса
- Скомпилируйте проект из исходников, если доверяете коду
- Не используйте проект, если у вас есть сомнения или вы не доверяете исходному коду.

---
> [!IMPORTANT]
> Все файлы в [`bin`](./Project/bin) взяты из [zapret-winws](https://github.com/bol-van/zapret-win-bundle/tree/master/zapret-winws). Вы можете это проверить с помощью хэшей/контрольных сумм.
> Выражаем благодарность [bol-van](https://github.com/bol-van).

---

## ✨ Возможности

- 🚀 Обход блокировок на основе DPI
- 🔧 Готовые конфиги для YouTube, Discord и др.
- 💻 Простые `.bat` скрипты
- ⚙️ Поддержка автозапуска
- 📐 Утилита для проверки доступа
- 📂 Открытый код

---

## 💻 Системные требования

- Windows 10/11
- Права администратора

---

## 📦 Установка

1. Скачайте архив `GoodbyeZapret.zip` из раздела [релизов](https://github.com/ALFiX01/GoodbyeZapret/releases/latest).
2. Распакуйте архив на системный диск (например, `C:\`).
   > ⚠️ Путь **не должен** содержать пробелов или кириллических символов.
3. Убедитесь, что путь к исполняемому файлу следующий:
   ```
   <Системный диск>:\GoodbyeZapret\Launcher.exe
   ```
4. Запустите `Launcher.exe` **от имени администратора** — это необходимо для применения сетевых настроек.
5. При первом запуске программа автоматически скачает все необходимые компоненты.

---

## 🔄 Ручное обновление

### ⚡ Способ 1 — Быстрое обновление

Просто запустите файл обновления:

```
<Системный диск>:\GoodbyeZapret\tools\Updater.exe
```

Он автоматически загрузит и установит последнюю версию GoodbyeZapret.

> ⚠️ Обязательно запускать **от имени администратора**.

---

### 🧱 Способ 2 — Обновление вручную

1. Скачайте свежий архив `GoodbyeZapret.zip` из раздела [релизов](https://github.com/ALFiX01/GoodbyeZapret/releases/latest).
2. Удалите старое содержимое папки:
   ```
   <Системный диск>:\GoodbyeZapret
   ```
3. Распакуйте содержимое архива в ту же папку.
4. Убедитесь, что путь к исполняемому файлу следующий:
   ```
   <Системный диск>:\GoodbyeZapret\Launcher.exe
   ```
5. Запустите `Launcher.exe` **от имени администратора**.

> 💡 Рекомендуется перед обновлением закрыть все активные конфиги и консоли GoodbyeZapret.


---

## ▶️ Быстрый старт

1. Перейдите в папку:
   ```
   <Системный диск>:\GoodbyeZapret\configs
   ```
2. Запустите нужный `.bat` файл **от имени администратора**:
   - `UltimateFix.bat` — основной вариант для обхода блокировок Discord, YouTube и других сервисов.
   - `WebUnlock.bat` — аналог `UltimateFix`, но с более широким списком сайтов и другими стратегиями обхода.
   - Альтернативные варианты:
     - `UltimateFix_2.bat`
     - `UltimateFix_3.bat`
     - `WebUnlock_2.bat`
     - и другие.
3. **Не закрывайте** окно консоли (с чёрным фоном) — оно должно оставаться открытым для работы.
4. Чтобы остановить работу — просто закройте окно консоли.


---

## 🔁 Автозапуск

1. Запустите файл:
   ```
   C:\GoodbyeZapret\Launcher.exe
   ```
   от имени администратора.
2. В открывшемся меню:
   - Выберите нужный скрипт, указав его номер.
   - Подтвердите установку в автозагрузку.
3. Чтобы удалить автозапуск, снова запустите:
   ```
   C:\GoodbyeZapret\Launcher.exe
   ```
   - выберите опцию `DS` (удаление из автозагрузки).

---

## 🛠️ Устранение неполадок

### 🚫 Нет эффекта

- Убедитесь, что `.bat`-файл запущен **от имени администратора**.
- Проверьте корректность пути к скрипту:
  ```
  <Системный диск>:\GoodbyeZapret\configs\...
  ```
- Попробуйте использовать другой конфигурационный файл.

### 🧹 Файлы удаляются

- Добавьте папку в исключения антивируса:
  ```
  <Системный диск>:\GoodbyeZapret
  ```
- Переустановите GoodbyeZapret, следуя [инструкции по установке](#-установка).

### ⚠️ Нестабильная работа

- Попробуйте другой конфиг.
- Отключите VPN/анонимайзеры, если они используются.
- Проверьте параметры в Chrome:
  - Перейдите по адресу `chrome://flags`
  - Убедитесь, что **QUIC** и **TLS 1.3** установлены в значение **Default**.

### ❗ Ошибки при запуске

- Убедитесь, что путь установки **не содержит пробелов и кириллицы**.
- GoodbyeZapret должен быть установлен строго на **системном диске**, например:
  ```
  <Системный диск>:\GoodbyeZapret
  ```

---

### 🧪 Быстрая диагностика

`Launcher.bat` может автоматически выполнить проверку системы на наличие потенциальных проблем которые могут повлиять на работу программы.

1. Откройте:
   ```
   <Системный диск>:\GoodbyeZapret\Launcher.bat
   ```
   от имени администратора.
2. В меню выберите опцию:
   ```
   ST
   ```
   Если проблемы будут обнаружены, программа сообщит вам о них в этом меню.


---

## ⚖️ Дисклеймер

Программное обеспечение GoodbyeZapret предоставляется "как есть", без каких-либо гарантий. Используйте этот инструмент на свой страх и риск. Разработчики не несут ответственности за:

* Любые возможные проблемы с вашим интернет-соединением.
* Блокировки или иные действия со стороны вашего интернет-провайдера.
* Любые другие последствия, прямые или косвенные, возникшие в результате использования GoodbyeZapret.

Убедитесь, что использование подобных инструментов не противоречит законодательству вашей страны и условиям предоставления услуг вашего интернет-провайдера.

---

## 📣 Контакты

Следите за новостями в [Telegram-канале разработчика](https://t.me/+4yHMA3RtghY1YzIy)

---

<div align="center">
  ⭐ Понравился проект? Поставь звезду! ⭐
</div>

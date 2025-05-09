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

- Добавьте папку `C:\GoodbyeZapret` в исключения антивируса
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

- ОС: Windows 10/11
- Права администратора

---

## 📦 Установка

1. Скачайте `GoodbyeZapret.zip` из [релизов](https://github.com/ALFiX01/GoodbyeZapret/releases/latest)
2. Распакуйте архив в `<Системный диск>:\GoodbyeZapret` (в пути не должно быть пробелов и кириллицы)
3. Проверьте путь к `Launcher.exe`. Корректный путь:  
   ```<Системный диск>:\GoodbyeZapret\Launcher.exe```
4. Запустите `Launcher.exe` **от имени администратора** (требуется для изменения сетевых настроек)
5. При первом запуске программа автоматически скачает необходимые компоненты.
---

## ▶️ Быстрый старт

1. Откройте `Configs`
2. Запустите нужный `.bat` от имени администратора:
   - `UltimateFix.bat` — основной вариант для обхода Discord и Youtube и др.
   - `WebUnlock.bat` — схож с UltimateFix, но имеет более широкий список и другие стратегии.
   - Альтернативы: `UltimateFix_2.bat`, `UltimateFix_3.bat`, `WebUnlock.bat`, `WebUnlock_2.bat` и тд
3. Не закрывайте окно с чёрным фоном (консолью)
4. Чтобы остановить — просто закройте окно

---

## 🔁 Автозапуск

1. Запустите `Launcher.bat` от имени администратора
2. Выберите нужный скрипт для автозапуска и выберите опцию установки в автозапуск ("<номер конфига>")
3. Для удаления автозапуска запустите `Launcher.bat` и выберите опцию удаления (DS)

---

## 🛠️ Устранение неполадок

```text
Нет эффекта:
  - Убедитесь, что .bat-файл запущен от имени администратора
  - Проверьте корректность пути
  - Попробуйте другой конфиг

Файлы удаляются:
  - Добавьте C:\GoodbyeZapret в исключения антивируса
  - Переустановите GoodbyeZapret

Нестабильная работа:
  - Попробуйте другой конфиг
  - Отключите VPN
  - Проверьте QUIC (default) и TLS 1.3 (default) в chrome://flags

Ошибки при запуске:
  - Убедитесь, что путь не содержит пробелов и кириллицы
  - GoodbyeZapret должен быть строго на системном диске
```


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

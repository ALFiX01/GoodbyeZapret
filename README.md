# GoodbyeZapret 1.6.2

<div align="center">
  <a href="https://github.com/ALFiX01/GoodbyeZapret">
    <img src="https://github.com/ALFiX01/GoodbyeZapret/blob/main/Files/Image/Design2.png?raw=true" alt="GoodbyeZapret Logo Banner" >
  </a>
  <br />
  <p><strong>Инструмент для обхода DPI-блокировок в Windows.</strong></p>

  <p>
    <a href="https://github.com/ALFiX01/GoodbyeZapret/releases/latest"><img src="https://img.shields.io/github/v/release/ALFiX01/GoodbyeZapret?style=plastic" alt="GitHub Release"></a>
    <a href="https://github.com/ALFiX01/GoodbyeZapret/commits/main"><img src="https://img.shields.io/github/last-commit/ALFiX01/GoodbyeZapret?style=plastic" alt="GitHub Last Commit"></a>
    <a href="https://github.com/ALFiX01/GoodbyeZapret/stargazers"><img src="https://img.shields.io/github/stars/ALFiX01/GoodbyeZapret?style=plastic" alt="GitHub Stars"></a>
    <a href="https://github.com/ALFiX01/GoodbyeZapret/releases"><img src="https://img.shields.io/github/downloads/ALFiX01/GoodbyeZapret/total?style=plastic" alt="GitHub Downloads"></a>
  </p>
  
  <br />

  ⚠️ <strong>Дисклеймер:</strong> Изображение в шапке (баннер) не связано с проектом <a href="https://github.com/bol-van/zapret">zapret</a> от bol-van. Оно является авторским художественным элементом и символизирует идею обхода блокировок. Надпись "ZAPRET" и жест на изображении не выражают отношения к каким-либо сторонним проектам и используются исключительно в контексте оформления этого репозитория.
</div>

---

**GoodbyeZapret** — это инструмент с открытым исходным кодом на базе [zapret-win-bundle/zapret-winws](https://github.com/bol-van/zapret-win-bundle/tree/master/zapret-winws), предназначенный для обхода блокировок на основе DPI (Deep Packet Inspection) в Windows. Он помогает пользователям получать доступ к веб-сайтам и сервисам, ограниченным на территории их страны.

---

## 📖 Оглавление

- [Предупреждение об антивирусах](#предупреждение-об-антивирусах)
- [Информация о bin файлах](#информация-о-bin-файлах)
- [Как это работает?](#как-это-работает)
- [Возможности](#возможности)
- [Системные требования](#системные-требования)
- [Установка](#установка)
- [Использование](#использование)
- [Автозапуск](#автозапуск)
- [Устранение неполадок](#устранение-неполадок)
- [Дисклеймер](#дисклеймер)
- [Внесение вклада](#внесение-вклада)

---

## ⚠️ Предупреждение об антивирусах

> **Возможные срабатывания антивирусов**

Некоторые компоненты GoodbyeZapret, в частности **WinDivert**, могут определяться как `HackTool` или `RiskTool`.

### Почему?

Программа перехватывает и модифицирует сетевой трафик — это может быть воспринято как подозрительная активность.

### Что делать?

1. **Добавить в исключения** — [скачайте релиз](https://github.com/ALFiX01/GoodbyeZapret/releases/latest) и добавьте `C:\GoodbyeZapret` в исключения антивируса.
2. **Собрать самостоятельно** — [скомпилируйте из исходников](https://github.com/ALFiX01/GoodbyeZapret).
3. **Не использовать**, если не доверяете.

---

## 📁 Информация о bin файлах

> Все файлы в [`bin`](./Project/bin) взяты из [zapret-winws](https://github.com/bol-van/zapret-win-bundle/tree/master/zapret-winws).

Выражаем благодарность [bol-van](https://github.com/bol-van).

---

## ⚙️ Как это работает?

Инструмент изменяет сетевые пакеты так, чтобы DPI-системы не могли корректно определить заблокированный ресурс. Основано на [**zapret**](https://github.com/bol-van/zapret).

---

## ✨ Возможности

- 🚀 Обход DPI-блокировок
- 🔧 Готовые конфиги для YouTube, Discord и др.
- 💻 Простые `.bat` скрипты
- ⚙️ Поддержка автозапуска
- 📂 Открытый код

---

## 💻 Системные требования

- **Windows 10/11** (возможна работа и на старых)
- **Права администратора** (обязательно)

---

## 📦 Установка

1. Скачайте `GoodbyeZapret.zip` из [релизов](https://github.com/ALFiX01/GoodbyeZapret/releases/latest)
2. Распакуйте в `C:\GoodbyeZapret` (короткий путь, без пробелов и кириллицы)

---

## 🚀 Использование

1. Откройте `Configs`
2. Запустите нужный `.bat` от имени администратора:
   - `UltimateFix.bat` — основной вариант
   - Альтернативы: `UltimateFix_ALT.bat`, `UltimateFix_ALT_2.bat`
   - Для YouTube: `YoutubeFix*.bat`
   - Для Discord: `DiscordFix*.bat`
3. Не закрывайте окно с чёрным фоном (работает в фоне)
4. Чтобы остановить — просто закройте окно

---

## 🔁 Автозапуск

1. Выберите рабочий `.bat` файл
2. Запустите `Launcher.bat` от имени администратора
3. Следуйте инструкциям — он добавит задачу в Планировщик
4. Чтобы удалить — снова запустите `Launcher.bat` и выберите опцию удаления

---

## 🛠️ Устранение неполадок

- **Нет эффекта:** запустили `.bat` с админ-правами? Путь корректный?
- **Файлы удалены:** восстановите и добавьте в исключения
- **Работает нестабильно:** пробуйте альтернативные конфиги
- **Конфликтует с VPN:** отключите другие сетевые инструменты
- **Ошибки запуска:** путь без пробелов/кириллицы и на диске `C:`

---

## ⚖️ Дисклеймер

Программное обеспечение GoodbyeZapret предоставляется "как есть", без каких-либо гарантий. Используйте этот инструмент на свой страх и риск. Разработчики не несут ответственности за:

*   Любые возможные проблемы с вашим интернет-соединением.
*   Блокировки или иные действия со стороны вашего интернет-провайдера.
*   Любые другие последствия, прямые или косвенные, возникшие в результате использования GoodbyeZapret.

Убедитесь, что использование подобных инструментов для обхода блокировок не противоречит законодательству вашей страны и условиям предоставления услуг вашего интернет-провайдера.

---

## 🤝 Внесение вклада

- Создайте [Issue](https://github.com/ALFiX01/GoodbyeZapret/issues) для ошибок/предложений
- Форкните репозиторий и создайте Pull Request

---

<div align="center">
  ⭐ Понравился проект? Поставь звезду! ⭐
</div>

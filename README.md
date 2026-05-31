# NetCrazyBot

Telegram бот для генерации .bat файлов с командами маршрутизации на основе DNS разрешения доменов.

## Описание

Бот разрешает DNS для указанных доменов через 10 различных DNS серверов и создает Windows batch файлы с командами `route add` в формате Keenetic для всех найденных IP адресов (только IPv4). Это полезно для настройки маршрутизации на роутерах Keenetic и других устройствах.

## Возможности

- ✅ Разрешение DNS через 10 серверов (Yandex, Google, Cloudflare, OpenDNS)
- ✅ Поддержка только IPv4 адресов
- ✅ Генерация .bat файлов в формате Keenetic с комментариями доменов
- ✅ Обработка списка доменов (каждый с новой строки)
- ✅ Автоматическое объединение результатов в один файл
- ✅ Защита от флуда (5 запросов в минуту на пользователя)
- ✅ Автоматическая очистка старых файлов (каждые 6 часов, файлы старше 24 часов)
- ✅ Статистика по доменам и IP адресам
- ✅ Автоматический перезапуск при сбоях

## Требования

### Вариант 1: Docker (рекомендуется)
- Docker
- Docker Compose
- Telegram Bot Token (получить у [@BotFather](https://t.me/BotFather))

### Вариант 2: Локальная установка
- Node.js 16.x или выше
- npm или yarn
- Telegram Bot Token (получить у [@BotFather](https://t.me/BotFather))

## Получение Telegram Bot Token

1. Откройте Telegram и найдите [@BotFather](https://t.me/BotFather)
2. Отправьте команду `/newbot`
3. Следуйте инструкциям для создания бота
4. Скопируйте полученный токен

## Установка и запуск

### Вариант 1: Docker (рекомендуется для продакшена)

1. Клонируйте репозиторий:
```bash
git clone https://gitlab.com/kosmostar777/netcrazybot.git
cd netcrazybot
```

2. Создайте файл `.env`:
```bash
echo "TELEGRAM_BOT_TOKEN=your_bot_token_here" > .env
```

3. Соберите и запустите бота:
```bash
docker build -t netcrazybot .
docker run -d --name netcrazybot --restart unless-stopped \
  -v $(pwd)/output:/app/output \
  --env-file .env \
  netcrazybot
```

4. Проверьте логи:
```bash
docker logs -f netcrazybot
```

### Управление ботом через Docker

**Просмотр логов:**
```bash
docker logs -f netcrazybot
```

**Остановка бота:**
```bash
docker stop netcrazybot
```

**Запуск бота:**
```bash
docker start netcrazybot
```

**Перезапуск бота:**
```bash
docker restart netcrazybot
```

**Удаление контейнера:**
```bash
docker stop netcrazybot
docker rm netcrazybot
```

**Обновление бота:**
```bash
git pull origin main
docker stop netcrazybot
docker rm netcrazybot
docker build -t netcrazybot .
docker run -d --name netcrazybot --restart unless-stopped \
  -v $(pwd)/output:/app/output \
  --env-file .env \
  netcrazybot
```

**Проверка статуса:**
```bash
docker ps | grep netcrazybot
```

### ⚠️ Важно: Автоматический перезапуск

Бот настроен с флагом `--restart unless-stopped`, что означает:
- ✅ Бот автоматически перезапустится при сбое
- ✅ Бот автоматически запустится при перезагрузке сервера
- ✅ Бот НЕ запустится, если вы его остановили вручную командой `docker stop`

Чтобы проверить политику перезапуска:
```bash
docker inspect netcrazybot | grep -A 5 RestartPolicy
```

### Вариант 2: Локальная установка

1. Клонируйте репозиторий:
```bash
git clone https://gitlab.com/kosmostar777/netcrazybot.git
cd netcrazybot
```

2. Установите зависимости:
```bash
npm install
```

3. Создайте файл `.env`:
```bash
cp .env.example .env
```

4. Откройте `.env` и добавьте ваш Telegram Bot Token:
```
TELEGRAM_BOT_TOKEN=your_bot_token_here
```

5. Запустите бота:
```bash
npm start
```

6. В режиме разработки (с автоперезагрузкой):
```bash
npm run dev
```

## Использование

1. Найдите вашего бота в Telegram
2. Отправьте команду `/start` для получения инструкций
3. Отправьте домен или список доменов:

**Один домен:**
```
rutube.ru
```

**Несколько доменов:**
```
rutube.ru
ozon.ru
wildberries.ru
```

4. Бот обработает домены через 10 DNS серверов и отправит вам .bat файл
5. Бот покажет статистику: количество доменов и IP адресов
6. Запустите файл от имени администратора на Windows для добавления маршрутов

## Команды бота

- `/start` - Показать приветственное сообщение и примеры использования
- `/help` - Показать справку по использованию

## Защита от флуда

Бот имеет встроенную защиту от флуда:
- **Лимит:** 5 запросов в минуту на пользователя
- При превышении лимита бот сообщит, сколько секунд нужно подождать

## Автоматическая очистка файлов

Бот автоматически удаляет старые файлы:
- **Интервал проверки:** каждые 6 часов
- **Время хранения:** 24 часа
- Это предотвращает переполнение диска

## Пример сгенерированного файла

**Имя файла:** `rutube_ru_keenetic.bat` (для одного домена)
**Имя файла:** `rutube_ru_and_2_other_keenetic.bat` (для нескольких доменов)

**Содержимое:**
```batch
route add 5.101.71.71 mask 255.255.255.255 0.0.0.0 :: rem rutube.ru
route add 176.114.120.24 mask 255.255.255.255 0.0.0.0 :: rem rutube.ru
route add 176.114.122.24 mask 255.255.255.255 0.0.0.0 :: rem rutube.ru
route add 178.248.235.114 mask 255.255.255.255 0.0.0.0 :: rem ozon.ru
route add 185.5.136.11 mask 255.255.255.255 0.0.0.0 :: rem ozon.ru
```

**Формат команды:**
- `route add` - команда добавления маршрута (lowercase для Keenetic)
- `IP` - IPv4 адрес
- `mask 255.255.255.255` - маска подсети
- `0.0.0.0` - шлюз по умолчанию
- `:: rem domain` - комментарий с именем домена

## Структура проекта

```
netcrazybot/
├── src/
│   ├── index.js          # Точка входа
│   ├── bot.js            # Логика Telegram бота
│   ├── config.js         # Конфигурация
│   ├── dnsResolver.js    # DNS разрешение через 10 серверов
│   ├── fileGenerator.js  # Генерация .bat файлов
│   ├── antiflood.js      # Защита от флуда
│   └── fileCleanup.js    # Автоматическая очистка файлов
├── output/               # Сгенерированные файлы (автоочистка каждые 6 часов)
├── .env                  # Переменные окружения (не в git)
├── .gitlab-ci.yml        # CI/CD конфигурация
├── Dockerfile            # Docker образ
├── docker-compose.yml    # Docker Compose конфигурация
├── .gitignore
├── package.json
└── README.md
```

## Деплой на сервер

### 🚀 Быстрая установка (рекомендуется)

Автоматическая установка одной командой:

```bash
curl -fsSL https://gitlab.com/kosmostar777/netcrazybot/-/raw/main/install.sh | sudo bash
```

Или скачайте и запустите:

```bash
wget https://gitlab.com/kosmostar777/netcrazybot/-/raw/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

**Что делает скрипт:**
- ✅ Устанавливает Docker (если не установлен)
- ✅ Устанавливает Git (если не установлен)
- ✅ Клонирует репозиторий в `/opt/netcrazybot`
- ✅ Запрашивает Telegram Bot Token
- ✅ Создает `.env` файл
- ✅ Собирает и запускает Docker контейнер
- ✅ Настраивает автоматический перезапуск

### 🔄 Обновление бота

```bash
curl -fsSL https://gitlab.com/kosmostar777/netcrazybot/-/raw/main/update.sh | sudo bash
```

Или:

```bash
cd /opt/netcrazybot
sudo ./update.sh
```

**Что делает скрипт:**
- ✅ Сохраняет текущую конфигурацию (.env)
- ✅ Обновляет код из Git
- ✅ Пересобирает Docker образ
- ✅ Перезапускает контейнер

### 🗑️ Удаление бота

```bash
curl -fsSL https://gitlab.com/kosmostar777/netcrazybot/-/raw/main/uninstall.sh | sudo bash
```

Или:

```bash
cd /opt/netcrazybot
sudo ./uninstall.sh
```

### 📋 Ручная установка

Если предпочитаете ручную установку:

1. Установите Docker на сервере:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io git
sudo systemctl enable docker
sudo systemctl start docker
```

2. Клонируйте репозиторий в `/opt/netcrazybot`:
```bash
sudo mkdir -p /opt/netcrazybot
cd /opt/netcrazybot
sudo git clone https://gitlab.com/kosmostar777/netcrazybot.git .
```

3. Создайте `.env` файл с токеном:
```bash
echo "TELEGRAM_BOT_TOKEN=your_bot_token_here" > .env
```

4. Соберите и запустите бота:
```bash
sudo docker build -t netcrazybot .
sudo docker run -d --name netcrazybot --restart unless-stopped \
  -v /opt/netcrazybot/output:/app/output \
  --env-file .env \
  netcrazybot
```

5. Проверьте логи:
```bash
sudo docker logs -f netcrazybot
```

### Управление ботом на сервере

**Просмотр логов:**
```bash
docker logs -f netcrazybot
docker logs --tail 100 netcrazybot  # Последние 100 строк
```

**Перезапуск бота:**
```bash
docker restart netcrazybot
```

**Остановка бота:**
```bash
docker stop netcrazybot
```

**Запуск бота:**
```bash
docker start netcrazybot
```

**Проверка статуса:**
```bash
docker ps | grep netcrazybot
docker inspect netcrazybot | grep -A 5 RestartPolicy
```

**Обновление бота:**
```bash
cd /opt/netcrazybot
git pull origin main
docker stop netcrazybot
docker rm netcrazybot
docker build -t netcrazybot .
docker run -d --name netcrazybot --restart unless-stopped \
  -v /opt/netcrazybot/output:/app/output \
  --env-file .env \
  netcrazybot
docker logs -f netcrazybot
```

### ⚠️ Автоматический перезапуск

Бот настроен с политикой `--restart unless-stopped`:
- ✅ **Автоматически перезапустится при сбое**
- ✅ **Автоматически запустится при перезагрузке сервера**
- ✅ **НЕ запустится, если остановлен вручную через `docker stop`**

Это означает, что после перезагрузки сервера бот автоматически поднимется!

### Автоматический деплой через GitLab CI/CD

Настройте переменные в GitLab (Settings → CI/CD → Variables):

1. **SSH_PRIVATE_KEY** (Type: File) - SSH ключ для доступа к серверу
2. **SERVER_IP** - IP адрес сервера
3. **SSH_PORT** (опционально) - SSH порт (по умолчанию 22)
4. **TELEGRAM_BOT_TOKEN** (Masked) - Токен бота

После настройки каждый push в `main` будет автоматически деплоить бота на сервер!

## Устранение неполадок

### Ошибка 409 Conflict

**Проблема:** `terminated by other getUpdates request; make sure that only one bot instance is running`

**Причина:** Бот запущен в нескольких местах одновременно с одним токеном.

**Решение:**
1. Найдите все запущенные экземпляры:
```bash
# На сервере
docker ps -a | grep netcrazybot

# На локальном компьютере
docker ps -a | grep netcrazybot
ps aux | grep "node src/index.js"
```

2. Остановите ВСЕ экземпляры кроме одного:
```bash
# Остановить Docker контейнер
docker stop netcrazybot
docker rm netcrazybot

# Остановить Node.js процесс
sudo kill <PID>
```

3. Запустите бот только в ОДНОМ месте (рекомендуется на сервере)

### Бот не отвечает

1. Проверьте, что токен правильно указан в `.env`
2. Проверьте логи: `docker logs -f netcrazybot`
3. Убедитесь, что контейнер запущен: `docker ps | grep netcrazybot`
4. Проверьте, что нет конфликта (ошибка 409)

### Не удается разрешить домен

1. Проверьте правильность написания домена
2. Убедитесь, что домен существует и доступен
3. Проверьте интернет-соединение сервера
4. Бот использует 10 DNS серверов, если ни один не ответил - домен недоступен

### Переполнение диска

Бот автоматически очищает файлы старше 24 часов каждые 6 часов.

Если нужно очистить вручную:
```bash
# Удалить все файлы в output
rm -rf /opt/netcrazybot/output/*

# Или удалить файлы старше 1 дня
find /opt/netcrazybot/output -type f -mtime +1 -delete
```

### Проверка работы автоочистки

Логи покажут сообщения об очистке:
```bash
docker logs netcrazybot | grep "Cleanup"
```

## Разработка

### Локальная разработка

1. Клонируйте репозиторий:
```bash
git clone https://gitlab.com/kosmostar777/netcrazybot.git
cd netcrazybot
```

2. Установите зависимости:
```bash
npm install
```

3. Создайте `.env`:
```bash
echo "TELEGRAM_BOT_TOKEN=your_bot_token_here" > .env
```

4. Запустите в режиме разработки:
```bash
npm run dev
```

**⚠️ Важно:** Перед запуском локально остановите бота на сервере, чтобы избежать конфликта!

### Добавление новых функций

1. Создайте новую ветку: `git checkout -b feature/new-feature`
2. Внесите изменения
3. Протестируйте локально
4. Закоммитьте: `git commit -am 'Add new feature'`
5. Запушьте: `git push origin feature/new-feature`
6. Создайте Merge Request

### Структура кода

- `src/bot.js` - обработка сообщений Telegram, валидация доменов
- `src/dnsResolver.js` - разрешение DNS через 10 серверов
- `src/fileGenerator.js` - генерация .bat файлов в формате Keenetic
- `src/antiflood.js` - защита от флуда (5 запросов/минуту)
- `src/fileCleanup.js` - автоматическая очистка старых файлов
- `src/config.js` - конфигурация приложения
- `src/index.js` - точка входа

## Лицензия

MIT

## Автор

NetCrazyBot Team

## Поддержка

Если у вас возникли вопросы или проблемы, создайте Issue в репозитории.

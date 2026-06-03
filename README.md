# NetCrazyBot

Telegram бот для управления AmneziaWG серверами.

## 📦 Установка


```bash
bash <(curl -fsSL https://raw.githubusercontent.com/4539617/netcrazebot/main/install.sh)
```

Во время установки вам нужно будет ввести:
- `TELEGRAM_BOT_TOKEN` - получите у [@BotFather](https://t.me/BotFather)
- `ADMIN_IDS` - ваш Telegram User ID (узнайте у [@userinfobot](https://t.me/userinfobot))

## 🔄 Переустановка

Скрипт автоматически удаляет старую версию и устанавливает новую:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/4539617/netcrazebot/main/install.sh)
```

## 🔧 Управление ботом

### Просмотр логов
```bash
docker logs -f netcrazybot
```

### Перезапуск бота
```bash
docker restart netcrazybot
```

### Остановка бота
```bash
docker stop netcrazybot
```

### Остановка всех контейнеров в docker-compose.yml
```bash
docker compose down
```

### Запуск бота
```bash
docker start netcrazybot
```

### Запуск всех контейнеров из docker-compose.yml
```bash
docker compose up -d --build
```

### Пересборка и перезапуск
```bash
cd /opt/netcrazybot
docker compose up -d --build
```

### Проверка статуса
```bash
docker ps --filter name=netcrazybot
```

## 🔐 Конфигурация

Все настройки хранятся в файле `/opt/netcrazybot/.env`:

```env
TELEGRAM_BOT_TOKEN=ваш_токен_от_BotFather
ADMIN_IDS=ваш_telegram_user_id
OUTPUT_DIR=/opt/netcrazybot/output
LOG_LEVEL=info
```


## 📝 Лицензия

MIT License

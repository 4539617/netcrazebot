# NetCrazyBot

Telegram бот для управления AmneziaWG серверами.

## 📦 Установка

**Важно:** Скрипт требует интерактивного ввода данных!

```bash
wget https://raw.githubusercontent.com/4539617/netcrazebot/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

Во время установки вам нужно будет ввести:
- `TELEGRAM_BOT_TOKEN` - получите у [@BotFather](https://t.me/BotFather)
- `ADMIN_IDS` - ваш Telegram User ID (узнайте у [@userinfobot](https://t.me/userinfobot))

## 🔄 Переустановка

Скрипт автоматически удаляет старую версию (включая AWG серверы) и устанавливает новую:

```bash
wget https://raw.githubusercontent.com/4539617/netcrazebot/main/install.sh
chmod +x install.sh
sudo ./install.sh
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

### Запуск бота
```bash
docker start netcrazybot
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

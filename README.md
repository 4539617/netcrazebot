# NetCrazyBot

Telegram бот для управления серверами.

## Установка

```bash

```bash
curl -fsSL https://raw.githubusercontent.com/4539617/netcrazebot/main/install.sh | sudo bash
```

### Или скачать и запустить

```bash
wget https://raw.githubusercontent.com/4539617/netcrazebot/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 🔄 Обновление бота

Для обновления бота до последней версии запустите тот же скрипт установки:

```bash
curl -fsSL https://raw.githubusercontent.com/4539617/netcrazebot/main/install.sh | sudo bash
```

Выберите вариант **1** - обновление сохранит все настройки и данные.

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

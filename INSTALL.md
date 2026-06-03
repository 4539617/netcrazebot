# 🚀 Инструкция по установке NetCrazyBot

## 📋 Требования

- Ubuntu 20.04 / 22.04 или Debian 11/12
- Минимум 1GB RAM
- Минимум 10GB свободного места на диске
- Root доступ к серверу
- Telegram Bot Token (получить у [@BotFather](https://t.me/BotFather))
- Ваш Telegram User ID (получить у [@userinfobot](https://t.me/userinfobot))

---

## 🎯 Быстрая установка

### Вариант 1: Автоматическая установка (рекомендуется)

```bash
# 1. Скачайте скрипт установки
wget https://raw.githubusercontent.com/your-repo/netcrazybot/main/install.sh

# 2. Сделайте скрипт исполняемым
chmod +x install.sh

# 3. Запустите установку
sudo ./install.sh
```

Скрипт запросит:
- **Telegram Bot Token** - токен вашего бота
- **Admin ID** - ваш Telegram User ID
- **Server IP** - IP адрес сервера

### Вариант 2: Ручная установка

#### Шаг 1: Обновление системы

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

#### Шаг 2: Установка зависимостей

```bash
sudo apt-get install -y \
    curl \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    wireguard-tools \
    net-tools
```

#### Шаг 3: Установка Docker

```bash
# Добавление GPG ключа Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Добавление репозитория Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Запуск Docker
sudo systemctl start docker
sudo systemctl enable docker
```

#### Шаг 4: Установка Node.js 20.x

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
```

#### Шаг 5: Клонирование репозитория

```bash
sudo mkdir -p /opt/netcrazybot
cd /opt/netcrazybot

# Если у вас есть Git репозиторий:
git clone https://github.com/your-repo/netcrazybot.git .

# Или скопируйте файлы вручную
```

#### Шаг 6: Создание .env файла

```bash
sudo nano /opt/netcrazybot/.env
```

Содержимое файла:
```env
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_bot_token_here

# Admin Configuration
ADMIN_IDS=your_telegram_user_id

# Server Configuration
SERVER_IP=your_server_ip

# Output Directory
OUTPUT_DIR=/opt/netcrazybot/output

# Log Level
LOG_LEVEL=info
```

#### Шаг 7: Создание директорий

```bash
sudo mkdir -p /opt/netcrazybot/output
sudo mkdir -p /opt/amnezia/amnezia-awg
sudo mkdir -p /opt/amnezia/amnezia-awg2
sudo chmod 755 /opt/amnezia
```

#### Шаг 8: Запуск бота

```bash
cd /opt/netcrazybot
sudo docker compose up -d --build
```

---

## 🔍 Проверка установки

### Проверка статуса бота

```bash
docker ps --filter name=netcrazybot
```

Вывод должен показать запущенный контейнер:
```
CONTAINER ID   IMAGE              COMMAND         STATUS         NAMES
abc123def456   netcrazybot:latest "node src/..."  Up 2 minutes   netcrazybot
```

### Просмотр логов

```bash
docker logs -f netcrazybot
```

Успешный запуск выглядит так:
```
[INFO] RouteBot initialized
[INFO] Bot started successfully!
[INFO] Admin IDs: 123456789
[INFO] Waiting for messages...
```

---

## 🎮 Использование бота

### Для обычных пользователей

1. Найдите бота в Telegram
2. Отправьте `/start`
3. Отправьте домен или список доменов для генерации .bat файла

### Для администраторов

1. Отправьте `/start` - увидите команду `/admin`
2. Отправьте `/admin` - откроется панель администратора
3. Доступные функции:
   - **🔧 Конфигурации** - генерация AWG конфигов
   - **⚙️ Установка** - установка AWG серверов
   - **📊 Статистика** - статистика серверов
   - **📋 Клиенты** - список клиентов

---

## 🔧 Управление ботом

### Основные команды

```bash
# Просмотр логов
docker logs -f netcrazybot

# Перезапуск бота
docker restart netcrazybot

# Остановка бота
docker stop netcrazybot

# Запуск бота
docker start netcrazybot

# Пересборка и перезапуск
cd /opt/netcrazybot
docker compose up -d --build

# Удаление бота
docker compose down
docker rmi netcrazybot:latest
```

### Обновление бота

```bash
cd /opt/netcrazybot

# Получить последние изменения
git pull

# Пересобрать и перезапустить
docker compose up -d --build
```

### Просмотр статуса всех контейнеров

```bash
# Бот
docker ps --filter name=netcrazybot

# AWG серверы
docker ps --filter name=amnezia
```

---

## 📦 Установка AWG серверов

После установки бота, установите AWG серверы через Telegram:

1. Откройте бота в Telegram
2. Отправьте `/admin`
3. Нажмите **⚙️ Установка**
4. Выберите версию (v1, v2 или оба)
5. Выберите порт (вручную или случайный)
6. Дождитесь завершения установки

### Проверка AWG серверов

```bash
# Проверка контейнеров
docker ps --filter name=amnezia

# Проверка конфигураций
ls -la /opt/amnezia/amnezia-awg/
ls -la /opt/amnezia/amnezia-awg2/

# Проверка портов
netstat -tuln | grep -E '(46666|31460)'
```

---

## 🐛 Решение проблем

### Бот не запускается

```bash
# Проверьте логи
docker logs netcrazybot

# Проверьте .env файл
cat /opt/netcrazybot/.env

# Проверьте права доступа
ls -la /opt/netcrazybot/
```

### Ошибка "wireguard-tools не установлен"

```bash
sudo apt-get install -y wireguard-tools
docker restart netcrazybot
```

### Ошибка доступа к Docker socket

```bash
# Проверьте монтирование
docker inspect netcrazybot | grep -A 5 Mounts

# Пересоздайте контейнер
cd /opt/netcrazybot
docker compose down
docker compose up -d
```

### Порт уже занят

```bash
# Проверьте занятые порты
netstat -tuln | grep LISTEN

# Найдите процесс
lsof -i :PORT_NUMBER

# Остановите конфликтующий сервис
sudo systemctl stop SERVICE_NAME
```

---

## 🔒 Безопасность

### Рекомендации

1. **Используйте firewall**
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow YOUR_AWG_PORT/udp
   sudo ufw enable
   ```

2. **Регулярно обновляйте систему**
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

3. **Используйте SSH ключи** вместо паролей

4. **Ограничьте доступ к боту** через ADMIN_IDS в .env

5. **Регулярно делайте бэкапы**
   ```bash
   # Бэкап конфигураций AWG
   tar -czf awg-backup-$(date +%Y%m%d).tar.gz /opt/amnezia/
   
   # Бэкап .env
   cp /opt/netcrazybot/.env /opt/netcrazybot/.env.backup
   ```

---

## 📊 Мониторинг

### Просмотр использования ресурсов

```bash
# Использование ресурсов контейнерами
docker stats

# Использование диска
df -h

# Использование памяти
free -h
```

### Логи

```bash
# Логи бота
docker logs -f netcrazybot

# Логи AWG v1
docker logs -f amnezia-awg

# Логи AWG v2
docker logs -f amnezia-awg2
```

---

## 📞 Поддержка

Если у вас возникли проблемы:

1. Проверьте логи: `docker logs netcrazybot`
2. Проверьте статус: `docker ps -a`
3. Проверьте конфигурацию: `cat /opt/netcrazybot/.env`
4. Создайте issue в GitHub репозитории

---

## 📝 Лицензия

MIT License

---

**Сделано с ❤️ by Bob**
#!/bin/bash

# NetCrazyBot Installation Script
# Автоматическая установка и настройка бота на VPS сервере

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    print_error "Пожалуйста, запустите скрипт с правами root (sudo)"
    exit 1
fi

print_message "🚀 Начинаем установку NetCrazyBot..."

# 1. Обновление системы
print_message "Обновление системы..."
apt update && apt upgrade -y

# 2. Установка Docker
print_message "Проверка установки Docker..."
if ! command -v docker &> /dev/null; then
    print_message "Установка Docker..."
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
    print_message "✅ Docker установлен"
else
    print_message "✅ Docker уже установлен"
fi

# 3. Установка Git
print_message "Проверка установки Git..."
if ! command -v git &> /dev/null; then
    print_message "Установка Git..."
    apt install -y git
    print_message "✅ Git установлен"
else
    print_message "✅ Git уже установлен"
fi

# 4. Создание директории для бота
INSTALL_DIR="/opt/netcrazybot"
print_message "Создание директории $INSTALL_DIR..."
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 5. Клонирование репозитория
print_message "Клонирование репозитория..."
if [ -d ".git" ]; then
    print_warning "Репозиторий уже существует, обновляем..."
    git pull origin main
else
    git clone https://gitlab.com/kosmostar777/netcrazybot.git .
fi

# 6. Запрос токена бота
print_message ""
print_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_message "Для работы бота необходим Telegram Bot Token"
print_message "Получите его у @BotFather в Telegram:"
print_message "1. Откройте @BotFather"
print_message "2. Отправьте /newbot"
print_message "3. Следуйте инструкциям"
print_message "4. Скопируйте полученный токен"
print_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_message ""

read -p "Введите Telegram Bot Token: " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    print_error "Токен не может быть пустым!"
    exit 1
fi

# 7. Создание .env файла
print_message "Создание .env файла..."
cat > .env << EOF
# Telegram Bot Token
# Get it from @BotFather on Telegram
TELEGRAM_BOT_TOKEN=$BOT_TOKEN
EOF

print_message "✅ .env файл создан"

# 8. Остановка старого контейнера (если есть)
print_message "Остановка старого контейнера (если есть)..."
docker stop netcrazybot 2>/dev/null || true
docker rm netcrazybot 2>/dev/null || true

# 9. Сборка Docker образа
print_message "Сборка Docker образа..."
docker build -t netcrazybot .

# 10. Запуск контейнера
print_message "Запуск контейнера..."
docker run -d --name netcrazybot --restart unless-stopped \
  -v $INSTALL_DIR/output:/app/output \
  --env-file .env \
  netcrazybot

# 11. Ожидание запуска
print_message "Ожидание запуска бота..."
sleep 5

# 12. Проверка статуса
print_message "Проверка статуса..."
if docker ps | grep -q netcrazybot; then
    print_message "✅ Бот успешно запущен!"
    print_message ""
    print_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "🎉 Установка завершена успешно!"
    print_message ""
    print_message "Полезные команды:"
    print_message "  Просмотр логов:    docker logs -f netcrazybot"
    print_message "  Перезапуск:        docker restart netcrazybot"
    print_message "  Остановка:         docker stop netcrazybot"
    print_message "  Запуск:            docker start netcrazybot"
    print_message "  Статус:            docker ps | grep netcrazybot"
    print_message ""
    print_message "Директория бота: $INSTALL_DIR"
    print_message "Файлы сохраняются в: $INSTALL_DIR/output"
    print_message ""
    print_message "Бот автоматически запустится при перезагрузке сервера!"
    print_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message ""
    print_message "Последние логи:"
    docker logs --tail 20 netcrazybot
else
    print_error "❌ Ошибка запуска бота!"
    print_error "Проверьте логи: docker logs netcrazybot"
    exit 1
fi

# Made with Bob

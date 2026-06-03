#!/bin/bash

# NetCrazyBot Installation Script
# Автоматическая установка бота на новый сервер

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    log_error "Пожалуйста, запустите скрипт с правами root (sudo)"
    exit 1
fi

log_info "Начало установки NetCrazyBot..."
echo ""

# 1. Обновление системы
log_info "Обновление системы..."
apt-get update -qq
apt-get upgrade -y -qq
log_success "Система обновлена"
echo ""

# 2. Установка необходимых пакетов
log_info "Установка необходимых пакетов..."
apt-get install -y -qq \
    curl \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    wireguard-tools \
    net-tools
log_success "Пакеты установлены"
echo ""

# 3. Установка Docker
if ! command -v docker &> /dev/null; then
    log_info "Установка Docker..."
    
    # Добавление официального GPG ключа Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Добавление репозитория Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Установка Docker
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Запуск Docker
    systemctl start docker
    systemctl enable docker
    
    log_success "Docker установлен и запущен"
else
    log_success "Docker уже установлен"
fi
echo ""

# 4. Установка Node.js 20.x
if ! command -v node &> /dev/null; then
    log_info "Установка Node.js 20.x..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y -qq nodejs
    log_success "Node.js $(node -v) установлен"
else
    log_success "Node.js $(node -v) уже установлен"
fi
echo ""

# 5. Клонирование репозитория (если не существует)
BOT_DIR="/opt/netcrazybot"
if [ ! -d "$BOT_DIR" ]; then
    log_info "Создание директории для бота..."
    mkdir -p "$BOT_DIR"
    log_success "Директория создана: $BOT_DIR"
else
    log_warning "Директория уже существует: $BOT_DIR"
fi
echo ""

# 6. Запрос конфигурации
log_info "Настройка конфигурации..."
echo ""

read -p "Введите Telegram Bot Token: " BOT_TOKEN
read -p "Введите Admin ID (Telegram User ID): " ADMIN_ID
read -p "Введите IP адрес сервера: " SERVER_IP

# 7. Создание .env файла
log_info "Создание .env файла..."
cat > "$BOT_DIR/.env" << EOF
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=$BOT_TOKEN

# Admin Configuration
ADMIN_IDS=$ADMIN_ID

# Server Configuration
SERVER_IP=$SERVER_IP

# Output Directory
OUTPUT_DIR=/opt/netcrazybot/output

# Log Level
LOG_LEVEL=info
EOF
log_success ".env файл создан"
echo ""

# 8. Создание docker-compose.yml
log_info "Создание docker-compose.yml..."
cat > "$BOT_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  bot:
    build: .
    container_name: netcrazybot
    restart: always
    env_file:
      - .env
    volumes:
      - ./output:/app/output
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/amnezia:/opt/amnezia
    network_mode: host
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF
log_success "docker-compose.yml создан"
echo ""

# 9. Копирование исходного кода (если запущено из директории проекта)
if [ -f "package.json" ]; then
    log_info "Копирование исходного кода..."
    cp -r . "$BOT_DIR/"
    log_success "Исходный код скопирован"
else
    log_warning "Исходный код не найден в текущей директории"
    log_info "Пожалуйста, скопируйте файлы проекта в $BOT_DIR"
fi
echo ""

# 10. Создание директории для вывода
log_info "Создание директории для файлов..."
mkdir -p "$BOT_DIR/output"
chmod 755 "$BOT_DIR/output"
log_success "Директория создана: $BOT_DIR/output"
echo ""

# 11. Создание директорий для AWG
log_info "Создание директорий для AWG..."
mkdir -p /opt/amnezia/amnezia-awg
mkdir -p /opt/amnezia/amnezia-awg2
chmod 755 /opt/amnezia
log_success "Директории AWG созданы"
echo ""

# 12. Сборка и запуск Docker контейнера
cd "$BOT_DIR"
if [ -f "Dockerfile" ]; then
    log_info "Сборка Docker образа..."
    docker compose build
    log_success "Docker образ собран"
    echo ""
    
    log_info "Запуск бота..."
    docker compose up -d
    log_success "Бот запущен"
else
    log_warning "Dockerfile не найден. Пропуск сборки."
fi
echo ""

# 13. Проверка статуса
log_info "Проверка статуса бота..."
sleep 3
if docker ps | grep -q netcrazybot; then
    log_success "Бот успешно запущен!"
    echo ""
    docker ps --filter name=netcrazybot --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    log_error "Бот не запущен. Проверьте логи: docker logs netcrazybot"
fi
echo ""

# 14. Вывод информации
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Установка завершена!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Директория бота: $BOT_DIR"
echo "🔧 Конфигурация: $BOT_DIR/.env"
echo "📋 Docker Compose: $BOT_DIR/docker-compose.yml"
echo ""
echo "🔍 Полезные команды:"
echo "  • Просмотр логов:     docker logs -f netcrazybot"
echo "  • Перезапуск бота:    docker restart netcrazybot"
echo "  • Остановка бота:     docker stop netcrazybot"
echo "  • Запуск бота:        docker start netcrazybot"
echo "  • Пересборка:         cd $BOT_DIR && docker compose up -d --build"
echo ""
echo "📊 Статус контейнеров:"
echo "  • Бот:                docker ps --filter name=netcrazybot"
echo "  • AWG серверы:        docker ps --filter name=amnezia"
echo ""
echo "⚙️ Установка AWG серверов:"
echo "  1. Откройте Telegram бота"
echo "  2. Отправьте команду /admin"
echo "  3. Выберите 'Установка'"
echo "  4. Следуйте инструкциям"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Made with Bob

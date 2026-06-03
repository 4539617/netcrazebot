#!/bin/bash

# NetCrazyBot - Installation Script
# Установка только бота и необходимых компонентов

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка root
if [ "$EUID" -ne 0 ]; then 
    log_error "Запустите скрипт с правами root: sudo $0"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "NetCrazyBot - Установка"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Обновление системы
log_info "Обновление системы..."
apt-get update -qq
apt-get upgrade -y -qq
log_success "Система обновлена"
echo ""

# 2. Установка базовых пакетов
log_info "Установка необходимых пакетов..."
apt-get install -y -qq curl git ca-certificates gnupg lsb-release
log_success "Пакеты установлены"
echo ""

# 3. Установка Docker
if ! command -v docker &> /dev/null; then
    log_info "Установка Docker..."
    
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl start docker
    systemctl enable docker
    
    log_success "Docker установлен"
else
    log_success "Docker уже установлен"
fi
echo ""

# 4. Клонирование или обновление репозитория
BOT_DIR="/opt/netcrazybot"

if [ -d "$BOT_DIR" ]; then
    log_warning "Директория $BOT_DIR уже существует - выполняю обновление"
    log_info "Обновление бота..."
    
    # Сохраняем .env файл
    if [ -f "$BOT_DIR/.env" ]; then
        log_info "Сохранение конфигурации..."
        cp "$BOT_DIR/.env" "/tmp/netcrazybot.env.backup"
        log_success "Конфигурация сохранена"
    fi
    
    # Переходим в директорию и обновляем код
    cd "$BOT_DIR"
    
    # Проверяем, является ли директория git репозиторием
    if [ -d ".git" ]; then
        log_info "Скачивание обновлений из GitHub..."
        git fetch origin
        git reset --hard origin/main
        log_success "Код обновлён"
    else
        log_warning "Директория не является git репозиторием, клонирую заново..."
        cd /opt
        rm -rf "$BOT_DIR"
        git clone https://github.com/4539617/netcrazebot.git "$BOT_DIR"
        cd "$BOT_DIR"
        log_success "Репозиторий склонирован"
    fi
    
    # Восстанавливаем .env файл
    if [ -f "/tmp/netcrazybot.env.backup" ]; then
        log_info "Восстановление конфигурации..."
        cp "/tmp/netcrazybot.env.backup" "$BOT_DIR/.env"
        rm "/tmp/netcrazybot.env.backup"
        log_success "Конфигурация восстановлена"
    fi
    
    # Пересобираем и перезапускаем контейнер
    log_info "Пересборка Docker образа..."
    docker compose build --no-cache
    log_success "Образ пересобран"
    echo ""
    
    log_info "Перезапуск бота..."
    docker compose down
    docker compose up -d
    log_success "Бот перезапущен"
    echo ""
    
    # Проверка статуса
    log_info "Проверка статуса..."
    sleep 5
    
    if docker ps | grep -q netcrazybot; then
        log_success "Бот успешно обновлён и запущен!"
        echo ""
        docker ps --filter name=netcrazybot --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_error "Бот не запустился. Проверьте логи:"
        echo ""
        docker logs netcrazybot
        exit 1
    fi
    echo ""
    
    # Финальная информация
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Обновление завершено!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📁 Директория: $BOT_DIR"
    echo "🔧 Конфигурация: $BOT_DIR/.env"
    echo ""
    echo "🔍 Полезные команды:"
    echo "  docker logs -f netcrazybot          # Просмотр логов"
    echo "  docker restart netcrazybot          # Перезапуск"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
fi

log_info "Клонирование репозитория..."
git clone https://github.com/4539617/netcrazebot.git "$BOT_DIR"
cd "$BOT_DIR"
log_success "Репозиторий склонирован: $BOT_DIR"
echo ""

# 5. Настройка конфигурации
log_info "Настройка конфигурации..."
echo ""

echo "Получите Bot Token у @BotFather в Telegram"
read -p "Введите TELEGRAM_BOT_TOKEN: " BOT_TOKEN
echo ""

echo "Узнайте свой User ID у @userinfobot в Telegram"
read -p "Введите ADMIN_IDS (через запятую): " ADMIN_IDS
echo ""

# Создание .env файла
log_info "Создание .env файла..."
cat > "$BOT_DIR/.env" << EOF
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=$BOT_TOKEN

# Admin Configuration
ADMIN_IDS=$ADMIN_IDS

# Output Directory
OUTPUT_DIR=/opt/netcrazybot/output

# Log Level
LOG_LEVEL=info
EOF
log_success ".env файл создан"
echo ""

# 6. Создание директории для вывода
log_info "Создание директории для файлов..."
mkdir -p "$BOT_DIR/output"
chmod 755 "$BOT_DIR/output"
log_success "Директория создана: $BOT_DIR/output"
echo ""

# 7. Сборка и запуск
log_info "Сборка Docker образа..."
docker compose build --no-cache
log_success "Образ собран"
echo ""

log_info "Запуск бота..."
docker compose up -d
log_success "Бот запущен"
echo ""

# 8. Проверка статуса
log_info "Проверка статуса..."
sleep 5

if docker ps | grep -q netcrazybot; then
    log_success "Бот успешно запущен!"
    echo ""
    docker ps --filter name=netcrazybot --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    log_error "Бот не запустился. Проверьте логи:"
    echo ""
    docker logs netcrazybot
    exit 1
fi
echo ""

# 9. Финальная информация
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Установка завершена!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Директория: $BOT_DIR"
echo "🔧 Конфигурация: $BOT_DIR/.env"
echo ""
echo "🔍 Полезные команды:"
echo "  docker logs -f netcrazybot          # Просмотр логов"
echo "  docker restart netcrazybot          # Перезапуск"
echo "  docker stop netcrazybot             # Остановка"
echo "  cd $BOT_DIR && docker compose up -d --build  # Пересборка"
echo ""
echo "📱 Telegram:"
echo "  1. Откройте бота"
echo "  2. Отправьте /start"
echo "  3. Отправьте /admin для доступа к функциям администратора"
echo "  4. Выберите 'Установка' для установки AWG серверов"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Made with Bob

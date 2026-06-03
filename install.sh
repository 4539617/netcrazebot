#!/bin/bash

# NetCrazyBot - Installation Script
# Меню управления ботом

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

BOT_DIR="/opt/netcrazybot"

# Функция установки бота
install_bot() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Установка NetCrazyBot"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Переходим в безопасную директорию
    cd /tmp
    
    # 1. Обновление системы
    log_info "Обновление системы..."
    apt-get update -qq
    apt-get upgrade -y -qq
    log_success "Система обновлена"
    echo ""
    
    # 2. Установка базовых пакетов
    log_info "Установка необходимых пакетов..."
    apt-get install -y -qq curl git ca-certificates gnupg lsb-release wireguard-tools
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
    
    # 4. Проверка существующей установки
    if [ -d "$BOT_DIR" ]; then
        log_warning "⚠️  Обнаружена старая установка в $BOT_DIR"
        echo ""
        read -p "Удалить и установить заново? (y/n): " CONFIRM </dev/tty
        echo ""
        
        if [ "$CONFIRM" != "y" ]; then
            log_info "Установка отменена"
            return
        fi
        
        log_info "Удаление старой установки..."
        docker stop netcrazybot 2>/dev/null || true
        docker rm netcrazybot 2>/dev/null || true
        docker rmi netcrazybot-netcrazybot 2>/dev/null || true
        cd /opt
        rm -rf "$BOT_DIR"
        log_success "Старая установка удалена"
        echo ""
    fi
    
    # 5. Клонирование репозитория
    cd /opt
    log_info "Клонирование репозитория..."
    git clone https://github.com/4539617/netcrazebot.git netcrazybot
    cd "$BOT_DIR"
    log_success "Репозиторий склонирован: $BOT_DIR"
    echo ""
    
    # 6. Загрузка Docker образов AWG
    if [ -f "$BOT_DIR/type1.json" ] && [ -f "$BOT_DIR/type2.json" ]; then
        log_info "Загрузка Docker образов AWG..."
        docker load -i "$BOT_DIR/type1.json"
        docker load -i "$BOT_DIR/type2.json"
        log_success "Docker образы AWG загружены"
        echo ""
    else
        log_warning "Docker образы AWG не найдены в репозитории"
        log_warning "Будет использован публичный образ (может не работать)"
        echo ""
    fi
    
    # 7. Настройка конфигурации
    log_info "Настройка конфигурации..."
    echo ""
    
    echo "Получите Bot Token у @BotFather в Telegram"
    read -p "Введите TELEGRAM_BOT_TOKEN: " BOT_TOKEN </dev/tty
    echo ""
    
    echo "Узнайте свой User ID у @userinfobot в Telegram"
    read -p "Введите ADMIN_IDS (через запятую): " ADMIN_IDS </dev/tty
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
    
    # 8. Создание директории для вывода
    log_info "Создание директории для файлов..."
    mkdir -p "$BOT_DIR/output"
    chmod 755 "$BOT_DIR/output"
    log_success "Директория создана: $BOT_DIR/output"
    echo ""
    
    # 9. Сборка и запуск
    log_info "Сборка Docker образа..."
    docker compose build --no-cache
    log_success "Образ собран"
    echo ""
    
    log_info "Запуск бота..."
    docker compose up -d
    log_success "Бот запущен"
    echo ""
    
    # 10. Проверка статуса
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
        return 1
    fi
    echo ""
    
    # 11. Финальная информация
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Установка завершена!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📁 Директория: $BOT_DIR"
    echo "🔧 Конфигурация: $BOT_DIR/.env"
    echo ""
    echo "📱 Telegram:"
    echo "  1. Откройте бота"
    echo "  2. Отправьте /start"
    echo "  3. Отправьте /admin для доступа к функциям администратора"
    echo ""
}

# Функция обновления бота
update_bot() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Обновление NetCrazyBot"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ ! -d "$BOT_DIR" ]; then
        log_error "Бот не установлен. Сначала выполните установку."
        return 1
    fi
    
    cd "$BOT_DIR"
    
    log_info "Остановка бота..."
    docker compose down
    log_success "Бот остановлен"
    echo ""
    
    log_info "Обновление из репозитория..."
    git pull origin main
    log_success "Код обновлён"
    echo ""
    
    # Загрузка Docker образов AWG если они есть
    if [ -f "$BOT_DIR/type1.json" ] && [ -f "$BOT_DIR/type2.json" ]; then
        log_info "Обновление Docker образов AWG..."
        docker load -i "$BOT_DIR/type1.json"
        docker load -i "$BOT_DIR/type2.json"
        log_success "Docker образы AWG обновлены"
        echo ""
    fi
    
    log_info "Пересборка и запуск..."
    docker compose up -d --build
    log_success "Бот обновлён и запущен"
    echo ""
    
    log_info "Просмотр логов (Ctrl+C для выхода)..."
    sleep 2
    docker logs -f netcrazybot
}

# Функция удаления бота
remove_bot() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_warning "Удаление NetCrazyBot"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_warning "⚠️  ВНИМАНИЕ: Это удалит бота и все его данные!"
    echo ""
    read -p "Вы уверены? (yes/no): " CONFIRM </dev/tty
    echo ""
    
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Удаление отменено"
        return
    fi
    
    log_info "Остановка и удаление контейнера..."
    docker stop netcrazybot 2>/dev/null || true
    docker rm netcrazybot 2>/dev/null || true
    docker rmi netcrazybot-netcrazybot 2>/dev/null || true
    log_success "Контейнер удалён"
    echo ""
    
    if [ -d "$BOT_DIR" ]; then
        log_info "Удаление файлов бота..."
        cd /opt
        rm -rf "$BOT_DIR"
        log_success "Файлы удалены"
    fi
    echo ""
    
    log_success "✅ Бот полностью удалён"
}

# Функция удаления AWG
remove_awg() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_warning "Удаление AWG (amnezia-awg)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_warning "⚠️  ВНИМАНИЕ: Это удалит AWG v1 и все его конфигурации!"
    echo ""
    read -p "Вы уверены? (yes/no): " CONFIRM </dev/tty
    echo ""
    
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Удаление отменено"
        return
    fi
    
    log_info "Остановка и удаление контейнера amnezia-awg..."
    docker stop amnezia-awg 2>/dev/null || true
    docker rm amnezia-awg 2>/dev/null || true
    log_success "Контейнер удалён"
    echo ""
    
    if [ -d "/opt/amnezia/amnezia-awg" ]; then
        log_info "Удаление конфигурации..."
        rm -rf /opt/amnezia/amnezia-awg
        log_success "Конфигурация удалена"
    fi
    echo ""
    
    log_success "✅ AWG v1 полностью удалён"
}

# Функция удаления AWG2
remove_awg2() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_warning "Удаление AWG2 (amnezia-awg2)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_warning "⚠️  ВНИМАНИЕ: Это удалит AWG v2 и все его конфигурации!"
    echo ""
    read -p "Вы уверены? (yes/no): " CONFIRM </dev/tty
    echo ""
    
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Удаление отменено"
        return
    fi
    
    log_info "Остановка и удаление контейнера amnezia-awg2..."
    docker stop amnezia-awg2 2>/dev/null || true
    docker rm amnezia-awg2 2>/dev/null || true
    log_success "Контейнер удалён"
    echo ""
    
    if [ -d "/opt/amnezia/amnezia-awg2" ]; then
        log_info "Удаление конфигурации..."
        rm -rf /opt/amnezia/amnezia-awg2
        log_success "Конфигурация удалена"
    fi
    echo ""
    
    log_success "✅ AWG v2 полностью удалён"
}

# Функция просмотра логов
show_logs() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Логи бота (Ctrl+C для выхода)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if ! docker ps | grep -q netcrazybot; then
        log_error "Бот не запущен"
        return
    fi
    
    docker logs -f netcrazybot
}

# Функция полного удаления
remove_all() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_warning "Полное удаление (AWG + Бот)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_warning "⚠️  ВНИМАНИЕ: Это удалит:"
    echo "  • Бот и все его данные"
    echo "  • AWG v1 и все конфигурации"
    echo "  • AWG v2 и все конфигурации"
    echo ""
    read -p "Вы уверены? (yes/no): " CONFIRM </dev/tty
    echo ""
    
    if [ "$CONFIRM" != "yes" ]; then
        log_info "Удаление отменено"
        return
    fi
    
    # Удаление AWG v1
    log_info "Удаление AWG v1..."
    docker stop amnezia-awg 2>/dev/null || true
    docker rm amnezia-awg 2>/dev/null || true
    rm -rf /opt/amnezia/amnezia-awg 2>/dev/null || true
    log_success "AWG v1 удалён"
    echo ""
    
    # Удаление AWG v2
    log_info "Удаление AWG v2..."
    docker stop amnezia-awg2 2>/dev/null || true
    docker rm amnezia-awg2 2>/dev/null || true
    rm -rf /opt/amnezia/amnezia-awg2 2>/dev/null || true
    log_success "AWG v2 удалён"
    echo ""
    
    # Удаление бота
    log_info "Удаление бота..."
    docker stop netcrazybot 2>/dev/null || true
    docker rm netcrazybot 2>/dev/null || true
    docker rmi netcrazybot-netcrazybot 2>/dev/null || true
    cd /opt
    rm -rf "$BOT_DIR" 2>/dev/null || true
    log_success "Бот удалён"
    echo ""
    
    log_success "✅ Всё удалено полностью"
}

# Главное меню
show_menu() {
    clear
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}           NetCrazyBot - Меню управления${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  1) Установка бота"
    echo "  2) Обновление бота"
    echo "  3) Удаление бота"
    echo "  4) Удаление AWG v1"
    echo "  5) Удаление AWG v2"
    echo "  6) Логи бота"
    echo "  7) Удалить всё (AWG + Бот)"
    echo "  0) Выход"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Основной цикл
while true; do
    show_menu
    read -p "Выберите действие (0-7): " choice </dev/tty
    
    case $choice in
        1)
            install_bot
            echo ""
            read -p "Нажмите Enter для продолжения..." </dev/tty
            ;;
        2)
            update_bot
            ;;
        3)
            remove_bot
            echo ""
            read -p "Нажмите Enter для продолжения..." </dev/tty
            ;;
        4)
            remove_awg
            echo ""
            read -p "Нажмите Enter для продолжения..." </dev/tty
            ;;
        5)
            remove_awg2
            echo ""
            read -p "Нажмите Enter для продолжения..." </dev/tty
            ;;
        6)
            show_logs
            ;;
        7)
            remove_all
            echo ""
            read -p "Нажмите Enter для продолжения..." </dev/tty
            ;;
        0)
            echo ""
            log_info "Выход..."
            echo ""
            exit 0
            ;;
        *)
            log_error "Неверный выбор. Попробуйте снова."
            sleep 2
            ;;
    esac
done

# Made with Bob

#!/bin/bash

# NetCrazyBot Uninstall Script
# Скрипт для полного удаления бота с VPS сервера

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

INSTALL_DIR="/opt/netcrazybot"

print_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_warning "⚠️  ВНИМАНИЕ! Это удалит NetCrazyBot с сервера!"
print_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_warning ""
print_warning "Будет удалено:"
print_warning "  - Docker контейнер netcrazybot"
print_warning "  - Docker образ netcrazybot"
print_warning "  - Директория $INSTALL_DIR"
print_warning "  - Все сгенерированные файлы"
print_warning ""

read -p "Вы уверены? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_message "Удаление отменено"
    exit 0
fi

print_message "🗑️  Начинаем удаление NetCrazyBot..."

# 1. Остановка и удаление контейнера
print_message "Остановка и удаление контейнера..."
docker stop netcrazybot 2>/dev/null || true
docker rm netcrazybot 2>/dev/null || true
print_message "✅ Контейнер удален"

# 2. Удаление образа
print_message "Удаление Docker образа..."
docker rmi netcrazybot 2>/dev/null || true
print_message "✅ Образ удален"

# 3. Удаление директории
if [ -d "$INSTALL_DIR" ]; then
    print_message "Удаление директории $INSTALL_DIR..."
    rm -rf $INSTALL_DIR
    print_message "✅ Директория удалена"
else
    print_warning "Директория $INSTALL_DIR не найдена"
fi

print_message ""
print_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_message "✅ NetCrazyBot успешно удален с сервера!"
print_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Made with Bob

#!/bin/bash

# NetCrazyBot Update Script
# Скрипт для обновления бота на VPS сервере

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

# Проверка существования директории
if [ ! -d "$INSTALL_DIR" ]; then
    print_error "Директория $INSTALL_DIR не найдена!"
    print_error "Сначала установите бота с помощью install.sh"
    exit 1
fi

cd $INSTALL_DIR

print_message "🔄 Начинаем обновление NetCrazyBot..."

# 1. Сохранение .env файла
print_message "Сохранение конфигурации..."
if [ -f ".env" ]; then
    cp .env .env.backup
    print_message "✅ Конфигурация сохранена"
else
    print_warning ".env файл не найден"
fi

# 2. Обновление кода из Git
print_message "Получение обновлений из Git..."
git fetch origin
git reset --hard origin/main
print_message "✅ Код обновлен"

# 3. Восстановление .env файла
if [ -f ".env.backup" ]; then
    mv .env.backup .env
    print_message "✅ Конфигурация восстановлена"
fi

# 4. Остановка старого контейнера
print_message "Остановка старого контейнера..."
docker stop netcrazybot 2>/dev/null || true
docker rm netcrazybot 2>/dev/null || true
print_message "✅ Старый контейнер остановлен"

# 5. Удаление старого образа
print_message "Удаление старого образа..."
docker rmi netcrazybot 2>/dev/null || true

# 6. Сборка нового образа
print_message "Сборка нового образа..."
docker build -t netcrazybot .
print_message "✅ Образ собран"

# 7. Запуск нового контейнера
print_message "Запуск нового контейнера..."
docker run -d --name netcrazybot --restart unless-stopped \
  -v $INSTALL_DIR/output:/app/output \
  --env-file .env \
  netcrazybot

# 8. Ожидание запуска
print_message "Ожидание запуска бота..."
sleep 5

# 9. Проверка статуса
print_message "Проверка статуса..."
if docker ps | grep -q netcrazybot; then
    print_message "✅ Бот успешно обновлен и запущен!"
    print_message ""
    print_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_message "🎉 Обновление завершено успешно!"
    print_message ""
    print_message "Последние логи:"
    docker logs --tail 20 netcrazybot
    print_message "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    print_error "❌ Ошибка запуска бота после обновления!"
    print_error "Проверьте логи: docker logs netcrazybot"
    exit 1
fi

# Made with Bob

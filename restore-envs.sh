#!/bin/bash

# Скрипт для восстановления .env файлов из бэкапа
# Использование: ./restore-envs.sh [путь_к_архиву]

DEFAULT_BACKUP="envs_backup_20260120_151812.tar.gz"
BACKUP_FILE="${1:-$DEFAULT_BACKUP}"

if [ -f "$BACKUP_FILE" ]; then
    echo "📦 Восстановление .env файлов из $BACKUP_FILE..."
    tar -xzvf "$BACKUP_FILE"
    echo "✅ Файлы успешно восстановлены."
else
    echo "❌ Ошибка: Файл бэкапа $BACKUP_FILE не найден!"
    echo "Использование: $0 [путь_к_архиву]"
    exit 1
fi
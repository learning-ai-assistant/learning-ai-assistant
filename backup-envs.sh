#!/bin/bash

# Скрипт для создания резервной копии всех .env файлов в проекте

BACKUP_NAME="envs_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

echo "📦 Поиск и архивация .env файлов..."

# Находим все .env файлы, исключая node_modules и скрытые папки git
find . -name ".env" -not -path "*/node_modules/*" -not -path "*/.git/*" > env_files_list.txt

if [ -s env_files_list.txt ]; then
    tar -cvzf "$BACKUP_NAME" -T env_files_list.txt
    echo "✅ Бэкап создан: $BACKUP_NAME"
    rm env_files_list.txt
else
    echo "⚠️ .env файлы не найдены."
    rm env_files_list.txt
fi
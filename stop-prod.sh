#!/bin/bash

# Скрипт для остановки сервисов с группировкой по проектам в Docker (PROD)

echo "🛑 Stopping Life Learning Assistant (PROD)..."

# Функция для остановки группы
stop_group() {
    local folder=$1
    local project_name=$2
    echo "📂 Stopping group: $project_name..."
    (cd "$folder" && docker compose -f docker-compose-prod.yml -p "$project_name" down --remove-orphans)
}

# Останавливаем в обратном порядке
stop_group "services/agent_service" "lifelong_learning-agent"
stop_group "services/web_ui_service" "lifelong_learning-web_ui"
stop_group "services/test_generator" "lifelong_learning-test_generator"
stop_group "services/rag" "lifelong_learning-rag"
stop_group "services/user_service" "lifelong_learning-user_service"

echo "✅ All groups stopped!"

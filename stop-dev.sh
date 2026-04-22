#!/bin/bash

# Скрипт для остановки сервисов с группировкой по проектам в Docker

echo "🛑 Stopping Life Learning Assistant (DEV)..."

# Функция для остановки группы
stop_group() {
    local folder=$1
    local project_name=$2
    echo "📂 Stopping group: $project_name..."
    (cd "$folder" && docker compose -f docker-compose-dev.yml -p "$project_name" down)
}

# Останавливаем в обратном порядке
echo "📂 Stopping Algo Sandbox..."
docker compose -f docker-compose-dev.yml stop algo-sandbox-dev 2>/dev/null || true

stop_group "services/agent_service" "lifelong_learning-agent"
stop_group "services/web_ui_service" "lifelong_learning-web_ui"
stop_group "services/test_generator" "lifelong_learning-test_generator"
stop_group "services/rag" "lifelong_learning-rag"
stop_group "services/user_service" "lifelong_learning-user_service"

echo "✅ All groups stopped!"

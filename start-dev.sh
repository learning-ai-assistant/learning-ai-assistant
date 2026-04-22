#!/bin/bash

# Скрипт для последовательного запуска сервисов с группировкой по проектам в Docker

echo "🚀 Starting Life Learning Assistant (DEV)..."

# Экспортируем токен для WebSocket
export WS_TOKEN=dev_token_123

# Создаем внешние сети, если они не существуют
docker network create rag_rag_network >/dev/null 2>&1
docker network create test_generator_default >/dev/null 2>&1
docker network create web_ui_network >/dev/null 2>&1
docker network create user_service_network >/dev/null 2>&1

# Функция для запуска группы
start_group() {
    local folder=$1
    local project_name=$2
    echo "📂 Starting group: $project_name (folder: $folder)..."
    (cd "$folder" && docker compose -f docker-compose-dev.yml -p "$project_name" up -d --build)
}

# 0. User Service Group
start_group "services/user_service" "lifelong_learning-user_service"
echo "🔧 Initializing User Database (Migrations + Test User)..."

# Ждем готовности базы данных перед миграциями
docker exec user-service-dev uv run alembic upgrade head

# Регистрация пользователя (идемпотентно)
docker exec user-service-dev uv run python scripts/register_user.py test_user test_password || echo "ℹ️ Test user already exists or initialization skipped."

# 1. RAG Group (База знаний)
start_group "services/rag" "lifelong_learning-rag"

# 2. Test Generator Group
start_group "services/test_generator" "lifelong_learning-test_generator"

# 3. Web UI Group (Backend + Frontend)
start_group "services/web_ui_service" "lifelong_learning-web_ui"

# 4. Agent Service (Оркестратор - запускаем последним)
start_group "services/agent_service" "lifelong_learning-agent"

# 5. Algo Sandbox (Песочница для кода)
echo "📂 Starting Algo Sandbox..."
docker compose -f docker-compose-dev.yml up -d --build algo-sandbox

echo "✅ All groups started!"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

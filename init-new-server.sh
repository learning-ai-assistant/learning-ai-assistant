#!/bin/bash

# Скрипт для первичной инициализации системы на новом сервере
# Требования: docker, docker compose, curl
# Использование: ./init-new-server.sh [prod|dev] (default: prod)

set -e # Прерывать выполнение при ошибках

ENV=${1:-prod}
if [ "$ENV" != "prod" ] && [ "$ENV" != "dev" ]; then
    echo "❌ Ошибка: Неверное окружение. Используйте 'prod' или 'dev'."
    exit 1
fi

echo "🌟 Инициализация Life Learning Assistant на новом сервере (Окружение: $ENV)..."

# Определение переменных в зависимости от окружения
if [ "$ENV" == "dev" ]; then
    COMPOSE_FILE="docker-compose-dev.yml"
    PROJECT_NAME="lifelong_learning-rag" # Имя проекта из start-dev.sh
    USER_PROJECT_NAME="lifelong_learning-user_service"
    REDIS_CONTAINER="redis-dev"
    USER_SERVICE_CONTAINER="user-service-dev"
else
    COMPOSE_FILE="docker-compose-prod.yml"
    PROJECT_NAME="lifelong_learning-rag"
    USER_PROJECT_NAME="lifelong_learning-user_service"
    REDIS_CONTAINER="redis-prod"
    USER_SERVICE_CONTAINER="user-service-prod"
fi

# Root-level orchestration keeps services in nested repos under ./services.
RAG_DIR="services/rag"
USER_SERVICE_DIR="services/user_service"

# 0. Проверка конфигурации и сети
echo "🔍 Проверка доступности LLM API..."
if [ -f "$RAG_DIR/.env" ]; then
    API_BASE=$(grep OPENAI_API_BASE "$RAG_DIR/.env" | cut -d'=' -f2)
    API_KEY=$(grep OPENAI_API_KEY "$RAG_DIR/.env" | cut -d'=' -f2)
    
    if [ ! -z "$API_BASE" ] && [ ! -z "$API_KEY" ]; then
        echo "📡 Тестирование соединения с $API_BASE..."
        if curl -s -o /dev/null -m 10 "$API_BASE"; then
            echo "✅ LLM API доступен."
        else
            echo "⚠️  WARNING: Не удалось подключиться к LLM API ($API_BASE). Возможны проблемы при запуске RAG API."
        fi
    fi
else
    echo "⚠️  WARNING: Файл $RAG_DIR/.env не найден. Проверка API пропущена."
fi

# 0.1 Подготовка Docker сетей и томов
echo "🌐 Создание Docker Networks..."
docker network create rag_rag_network >/dev/null 2>&1 || echo "Network rag_rag_network уже существует"
docker network create test_generator_default >/dev/null 2>&1 || echo "Network test_generator_default уже существует"
docker network create web_ui_network >/dev/null 2>&1 || echo "Network web_ui_network уже существует"
docker network create user_service_network >/dev/null 2>&1 || echo "Network user_service_network уже существует"

echo "📦 Создание Docker Volumes..."
docker volume create rag_qdrant_storage >/dev/null 2>&1 || echo "Volume rag_qdrant_storage уже существует"
docker volume create rag_redis_data >/dev/null 2>&1 || echo "Volume rag_redis_data уже существует"
docker volume create user_postgres_data >/dev/null 2>&1 || echo "Volume user_postgres_data уже существует"

# 1. Pull Docker images
echo "⬇️ Pull Docker образов..."
# RAG images
docker pull qdrant/qdrant:v1.12.4
docker pull redis:7.4.2-alpine
docker pull rediscommander/redis-commander:latest
docker pull medphisiker/rag-backup-downloader:v001
# User Service images
docker pull postgres:15.15-alpine
# Примечание: rag-api, user-service собираются из исходников в DEV режиме, или пулятся в PROD.
# Предполагаем подготовку к DEV/PROD гибридному режиму или просто настройку данных.

# 2. Start RAG Infrastructure (Qdrant, Redis)
echo "🚀 Запуск инфраструктуры RAG (Qdrant, Redis)..."
(cd "$RAG_DIR" && docker compose -f $COMPOSE_FILE -p "$PROJECT_NAME" up -d qdrant redis)

echo "⏳ Ожидание готовности Qdrant..."
for i in $(seq 1 10); do
    if curl -s http://localhost:6333/ > /dev/null; then
        echo "✅ Qdrant готов."
        break
    fi
    echo "📡 Ожидание Qdrant... ($i/10)"
    sleep 3
done

# 3. Restore Databases (Qdrant & Redis)
echo "📚 Восстановление базы знаний (Bootstrap)..."

# Важно: Останавливаем Redis перед распаковкой, чтобы он не перезаписал dump.rdb при выключении
# И чтобы мы могли безопасно подложить файл
echo "🛑 Временная остановка Redis ($REDIS_CONTAINER) для безопасной распаковки..."
docker stop $REDIS_CONTAINER

# Делаем скрипт загрузчика исполняемым
chmod +x "$RAG_DIR/backup_downloader/bootstrap_and_restore.sh"

# Запускаем загрузчик, который подключится к уже запущенным Qdrant и Redis (Redis остановлен, но volume доступен)
# Примечание: bootstrap-loader пытается подключиться к Redis только если это нужно.
# В текущем bootstrap скрипте он делает 'tar xzf ... -C /redis_data'. Это работа с файловой системой, Redis не нужен запущенным.
# Но он может ждать Qdrant. Qdrant мы не останавливаем.
(cd "$RAG_DIR" && docker compose -f docker-compose-bootstrap.yml up --abort-on-container-exit)

BOOTSTRAP_STATUS="❌ Ошибка"
if [ $? -eq 0 ]; then
    echo "✅ Скачивание backup и распаковка успешны."
    BOOTSTRAP_STATUS="✅ Успешно"
else
    echo "❌ Ошибка Bootstrap!"
    exit 1
fi
# Очистка контейнера загрузчика
(cd "$RAG_DIR" && docker compose -f docker-compose-bootstrap.yml down)

# 4. Start Redis to load the restored dump.rdb
echo "▶️ Запуск Redis ($REDIS_CONTAINER) с восстановленными данными..."
docker start $REDIS_CONTAINER
echo "⏳ Ожидание готовности Redis..."
sleep 5

# 4.1 Start RAG API now that data is restored
echo "🚀 Запуск RAG API и остальных сервисов..."
(cd "$RAG_DIR" && docker compose -f $COMPOSE_FILE -p "$PROJECT_NAME" up -d)

echo "⏳ Ожидание готовности RAG API..."
for i in $(seq 1 30); do
    if curl -s http://localhost:8000/health > /dev/null; then
        echo "✅ RAG API отвечает."
        break
    fi
    echo "📡 Ожидание RAG API... ($i/30)"
    sleep 5
done

# 5. Verify RAG Health and Data Counts
echo "🔍 Проверка RAG Health и данных..."

HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
echo "Health Response: $HEALTH_RESPONSE"

# Парсим JSON ответ с помощью Python
QDRANT_COUNT=$(echo $HEALTH_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('collection_vectors_count', 0))")
REDIS_COUNT=$(echo $HEALTH_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('redis_parent_docs_count', 0))")

echo "📊 Статистика:"
echo "   - Qdrant Vectors: $QDRANT_COUNT"
echo "   - Redis Docs: $REDIS_COUNT"

if [ "$QDRANT_COUNT" == "0" ] || [ "$QDRANT_COUNT" == "None" ]; then
    echo "⚠️ WARNING: Коллекция Qdrant пуста!"
fi

if [ "$REDIS_COUNT" == "0" ] || [ "$REDIS_COUNT" == "None" ]; then
    echo "⚠️ WARNING: Хранилище Redis пусто!"
fi

# Сохраняем статусы для отчета
QDRANT_STATUS="✅ OK ($QDRANT_COUNT векторов)"
if [ "$QDRANT_COUNT" == "0" ] || [ "$QDRANT_COUNT" == "None" ]; then QDRANT_STATUS="⚠️ WARNING (0 векторов)"; fi

REDIS_STATUS="✅ OK ($REDIS_COUNT документов)"
if [ "$REDIS_COUNT" == "0" ] || [ "$REDIS_COUNT" == "None" ]; then REDIS_STATUS="⚠️ WARNING (0 документов)"; fi

# 6. Initialize User Service
echo "👤 Инициализация User Service..."

# Start User Service Group
(cd "$USER_SERVICE_DIR" && docker compose -f $COMPOSE_FILE -p "$USER_PROJECT_NAME" up -d)

echo "⏳ Ожидание User Service DB..."
sleep 10 # Даем время базе подняться

# Apply Migrations
echo "🔧 Применение DB Migrations..."
if docker exec $USER_SERVICE_CONTAINER uv run alembic upgrade head; then
    USER_DB_STATUS="✅ Успешно (Миграции применены)"
else
    USER_DB_STATUS="❌ Ошибка миграций"
fi

# Create and Check Test User
echo "🧪 Создание тестового пользователя (с ролью developer)..."
# Создаем
if docker exec $USER_SERVICE_CONTAINER uv run python scripts/register_user.py test_bootstrap_user test_password developer; then
    USER_CREATE_STATUS="✅ Успешно"
else
    USER_CREATE_STATUS="❌ Ошибка создания"
fi

# Проверка массового создания (если файл существует)
if [ -f "users_to_create.json" ]; then
    echo "👥 Массовое создание пользователей из users_to_create.json..."
    docker cp users_to_create.json $USER_SERVICE_CONTAINER:/app/users_to_create.json
    docker exec $USER_SERVICE_CONTAINER uv run python scripts/bulk_create_users.py users_to_create.json
    USER_BULK_STATUS="✅ Успешно"
else
    USER_BULK_STATUS="➖ Пропущено (файл не найден)"
fi

# Проверяем список пользователей
echo "📋 Список пользователей:"
docker exec $USER_SERVICE_CONTAINER uv run python scripts/list_users.py

# Удаляем пользователя через скрипт
echo "🗑️ Удаление тестового пользователя..."
if docker exec $USER_SERVICE_CONTAINER uv run python scripts/delete_user.py test_bootstrap_user; then
    USER_DELETE_STATUS="✅ Успешно"
else
    USER_DELETE_STATUS="❌ Ошибка удаления"
fi

echo ""
echo "=================================================="
echo "📊 ИТОГОВЫЙ ОТЧЕТ ИНИЦИАЛИЗАЦИИ ($ENV)"
echo "=================================================="
echo "1. Загрузка базы знаний (RAG):      $BOOTSTRAP_STATUS"
echo "2. Состояние Qdrant (Векторы):      $QDRANT_STATUS"
echo "3. Состояние Redis (Документы):     $REDIS_STATUS"
echo "4. База данных User Service:        $USER_DB_STATUS"
echo "5. Тест создания пользователя:      $USER_CREATE_STATUS"
echo "6. Создание пользоватлей (из JSON): $USER_BULK_STATUS"
echo "7. Тест удаления пользователя:      $USER_DELETE_STATUS"
echo "=================================================="

echo ""
echo "🎉 Инициализация системы завершена!"
echo "🚀 Теперь вы можете использовать систему."

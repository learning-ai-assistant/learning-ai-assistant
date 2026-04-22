#!/bin/bash

# Скрипт для сборки всех Docker образов для PROD окружения

echo "🔨 Building all Docker images for PROD mode..."

# Функция для сборки образа
build_image() {
    local folder=$1
    local dockerfile=$2
    local image_name=$3
    echo "📦 Building: $image_name"
    (cd "$folder" && docker build -f "$dockerfile" -t "$image_name" .)
    if [ $? -eq 0 ]; then
        echo "✅ Successfully built: $image_name"
    else
        echo "❌ Failed to build: $image_name"
        exit 1
    fi
}

# 1. User Service
build_image "services/user_service" "Dockerfile-prod" "medphisiker/user_service:v001"

# 2. RAG Service
build_image "services/rag" "Dockerfile" "medphisiker/rag-api:v001"

# 3. Test Generator
build_image "services/test_generator" "Dockerfile" "medphisiker/test_generator:v001"

# 4. Web UI Backend
build_image "services/web_ui_service/backend" "Dockerfile-prod" "medphisiker/web_ui_backend:v001"

# 5. Web UI Frontend
build_image "services/web_ui_service/frontend" "Dockerfile-prod" "medphisiker/web_ui_frontend:v001"

# 6. Agent Service
build_image "services/agent_service" "Dockerfile-prod" "medphisiker/agent_service:v001"

echo ""
echo "🎉 All images built successfully!"
echo ""
echo "Built images:"
echo "  - medphisiker/user_service:v001"
echo "  - medphisiker/rag-api:v001"
echo "  - medphisiker/test_generator:v001"
echo "  - medphisiker/web_ui_backend:v001"
echo "  - medphisiker/web_ui_frontend:v001"
echo "  - medphisiker/agent_service:v001"
echo ""
echo "📝 To push images to Docker Hub, run:"
echo "  docker push medphisiker/user_service:v001"
echo "  docker push medphisiker/rag-api:v001"
echo "  docker push medphisiker/test_generator:v001"
echo "  docker push medphisiker/web_ui_backend:v001"
echo "  docker push medphisiker/web_ui_frontend:v001"
echo "  docker push medphisiker/agent_service:v001"

#!/bin/bash

# Скрипт для отправки всех Docker образов в Docker Hub

echo "📤 Pushing all Docker images to Docker Hub..."

# Функция для пуша образа
push_image() {
    local image_name=$1
    echo "📤 Pushing: $image_name"
    docker push "$image_name"
    if [ $? -eq 0 ]; then
        echo "✅ Successfully pushed: $image_name"
    else
        echo "❌ Failed to push: $image_name"
        exit 1
    fi
}

# Пушим все образы
push_image "medphisiker/user_service:v001"
push_image "medphisiker/rag-api:v001"
push_image "medphisiker/test_generator:v001"
push_image "medphisiker/web_ui_backend:v001"
push_image "medphisiker/web_ui_frontend:v001"
push_image "medphisiker/agent_service:v001"

echo ""
echo "🎉 All images pushed successfully!"

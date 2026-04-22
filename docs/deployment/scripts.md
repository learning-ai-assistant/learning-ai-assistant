# Скрипты развертывания (Deployment Scripts)

В проекте используются скрипты `start-dev.sh`, `stop-dev.sh`, `start-prod.sh` и `stop-prod.sh` для управления жизненным циклом контейнеров. Эти скрипты обеспечивают правильный порядок запуска, группировку сервисов и управление зависимостями для сред разработки (DEV) и эксплуатации (PROD).

## Обзор

Вместо использования одной монолитной команды `docker compose up`, мы разбиваем систему на логические группы (проекты) с помощью переменной `COMPOSE_PROJECT_NAME`. Это позволяет:
1.  Управлять группами сервисов независимо (например, перезапустить только UI).
2.  Избегать конфликтов имен контейнеров.
3.  Обеспечивать строгий порядок запуска (RAG -> Generator -> Agent -> UI).

## Скрипт `start-dev.sh`

Этот скрипт запускает все компоненты системы в режиме разработки.

### Порядок запуска:

1.  **User Service** (`lifelong_learning-user_service`)
    *   Включает: `user-db-dev`, `user-service-dev`.
    *   Создает сеть `user_service_network`.
    *   Инициализирует базу данных (миграции Alembic).
    *   Регистрирует тестового пользователя.

2.  **RAG Service** (`lifelong_learning-rag`)
    *   Включает: `qdrant-dev`, `redis-dev`, `redis-commander-dev`, `rag-api-dev`.
    *   Создает общую сеть `rag_rag_network`.

3.  **Test Generator** (`lifelong_learning-test_generator`)
    *   Включает: `test-generator-dev`.
    *   Использует сеть `test_generator_default`.

4.  **Web UI Service** (`lifelong_learning-web_ui`)
    *   Включает: `web-ui-backend-dev`, `web-ui-frontend-dev`.
    *   Создает сеть `web_ui_network`.

5.  **Agent Service** (`lifelong_learning-agent`)
    *   Включает: `agent-service-dev`.
    *   Подключается к сетям RAG, Test Generator и Web UI.
    *   Запускается последним как оркестратор.

6.  **Algo Sandbox** (из корневого docker-compose-dev.yml)
    *   Включает: `algo-sandbox-dev`.
    *   Песочница для выполнения кода пользователя.

### Использование:

```bash
./start-dev.sh
```

Скрипт автоматически проверит наличие необходимых файлов конфигурации и `.env` файлов. Если что-то отсутствует, он сообщит об ошибке.

## Скрипт `stop-dev.sh`

Этот скрипт корректно останавливает и удаляет контейнеры всех групп.

### Порядок остановки:

1.  **Algo Sandbox** (останавливается первым).
2.  **Agent Service** (останавливается вторым, так как зависит от остальных).
3.  **Web UI Service**.
4.  **Test Generator**.
5.  **RAG Service**.
6.  **User Service** (останавливается последним, так как содержит базу данных пользователей).

### Использование:

```bash
./stop-dev.sh
```

Скрипт останавливает контейнеры и удаляет их, но **сохраняет данные** в именованных томах (volumes), таких как `qdrant_data` и `redis_data`.

## Скрипты PROD окружения

Для запуска системы в продакшн-режиме используются аналогичные скрипты, но работающие с файлами `docker-compose-prod.yml` и использующие образы из GHCR.

### Скрипт `start-prod.sh`

Запускает все компоненты системы, используя стабильные образы из GHCR.

```bash
./start-prod.sh
```

**Порядок запуска:**
1. **User Service** — с инициализацией БД и миграциями
2. **RAG Service** — база знаний
3. **Test Generator** — генератор тестов
4. **Web UI Service** — интерфейс (Backend + Frontend)
5. **Agent Service** — оркестратор

### Скрипт `stop-prod.sh`

Останавливает и удаляет контейнеры продакшн-окружения.

```bash
./stop-prod.sh
```

**Порядок остановки** (обратный запуску):
1. **Agent Service**
2. **Web UI Service**
3. **Test Generator**
4. **RAG Service**
5. **User Service**

### Скрипт `build-prod.sh`

Собирает все Docker образы для PROD окружения.

```bash
./build-prod.sh
```

Собирает образы в следующем порядке:
1. User Service
2. RAG Service
3. Test Generator
4. Web UI Backend
5. Web UI Frontend
6. Agent Service

### Скрипт `push-prod.sh`

Отправляет все собранные образы в GitHub Container Registry (GHCR).

```bash
./push-prod.sh
```

**Важно:** Перед запуском убедитесь, что вы авторизованы в GHCR:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

## Технические детали

### Сетевое взаимодействие

Для связи между контейнерами разных групп используются внешние сети и **сетевые алиасы** (aliases). Это позволяет сервисам обращаться друг к другу по стабильным именам, независимо от динамических имен контейнеров Docker Compose.

| Сервис | Алиас | Порт | Описание |
|--------|-------|------|----------|
| User Service | `user-service` | 8010 | Управление пользователями |
| Agent Service | `agent-service` | 8270 | Основной API агента |
| Web Backend | `web-backend` | 8151 | Бэкенд интерфейса |
| Web Frontend | `web-frontend` | 80 | Фронтенд (Nginx) |
| RAG API | `rag-api` | 8000 | API поиска и RAG |
| Test Generator | `test-generator-api` | 8000 | Генератор тестов |

### Переменные окружения

Скрипты автоматически загружают переменные из `.env` файлов в соответствующих директориях. Убедитесь, что вы создали `.env` файлы на основе `.env_example` перед первым запуском.

### Логирование

Чтобы посмотреть логи конкретной группы сервисов после запуска:

```bash
# Логи агента
docker logs -f agent-service-dev

# Логи бэкенда UI
docker logs -f web-ui-backend-dev

# Логи User Service
docker logs -f user-service-dev

# PROD окружение
docker logs -f user-service-prod
docker logs -f rag-api-prod
docker logs -f test-generator-prod
docker logs -f web-ui-backend-prod
docker logs -f web-ui-frontend-prod
docker logs -f agent-service-prod
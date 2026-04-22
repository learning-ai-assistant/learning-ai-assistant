# Обновление PROD окружения

Этот документ описывает процесс обновления PROD окружения до состояния DEV.

## Обзор

PROD окружение использует Docker образы из GitHub Container Registry (GHCR), в то время как DEV окружение собирает образы локально с горячей перезагрузкой кода.

## Структура PROD окружения

### Сервисы и образы

| Сервис | Образ GHCR | Порт | Docker Compose |
|--------|-----------|------|----------------|
| User Service | `ghcr.io/lifelong-learning-assisttant/user_service:v001` | 8010 | `user_service/docker-compose-prod.yml` |
| RAG API | `ghcr.io/lifelong-learning-assisttant/rag-api:v001` | 8000 | `rag/docker-compose-prod.yml` |
| Test Generator | `ghcr.io/lifelong-learning-assisttant/test_generator:v001` | 52812 | `test_generator/docker-compose-prod.yml` |
| Web UI Backend | `ghcr.io/lifelong-learning-assisttant/web_ui_backend:v001` | 8151 | `web_ui_service/docker-compose-prod.yml` |
| Web UI Frontend | `ghcr.io/lifelong-learning-assisttant/web_ui_frontend:v001` | 8150 | `web_ui_service/docker-compose-prod.yml` |
| Agent Service | `ghcr.io/lifelong-learning-assisttant/agent_service:v001` | 8270 | `agent_service/docker-compose-prod.yml` |

## Скрипты управления

### Сборка образов

```bash
./build-prod.sh
```

Этот скрипт собирает все Docker образы для PROD окружения:
1. User Service
2. RAG Service
3. Test Generator
4. Web UI Backend
5. Web UI Frontend
6. Agent Service

### Публикация образов

```bash
./push-prod.sh
```

Этот скрипт отправляет все собранные образы в GHCR.

**Важно:** Перед запуском убедитесь, что вы авторизованы в GitHub Container Registry:

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

### Запуск PROD окружения

```bash
./start-prod.sh
```

Скрипт запускает сервисы в следующем порядке:
1. User Service (с инициализацией БД и миграциями)
2. RAG Service
3. Test Generator
4. Web UI Service (Backend + Frontend)
5. Agent Service

### Остановка PROD окружения

```bash
./stop-prod.sh
```

## Первичная инициализация (на новом сервере)

Если вы разворачиваете систему на новом сервере "с нуля", необходимо инициализировать базы данных и загрузить знания:

```bash
chmod +x init-new-server.sh
./init-new-server.sh
```

Этот скрипт:
1. Выполнит проверку доступности LLM API.
2. Создаст необходимые Docker сети.
3. Запустит инфраструктуру RAG (Qdrant, Redis).
4. Скачает бэкапы знаний и импортирует их (Bootstrap).
5. Запустит RAG API и остальные сервисы.
6. Создаст структуру таблиц в PostgreSQL и зарегистрирует тестового пользователя.

## Процесс обновления PROD

### Шаг 1: Остановить текущее PROD окружение

```bash
./stop-prod.sh
```

### Шаг 2: Собрать новые образы

```bash
./build-prod.sh
```

### Шаг 3: Опубликовать образы в GHCR

```bash
./push-prod.sh
```

### Шаг 4: Запустить PROD окружение

```bash
./start-prod.sh
```

## Сетевое взаимодействие

PROD окружение использует внешние Docker сети для связи между сервисами:

- `rag_rag_network` — для RAG сервиса
- `test_generator_default` — для генератора тестов
- `web_ui_network` — для Web UI
- `user_service_network` — для сервиса пользователей

### Сетевые алиасы

- `user-service` — сервис пользователей
- `rag-api` — RAG API
- `test-generator-api` — генератор тестов
- `web-backend` — бэкенд интерфейса
- `web-frontend` — фронтенд интерфейса
- `agent-service` — агент

## Внешние тома (Volumes)

PROD окружение использует внешние тома для сохранения данных:

- `rag_qdrant_storage` — данные Qdrant (векторная БД)
- `rag_redis_data` — данные Redis (кэш)
- `user_postgres_data` — данные PostgreSQL (пользователи)

Эти томы являются общими для DEV и PROD окружений, что гарантирует сохранность данных.

## Отличия от DEV окружения

| Характеристика | DEV | PROD |
|----------------|-----|------|
| Сборка образов | Локальная (`build: .`) | Из GHCR (`image: ...`) |
| Монтирование кода | Да (`volumes: ./src:/app`) | Нет |
| Hot-reload | Да | Нет |
| Перезагрузка | Автоматическая | Требует пересборки |
| User Service | Да | Да |
| Algo Sandbox | Да | Нет |

## Тестирование PROD окружения

После обновления PROD окружения рекомендуется провести тестирование:

1. Проверить доступность всех сервисов:
   ```bash
   curl http://localhost:8010/health  # User Service
   curl http://localhost:8000/health  # RAG API
   curl http://localhost:52812/health  # Test Generator
   curl http://localhost:8151/health  # Web UI Backend
   curl http://localhost:8150  # Web UI Frontend
   curl http://localhost:8270/health  # Agent Service
   ```

2. Запустить интеграционные тесты:
   ```bash
   docker exec web_ui_service-backend-prod uv run python /app/tests_integration/test_netrunner_scenarios.py --cfg /app/tests_integration/config-prod.json
   ```

3. Проверить функциональность через Web UI (http://localhost:8150)

## Устранение неполадок

### Образы не загружаются

Убедитесь, что образы существуют в GHCR и вы авторизованы:

```bash
docker images | grep ghcr.io
```

### Сервисы не запускаются

Проверьте логи контейнеров:

```bash
docker logs user-service-prod
docker logs rag-api
docker logs llm-tester-api
docker logs web_ui_backend
docker logs web_ui_frontend
docker logs lifelong_learning-agent-agent-1
```

### Проблемы с сетью

Убедитесь, что все сети созданы:

```bash
docker network ls | grep -E "rag_rag_network|test_generator_default|web_ui_network|user_service_network"
```

Если сети отсутствуют, создайте их:

```bash
docker network create rag_rag_network
docker network create test_generator_default
docker network create web_ui_network
docker network create user_service_network
```

## Версионирование образов

В данный момент используется тег `v001` для всех образов. При следующем обновлении рекомендуется:

1. Увеличить версию до `v002`
2. Обновить все docker-compose-prod.yml файлы
3. Собрать и опубликовать новые образы
4. Остановить и запустить PROD окружение

Это позволит откатиться на предыдущую версию в случае проблем.

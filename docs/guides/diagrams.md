# PlantUML Docker Renderer

Используем готовый `Docker`-образ ([ссылка](https://github.com/VLMHyperBenchTeam/plantuml-docker-renderer)) для автоматического рендеринга `PlantUML` диаграмм в SVG и PNG форматы.

Примеры команд для нашего проекта:

# Установить точку монтирования

## Linux

```
export MOUNT_POINT="/workspace"
```

## Windows
```
$env:MOUNT_POINT="/workspace"
```

# Запустить рендерер

## Рендеринг всех .puml файлов в SVG

```
docker run --rm -v ${PWD}:$env:MOUNT_POINT ghcr.io/vlmhyperbenchteam/plantuml-renderer:latest $env:MOUNT_POINT/docs/diagrams-src/01-overview svg
```

## Рендеринг всех .puml файлов в PNG
```
docker run --rm -v ${PWD}:$env:MOUNT_POINT ghcr.io/vlmhyperbenchteam/plantuml-renderer:latest $env:MOUNT_POINT/docs/diagrams-src/01-overview png
```
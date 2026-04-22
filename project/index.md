# Индекс контекста проекта

## Назначение

Этот файл — entry point для durable project context layer root-проекта `learning-ai-assistant`.

Используй `project/`, чтобы понять repository boundaries, technical baseline, migration state и top-level navigation. Этот слой не является engineering Source of Truth для архитектуры.

## Порядок чтения

1. [`overview.md`](overview.md) для краткого описания проекта и product frame.
2. [`gitContext.md`](gitContext.md) для repository ownership boundaries и nested repos.
3. [`techContext.md`](techContext.md) для technical baseline и environment assumptions.
4. [`entry-points.md`](entry-points.md) для loading order и ownership split между слоями.
5. [`secretsContext.md`](secretsContext.md) для baseline правил работы с secrets.
6. [`repository-map.md`](repository-map.md) для top-level navigation по областям репозитория.
7. [`context-migration.md`](context-migration.md) для текущей миграции от legacy `.kilocode` и `tasks_descriptions/` к новой layered model.

## Границы слоя

- `project/` содержит durable repository context.
- `docs/` содержит architecture, contracts и другие engineering SoT artifacts.
- `operational_scope/` является target execution layer после rename.
- `tasks_descriptions/` пока является legacy execution layer до завершения migration rename.

## Связанные entry points

- [`AGENTS.md`](../AGENTS.md) для repository-wide routing.
- [`README.md`](../README.md) для high-level product overview.

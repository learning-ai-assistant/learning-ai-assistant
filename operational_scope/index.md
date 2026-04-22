# operational_scope

## Назначение

Этот каталог — execution layer root-проекта `learning-ai-assistant`.

Он содержит временные execution artifacts текущей итерации:

- tasks;
- plans;
- backlog.

Этот слой не является engineering Source of Truth для архитектуры. Если execution artifact конфликтует с `docs/`, следуй `docs/`.

## Как читать слой

1. Начинай с [`task-map.md`](task-map.md).
2. Затем переходи в `tasks/`, `plans/` или `backlog/` только по необходимости.
3. Не читай весь execution layer целиком, если нужен только один локальный artifact.

## Entry points

- [`task-map.md`](task-map.md)
- [`../project/index.md`](../project/index.md)
- [`../docs/`](../docs)

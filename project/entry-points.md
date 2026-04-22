# Entry Points

## Назначение

Этот файл задает local loading order и ownership split между контекстными слоями root-проекта.

## Loading order

1. `AGENTS.md` — thin router artifact.
2. [`index.md`](index.md) и релевантные файлы в `project/` — durable repository context.
3. `docs/` — engineering Source of Truth для architecture, contracts и long-lived technical decisions.
4. [`../operational_scope/`](../operational_scope/) — execution layer для plans, tasks, backlog и discussion artifacts.
5. `.kilo/` — Kilo-specific runtime behavior, rules и agents.

## Ownership split

- `AGENTS.md` не хранит полный durable context и не заменяет memory bank.
- `project/` хранит repository boundaries, tech baseline, migration state и routing details.
- `docs/` хранит canonical engineering decisions.
- `operational_scope/` хранит execution status и temporary work artifacts.
- `.kilo/` хранит Kilo runtime/config artifacts и не заменяет `docs/` или `project/`.

## Nested project note

- `sot_layers/hyper-graph/` — nested reference methodology project со своим local context.
- Для root-scoped задач не использовать его как primary project context по умолчанию.
- Если scope задачи уходит внутрь nested methodology project, агент должен переключаться на его local context.

# Context Migration

## Migration direction

Root project переводится:

- от legacy `.kilocode/` context model;
- от execution layer в `tasks_descriptions/`;
- к новой layered model: `AGENTS.md` + `project/` + `operational_scope/` + `.kilo/`.

## Current coexistence state

- [`AGENTS.md`](../AGENTS.md) и `project/` materialize-ятся как новый durable entry system.
- `tasks_descriptions/` пока еще является active legacy execution layer.
- `operational_scope/` является target name и target execution layer после rename.
- `.kilocode/` пока еще существует как legacy nested repo, но не является target steady-state layout.

## Temporary compatibility rules

- Пока rename не завершён, ссылки на execution artifacts могут временно вести в `tasks_descriptions/`.
- Новые durable context decisions нужно фиксировать в `project/` и `docs/`, а не в `.kilocode/`.
- Изменения в `.kilocode/` допустимы только как migration-maintenance до cutover.

## Target state

- `tasks_descriptions/` renamed to `operational_scope/`
- `.kilocode/` removed
- Root project uses only `AGENTS.md`, `project/`, `operational_scope/`, `docs/` and `.kilo/` as steady-state context/runtime layers.

## Related entry points

- [`entry-points.md`](entry-points.md) для loading order.
- [`gitContext.md`](gitContext.md) для repository ownership during migration.

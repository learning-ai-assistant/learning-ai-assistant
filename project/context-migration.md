# Context Migration

## Completed migration direction

Root project переведен:

- от legacy `.kilocode/` context model;
- от execution layer в `tasks_descriptions/`;
- к layered model: `AGENTS.md` + `project/` + `operational_scope/` + `.kilo/`.

## Current model

- [`AGENTS.md`](../AGENTS.md) и `project/` materialize-ятся как новый durable entry system.
- `operational_scope/` materialized как execution layer.
- `.kilo/` materialized как runtime/config layer нового Kilo.

## Active rules

- Durable context decisions фиксируются в `project/` и `docs/`.
- Execution artifacts фиксируются в `operational_scope/`.
- Kilo runtime/config artifacts фиксируются в `.kilo/`.

## Historical note

- Legacy `.kilocode/` и `tasks_descriptions/` считаются superseded layers.
- Steady-state model проекта: `AGENTS.md`, `project/`, `docs/`, `operational_scope/` и `.kilo/`.

## Related entry points

- [`entry-points.md`](entry-points.md) для loading order.
- [`gitContext.md`](gitContext.md) для repository ownership.

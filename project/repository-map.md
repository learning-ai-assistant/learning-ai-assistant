# Repository Map

## Top-level areas

- `README.md` — product overview и high-level orientation.
- `docs/` — engineering Source of Truth для architecture, governance, specs и diagrams.
- `project/` — durable repository context и migration routing.
- `operational_scope/` — execution layer проекта.
- `.kilo/` — nested repo нового Kilo runtime/config.
- `sot_layers/` — methodology/reference assets; отдельные nested/local contexts внутри этой зоны нужно уважать.
- `externel_projects/` — reference repositories, если задача не направлена на них явно.

## Navigation hints

- Для product и architecture reasoning начинай с [`README.md`](../README.md), затем переходи в `docs/`.
- Для repository boundaries и migration state начинай с [`index.md`](index.md).
- Для execution work начинай с [`task-map.md`](../operational_scope/task-map.md).
- Для Kilo runtime behavior читай `.kilo/rules/` и related `.kilo/agents/` artifacts.

# Repository Map

## Top-level areas

- `README.md` — product overview и high-level orientation.
- `docs/` — engineering Source of Truth для architecture, governance, specs и diagrams.
- `project/` — durable repository context и migration routing.
- `tasks_descriptions/` — current legacy execution layer; target rename: `operational_scope/`.
- `.kilo/` — nested repo нового Kilo runtime/config.
- `.kilocode/` — legacy nested repo старого kilocode, target for removal.
- `sot_layers/` — methodology/reference assets; отдельные nested/local contexts внутри этой зоны нужно уважать.
- `externel_projects/` — reference repositories, если задача не направлена на них явно.

## Navigation hints

- Для product и architecture reasoning начинай с [`README.md`](../README.md), затем переходи в `docs/`.
- Для repository boundaries и migration state начинай с [`index.md`](index.md).
- Для execution work пока используй `tasks_descriptions/`, пока rename в `operational_scope/` не выполнен.
- Для Kilo runtime behavior читай `.kilo/rules/` и related `.kilo/agents/` artifacts.

# Обзор проекта

## Назначение

`learning-ai-assistant` — агентная система для ведения Obsidian-базы заметок по алгоритмам, генерации quiz-сценариев и проведения algorithm interview practice.

## Product frame

- Основной пользователь — разработчик, который готовится к algorithm interviews и ведет personal knowledge base в Obsidian.
- Проект помогает систематизировать заметки, дополнять их через controlled web search, проводить quiz practice и сохранять measurable progress.
- Запись в пользовательские артефакты должна проходить через explicit confirm и preview.

## Текущие durable product areas

- Работа с Obsidian vault и tagging/augmentation flow.
- Quiz generation и grading по темам/тегам.
- Algorithm interview workflow с sandbox execution и feedback.
- Сохранение markdown reports и численных метрик.

## Где находится канон

- Product/feature rationale: [`README.md`](../README.md), [`product-proposal.md`](../docs/product-proposal.md)
- Architecture и technical design: [`system-design.md`](../docs/system-design.md), `docs/specs/`, `docs/diagrams/`
- Governance и risk policy: [`governance.md`](../docs/governance.md)

## Migration note

- `sot_layers/hyper-graph/` используется как reference methodology source.
- Local steady-state context этого проекта должен materialize-иться в `AGENTS.md`, `project/`, `operational_scope/` и `.kilo/`, а не читаться напрямую из nested methodology project.

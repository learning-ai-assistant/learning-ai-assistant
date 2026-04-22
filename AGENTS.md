# learning-ai-assistant

## О проекте

`learning-ai-assistant` — проект AI-assistant для работы с Obsidian notes по алгоритмам, генерации quiz-сценариев и проведения algorithm interview practice.

## Как читать контекст

Используй такой порядок чтения:

1. [`project/index.md`](project/index.md) для durable repository context, git boundaries и current repository layout.
3. `docs/` для architecture, contracts и других engineering Source of Truth artifacts.
4. [`operational_scope/`](operational_scope/) для execution-layer контекста текущей итерации.
5. `.kilo/` для Kilo-specific project rules, agents и runtime configuration.

Если temporary planning artifact конфликтует с `docs/`, следуй `docs/`.

## Ключевые entry points

- [`project/index.md`](project/index.md)
- [`project/entry-points.md`](project/entry-points.md)
- [`README.md`](README.md)

## Важная граница

- `sot_layers/hyper-graph/` — reference methodology source и nested project со своим локальным контекстом.
- Root project не должен использовать `sot_layers/hyper-graph/` как свой runtime context layer по умолчанию.

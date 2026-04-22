# Secrets Context

## Назначение

Этот файл задает baseline обращения с secrets и sensitive access data в root-проекте.

## Baseline rules

- Не читать и не выводить secret values без явной необходимости задачи.
- Не копировать secrets в documentation, plans, task files или chat artifacts.
- Не коммитить credentials, tokens, API keys и `.env` values.
- Если задача затрагивает provider setup или local credentials, использовать redact-first поведение.

## Storage guidance

- Runtime secrets должны храниться вне versioned documentation и вне durable context files.
- `project/` и `docs/` могут описывать только handling policy, но не сами значения secrets.

## Boundary note

- Если отдельный tool/runtime config требует secret references, document only the location/pattern, not the secret content.

## Related entry points

- [`gitContext.md`](gitContext.md) для repository boundaries.

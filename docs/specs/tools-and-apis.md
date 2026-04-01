# Спецификация: Tools and APIs

## Назначение
`Tool Layer` инкапсулирует все детерминированные операции PoC: чтение и запись заметок, web search, запуск sandbox, запись отчётов и метрик, обслуживание retrieval index. Этот слой отделяет reasoning от исполнения и не принимает произвольные natural language команды.

## Границы модуля
Tool layer отвечает за:
- выполнение typed commands;
- валидацию аргументов и policy checks перед side effects;
- таймауты, retries и классификацию ошибок;
- публикацию audit and telemetry events;
- вызов внешних систем через безопасные adapters.

Tool layer не отвечает за:
- выбор сценария и принятие решения, какой tool нужен;
- формирование prompt;
- интерпретацию пользовательского намерения;
- хранение высокоуровневого session state.

## Категории инструментов

| Категория | Описание | Side effect |
|---|---|---|
| Vault read | чтение заметок, тегов и отчётов | нет |
| Vault write | патчинг заметок и отчётов | да |
| Web search | поиск и извлечение внешних материалов | внешний read |
| Sandbox run | выполнение кода и тестов | изолированное вычисление |
| Metrics write | запись численных событий и агрегатов | да |
| Index maintenance | refresh и reconcile индекса | да |

## Базовые контракты

### `ToolCommand`
- `command_id`
- `tool_name`
- `category`
- `arguments`
- `risk_level`
- `requires_confirmation`
- `timeout_profile`
- `idempotency_key`

### `ToolResult`
- `command_id`
- `status`
- `payload_ref`
- `error_code`
- `retryable`
- `audit_ref`
- `duration_ms`

## Инструменты по категориям

### Vault read
Назначение:
- чтение заметок по path или logical ref;
- чтение YAML frontmatter;
- чтение markdown reports.

Ограничения:
- доступ только внутри разрешённого vault root;
- абсолютные пути и path traversal запрещены;
- содержимое возвращается как data artifact, а не как команда для исполнения.

### Vault write
Назначение:
- патчинг markdown notes;
- добавление section such as `Sources` или `Addendum`;
- сохранение markdown reports.

Ограничения:
- write только после explicit confirm для пользовательских артефактов;
- payload должен быть связан с preview hash;
- после записи выполняется post-check such as YAML validation when applicable.

### Web search
Назначение:
- поиск внешних источников для augmentation;
- извлечение сниппетов и ссылок.

Ограничения:
- запросы не должны отправлять полный текст заметок без необходимости;
- результаты считаются untrusted input;
- web search не создаёт side effects сам по себе.

### Sandbox run
Назначение:
- выполнение пользовательского кода;
- запуск тестов fixed problem bank;
- сбор детерминированных результатов выполнения.

Ограничения:
- no network;
- лимиты CPU and RAM;
- timeout;
- минимальные mounted resources;
- результаты содержат только технические сигналы, достаточные для interview workflow.

### Metrics write
Назначение:
- запись агрегатов и событий прогресса;
- сохранение latency, token usage и quality signals.

Ограничения:
- идемпотентность обязательна;
- привязка к stable ids such as `session_id` and `event_id`;
- частичный сбой не должен ломать пользовательский ответ.

### Index maintenance
Назначение:
- incremental refresh;
- reconcile проблемных записей;
- обновление tag and note index после подтверждённого write.

Ограничения:
- не должно изменять пользовательский контент beyond index metadata;
- может выполняться асинхронно, если это не ломает свежесть сценария.

## Ошибки и классификация

| Код | Категория | Retry | Поведение |
|---|---|---|---|
| `TOOL_POLICY_BLOCKED` | policy | нет | немедленный safe refusal |
| `TOOL_TIMEOUT` | временная ошибка | да | retry по policy |
| `TOOL_EXTERNAL_UNAVAILABLE` | внешняя зависимость | да | degrade или defer |
| `TOOL_INVALID_ARGUMENTS` | контракт | нет | считать orchestration or validation defect |
| `TOOL_HASH_MISMATCH` | confirmation integrity | нет | запретить write и запросить новый preview |
| `TOOL_PARTIAL_WRITE` | persistence | да | идемпотентное восстановление |

## Security and safety rules
- tool adapters не раскрывают секреты и внутренние credentials в LLM outputs;
- path handling ограничен allowlist директориями;
- sandbox adapter не даёт shell access outside isolated runtime;
- web results маркируются как untrusted;
- все risky actions сопровождаются audit event.

## Наблюдаемость
Tool layer обязан логировать:
- `command_id`, `tool_name`, `category`, `status`
- latency и timeout outcome
- retry count
- факт подтверждения для risky actions
- audit refs для vault writes и sandbox runs
- provider-specific error details only in technical telemetry without leaking secrets

## Критерии готовности реализации
- каждый инструмент имеет typed request and response contract;
- risky actions не могут быть исполнены в обход confirmation protocol;
- ошибки классифицируются единообразно и совместимы с [`docs/specs/orchestrator.md`](orchestrator.md);
- side effects auditируемы и воспроизводимы по telemetry;
- adapters остаются заменяемыми без изменения orchestration contract.

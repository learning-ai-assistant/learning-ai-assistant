# Спецификация: Serving and Config

## Назначение
Этот документ фиксирует архитектурные правила конфигурации и запуска PoC, связанные с backend-serving, `LLM Gateway`, model profiles, секретами и режимами деградации. Цель — обеспечить переносимость между OpenAI-compatible провайдерами и local-first deployment без изменения оркестрационных контрактов.

## Границы
Слой serving and config отвечает за:
- конфигурацию backend-компонентов;
- описание `ModelProfile` и provider endpoints;
- управление timeout, token budgets и fallback policy;
- хранение ссылок на секреты;
- публикацию capability matrix для gateway.

Слой не отвечает за:
- продуктовые сценарии;
- управление session state;
- интерпретацию tool errors;
- хранение пользовательского контента.

## Конфигурационные сущности

### `ModelProfile`
Минимальный контракт профиля модели:
- `profile_id`
- `base_url`
- `model_name`
- `provider_kind`
- `auth_ref`
- `timeout_profile`
- `token_budget`
- `capability_flags`
- `fallback_profile_ref`

### `ProviderCapabilities`
- `supports_structured_output`
- `supports_tool_calling`
- `supports_streaming`
- `supports_json_mode`
- `max_context_hint`

### `RuntimeConfig`
- `environment`
- `vault_root_ref`
- `reports_root_ref`
- `metrics_store_ref`
- `sandbox_profile_ref`
- `default_model_profile_ref`
- `observability_profile_ref`

## Конфигурационные правила
- OpenAI-compatible API является минимальным обязательным контрактом.
- Поддерживаются облачные и локальные endpoints, если они соблюдают нужный контракт запросов и ответов.
- Конкретный провайдер не должен быть зашит в orchestration logic.
- Secrets хранятся вне кода и конфигурации, доступной LLM.
- В PoC допустим file-based config или environment-based config, если сохраняется явная структура профилей.

## Fallback policy

### Приоритет выбора профиля
1. primary model profile для текущего сценария
2. fallback profile того же capability класса
3. локально доступный профиль с урезанной функциональностью
4. deferred AI work, если ни один профиль не позволяет безопасно завершить шаг

### Когда использовать fallback
- timeout primary provider
- временная недоступность endpoint
- достижение cost or token budget limit
- отсутствие нужной capability such as structured output support

### Когда fallback запрещён
- если альтернативный профиль нарушает policy текущей роли;
- если модель не может обеспечить необходимый structured contract;
- если переключение меняет risk surface risky action шага.

## Local-first deployment
- backend должен уметь работать с локальным OpenAI-compatible endpoint;
- Ollama допускается как локальный источник моделей через совместимый bridge;
- отсутствие облачного провайдера не должно ломать базовый запуск PoC;
- деградация допустима, если это явно отражается в `ModelProfile` capabilities.

## HSM integration boundaries
Состав сервисов и их режимы управляются через HSM workflow, зафиксированный в [`README.md`](../README.md:93). На архитектурном уровне это означает:
- конфигурация сервисов описывается декларативно;
- materialization окружения не должна менять contracts модулей;
- switching dev and prod modes допускается без изменения spec contracts.

## Секреты и безопасная конфигурация
- `auth_ref` указывает на секрет, но не содержит сам секрет;
- секреты доступны только backend runtime;
- telemetry не логирует ключи и полный provider payload;
- local-only режим допускается для чувствительных vault данных.

## Ошибки и деградация

| Код | Смысл | Поведение |
|---|---|---|
| `CFG_PROVIDER_UNREACHABLE` | endpoint недоступен | перейти к fallback profile или defer |
| `CFG_UNSUPPORTED_CAPABILITY` | профилю не хватает возможностей | выбрать другой профиль |
| `CFG_SECRET_UNAVAILABLE` | секрет не найден | блокировать провайдера и сообщать о misconfiguration |
| `CFG_BUDGET_EXCEEDED` | превышен budget | переключиться на более дешёвый профиль или defer |

## Наблюдаемость
Serving layer публикует:
- выбранный `profile_id`
- `provider_kind`
- latency endpoint
- budget consumption
- число fallback switches
- capability mismatches

Полный observability-контур см. в [`docs/specs/observability-evals.md`](observability-evals.md).

## Критерии готовности реализации
- переключение между OpenAI-compatible провайдерами не меняет контрактов оркестратора;
- local-first и cloud-backed режимы используют общую модель профилей;
- timeout and budget policies конфигурируются явно;
- секреты изолированы от LLM и пользовательских артефактов;
- serving contracts совместимы с [`docs/system-design.md`](../system-design.md) и [`docs/specs/orchestrator.md`](orchestrator.md).

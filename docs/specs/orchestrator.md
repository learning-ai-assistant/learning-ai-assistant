# Спецификация: Orchestrator

## Назначение
[`Session Orchestrator`](../system-design.md) — центральный управляющий модуль PoC. Он принимает нормализованный запрос от backend-слоя, определяет сценарий, активную роль, следующий шаг графа и координирует вызовы [`LLM Gateway`](serving-config.md), [`Retrieval Service`](retriever.md), [`Memory Service`](memory-context.md) и [`Tool Layer`](tools-and-apis.md).

## Ответственность
Оркестратор отвечает за:
- классификацию запроса и выбор сценария;
- переключение ролей `assistant`, `interviewer`, `mentor`;
- управление графом выполнения шага;
- определение stop condition;
- выбор между LLM-шагом, tool-only шагом и mixed step;
- retries, fallback и создание deferred AI jobs;
- запуск policy checks до и после risky actions;
- запись state transition events в observability-контур.

Оркестратор не отвечает за:
- прямую работу с SDK провайдеров LLM;
- прямое чтение и запись заметок, отчётов и метрик;
- хранение долгоживущих артефактов вне `SessionState` ссылок;
- низкоуровневую индексацию и ранжирование retrieval-данных.

## Основные сущности

### `SessionState`
Минимальный контракт состояния:
- `session_id`
- `user_id`
- `active_role`
- `active_scenario`
- `current_step`
- `pending_confirmation`
- `active_snapshot_refs`
- `deferred_job_refs`
- `last_safe_response_ref`
- `status`

### `TaskIntent`
Нормализованный результат маршрутизации:
- `intent_type`
- `scenario`
- `confidence`
- `requested_role`
- `requires_confirmation`
- `needs_retrieval`
- `needs_llm`

### `WorkflowStepPlan`
План одного шага графа:
- `step_id`
- `step_kind`
- `role_profile_ref`
- `context_bundle_ref`
- `tool_plan_ref`
- `fallback_policy_ref`
- `stop_condition`

## Граф состояний

| Состояние | Назначение | Возможные переходы |
|---|---|---|
| `received` | запрос принят backend-слоем | `classifying` |
| `classifying` | нормализация интента и роли | `retrieving`, `planning`, `blocked` |
| `retrieving` | подготовка snapshot и context bundle | `planning`, `deferred` |
| `planning` | выбор следующего шага | `awaiting_confirmation`, `executing_tool`, `calling_llm`, `completed`, `deferred` |
| `calling_llm` | выполнение LLM-шага | `planning`, `blocked`, `deferred` |
| `awaiting_confirmation` | ожидание явного подтверждения | `executing_tool`, `cancelled` |
| `executing_tool` | выполнение детерминированного side effect | `planning`, `completed`, `blocked` |
| `deferred` | работа отложена из-за внешней зависимости | `completed`, `planning` |
| `blocked` | нарушение policy или неустранимая ошибка | `completed` |
| `completed` | шаг завершён и ответ сформирован | terminal |
| `cancelled` | пользователь отменил risky action | terminal |

## Правила переходов
- `awaiting_confirmation` допускается только для шагов с side effects или policy-sensitive changes.
- `interviewer` не может перейти к шагу, который создаёт ответ с готовым решением задачи.
- `mentor` может читать progress memory, но не активировать sandbox без явного сценария.
- `deferred` используется только если локально возможная часть шага уже завершена или сохранена.
- `blocked` должен сопровождаться объяснимой пользовательской причиной и telemetry event.

## Role-scoped policy

| Роль | Основной фокус | Ключевые ограничения |
|---|---|---|
| `assistant` | заметки, теги, augmentation, навигация по знаниям | write только через preview plus confirm |
| `interviewer` | quiz and interview flow | запрещён вывод полного ответа и полного решения |
| `mentor` | обратная связь, рекомендации, анализ слабых мест | работает только с уже сохранёнными progress artifacts |

## Stop conditions
Оркестратор завершает шаг, когда выполнено одно из условий:
- сформирован пользовательский ответ без незавершённых обязательных side effects;
- создан `pending_confirmation` и управление возвращено UI;
- создан `DeferredAIWorkItem` и пользователю объяснён режим деградации;
- зафиксировано policy block condition;
- сценарий явно завершён и все обязательные артефакты записаны.

## Retry и fallback policy

### Retryable cases
- timeout LLM провайдера;
- временная ошибка web search;
- временный сбой записи метрик;
- временный сбой чтения retrieval index.

### Non-retryable cases
- нарушение policy;
- hash mismatch у подтверждаемого payload;
- invalid user input без возможности безопасного исправления;
- несовместимый structured output после исчерпания parser recovery.

### Fallback rules
- при недоступности LLM оркестратор сохраняет локально возможный результат и создаёт deferred job;
- при недоступности web search сценарий продолжает работу по локальным материалам, если это допустимо;
- при частичном сбое persistence оркестратор использует stable ids и идемпотентное восстановление;
- provider switch не меняет контрактов orchestration-слоя.

## Контракты взаимодействия

### Входы оркестратора
- нормализованный запрос от backend API;
- `SessionState` из [`docs/specs/memory-context.md`](memory-context.md);
- retrieval snapshot ref из [`docs/specs/retriever.md`](retriever.md);
- policy flags из role profile;
- tool capabilities из [`docs/specs/tools-and-apis.md`](tools-and-apis.md).

### Выходы оркестратора
- `WorkflowStepPlan`;
- `ToolExecutionPlan` для tool layer;
- `LLMStepRequest` для gateway;
- state transition events;
- final response envelope или deferred work record.

## Ошибки и исключительные ситуации

| Код | Смысл | Действие |
|---|---|---|
| `ORCH_POLICY_BLOCK` | шаг запрещён policy | вернуть safe refusal |
| `ORCH_CONFIRMATION_REQUIRED` | нужен confirm | сформировать preview и ждать UI |
| `ORCH_CONTEXT_BUDGET_EXCEEDED` | слишком большой context | пересобрать bundle через memory policy |
| `ORCH_PROVIDER_DEFERRED` | LLM шаг отложен | создать deferred job |
| `ORCH_TOOL_FAILURE` | tool завершился ошибкой | классифицировать retryability |
| `ORCH_INVALID_ROLE_TRANSITION` | запрещённый handoff ролей | заблокировать переход |

## Наблюдаемость
Оркестратор обязан логировать:
- `session_id`, `request_id`, `active_role`, `scenario`, `current_step`
- outcome классификации интента
- время шагов планирования и переходов
- причины fallback и deferred mode
- policy decisions и blocked transitions
- ссылки на tool execution events и LLM usage events

Полный план наблюдаемости описан в [`docs/specs/observability-evals.md`](observability-evals.md).

## Критерии готовности реализации
Реализация orchestration-слоя считается соответствующей дизайну, если:
- graph execution детерминированно воспроизводим по `SessionState` и telemetry;
- роль, tool allowlist и memory scope переключаются согласованно;
- risky actions всегда проходят через confirmation-first protocol;
- deferred AI work не приводит к потере пользовательского результата;
- интерфейсы с gateway, retrieval и tools остаются typed и vendor-neutral.

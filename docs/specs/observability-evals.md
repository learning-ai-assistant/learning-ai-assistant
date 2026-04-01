# Спецификация: Observability and Evals

## Назначение
Этот документ фиксирует минимально необходимый контур наблюдаемости, контроля качества и eval-проверок для PoC. Цель — сделать поведение orchestration-слоя, LLM-шагов, tool execution и механизмов защиты проверяемыми, а деградацию — заметной и управляемой.

## Границы
Контур observability and evals отвечает за:
- трассировку запросов, сессий и ключевых шагов;
- сбор latency, token, tool and fallback metrics;
- хранение safety и quality сигналов;
- сценарные evals и anti-cheating проверки;
- поддержку анализа деградации и provider portability.

Контур не отвечает за:
- принятие продуктовых решений по UI;
- выполнение бизнес-сценариев;
- хранение полного пользовательского контента в логах.

## Что должно логироваться

| Категория | Обязательные поля |
|---|---|
| Request telemetry | `request_id`, `session_id`, `active_role`, `scenario`, `step_id` |
| LLM telemetry | `profile_id`, `provider_kind`, latency, token usage, parse status |
| Retrieval telemetry | `query_id`, hit count, filtered count, snapshot size, latency |
| Tool telemetry | `command_id`, `tool_name`, status, duration, retry count |
| Confirmation telemetry | `confirmation_id`, requested action, approved or rejected |
| Safety telemetry | policy block code, anti-cheating signal, scope violation |
| Degradation telemetry | fallback trigger, deferred job id, degraded mode reason |

## Что не должно логироваться
- полное содержимое заметок;
- секреты и provider credentials;
- полные prompts с чувствительным пользовательским контентом без отдельного debug mode и согласия;
- код пользователя целиком во внешних telemetry sinks.

## Метрики

### Технические метрики
- latency orchestration steps
- latency retrieval queries
- latency provider calls
- sandbox execution time
- share of deferred AI jobs
- share of retryable и non-retryable ошибок

### Качественные метрики
- accept rate предложенных тегов
- доля write-операций, реально прошедших через explicit confirm
- доля quiz sessions, завершённых без потери результатов
- доля interview sessions без anti-cheating нарушений
- provider portability success rate по smoke scenarios

### Safety метрики
- число policy block events по ролям
- число попыток запроса полного решения в interview mode
- число hash mismatch на confirmation steps
- число path policy violations

## Eval records

### `EvalRecord`
- `eval_id`
- `scenario`
- `criteria_set`
- `score`
- `result`
- `failure_reasons`
- `reviewer_type`
- `artifact_refs`

### Типы evals
| Тип | Назначение |
|---|---|
| Scenario eval | проверка типового пользовательского сценария |
| Safety eval | проверка guardrails и policy blocks |
| Portability eval | проверка разных OpenAI-compatible провайдеров |
| Degradation eval | проверка fallback и deferred flows |
| Regression eval | проверка сохранения качества после изменений |

## Anti-cheating контроль
Для `interviewer` режима observability-контур должен фиксировать:
- сигналы на попытку раскрытия полного решения;
- факт срабатывания hint-only policy;
- повторяющиеся dangerous prompts;
- расхождения между prompt policy и фактическим output class.

Эти сигналы используются как для telemetry, так и для safety regression evals.

## Сценарии обязательных evals
- tagging with confirmation
- augmentation with unavailable web search
- quiz with deferred AI grading
- interview with sandbox result and anti-cheating pressure
- provider switch between two OpenAI-compatible profiles
- confirmation hash mismatch
- retrieval stale then reconcile

## Деградация и восстановление
Наблюдаемость должна позволять ответить на вопросы:
- какой шаг деградировал;
- почему сработал fallback;
- был ли пользовательский результат сохранён;
- требуется ли ручное вмешательство;
- можно ли доисполнить deferred AI work автоматически.

## Критерии готовности реализации
- каждый значимый шаг сценария traceable по `request_id` и `session_id`;
- telemetry позволяет анализировать latency, cost, safety и quality без хранения лишнего контента;
- evals покрывают все четыре PoC-сценария и ключевые guardrails;
- anti-cheating события выделены как отдельный класс сигналов;
- контур совместим с [`docs/specs/orchestrator.md`](orchestrator.md), [`docs/specs/tools-and-apis.md`](tools-and-apis.md) и [`docs/specs/serving-config.md`](serving-config.md).

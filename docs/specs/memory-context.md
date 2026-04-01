# Спецификация: Memory and Context

## Назначение
`Memory Service` управляет состоянием сессии, общей памятью прогресса, role-scoped memory и сборкой `ContextBundle` для LLM-шагов. Задача сервиса — удерживать только полезный и безопасный контекст, не раздувая prompt и не смешивая роли.

## Границы модуля
Memory service отвечает за:
- хранение и обновление `SessionState`;
- ведение общей памяти прогресса;
- раздельное хранение role-scoped memory;
- сборку `ContextBundle` по budget policy;
- хранение `pending_confirmation` и ссылок на snapshot and artifacts;
- сокращение stale or duplicated context.

Memory service не отвечает за:
- выбор сценария и переходов графа;
- вызовы LLM и инструментов;
- низкоуровневую запись markdown-отчётов и метрик;
- policy decisions beyond already approved rules.

## Memory layers

| Слой | Назначение | Примеры данных |
|---|---|---|
| Request context | данные одного шага | текущее сообщение, временный preview, выбранная заметка |
| Session state | состояние активной сессии | роль, шаг сценария, pending confirmation |
| Shared progress memory | общая история пользователя | summaries квизов, слабые темы, принятые изменения |
| Role-scoped memory | память внутри роли | interviewer warnings, mentor recommendations |
| Artifact memory | durable references | snapshot ids, report ids, deferred job ids |

## Основные контракты

### `SessionState`
- `session_id`
- `user_id`
- `active_role`
- `active_scenario`
- `current_step`
- `pending_confirmation`
- `active_snapshot_refs`
- `artifact_refs`
- `deferred_job_refs`
- `status`

### `ContextBundle`
- `bundle_id`
- `session_summary`
- `role_memory_refs`
- `progress_refs`
- `retrieval_snapshot_refs`
- `budget_policy`
- `excluded_refs`
- `reasoning_scope`

### `PendingConfirmation`
- `confirmation_id`
- `payload_hash`
- `preview_ref`
- `requested_action`
- `expires_at`
- `status`

## Context budget policy

### Основные правила
- в LLM передаётся только минимально достаточный контекст;
- retrieval snippets приоритетнее полного сырого содержимого больших заметок;
- summary предпочтительнее повторной передачи уже обсуждённых фрагментов;
- role-scoped memory не должна утекать между ролями без явного policy rule;
- interview mode не получает скрытые solution artifacts.

### Приоритеты включения в bundle
1. текущий пользовательский запрос
2. активный шаг сценария
3. `pending_confirmation`, если он есть
4. свежий retrieval snapshot
5. краткий session summary
6. role-specific memory
7. shared progress memory при необходимости

### Правила отсечения
- удалять дубликаты по `artifact_ref` и semantic role;
- исключать stale fragments, если есть более свежий summary;
- ограничивать число historical artifacts по budget policy;
- для augmentation не включать полный текст заметки, если достаточно целевого фрагмента и metadata.

## Политика подтверждений
- risky action создаёт `PendingConfirmation` до выполнения side effect;
- preview и исполняемый payload связываются через `payload_hash`;
- после confirm разрешён только exact payload execution;
- после reject preview помечается закрытым и не может быть использован повторно.

## Summary strategy
- session summary обновляется после завершения значимых шагов, а не после каждого токена диалога;
- summary должен хранить факты и ссылки на артефакты, а не копию полного диалога;
- progress memory агрегирует только полезные для будущих сценариев данные;
- mentor получает summaries прогресса, а interviewer получает только допустимые interview-related сигналы.

## Изоляция ролей

| Роль | Что может читать | Что не должна получать |
|---|---|---|
| `assistant` | заметки, summaries, approved note context | hidden evaluation criteria interview mode |
| `interviewer` | problem statement, progress hints, sandbox summaries | готовые решения и mentor-only рекомендации |
| `mentor` | отчёты, summaries, слабые темы, прошлый feedback | неподтверждённые write previews |

## Ошибки и деградация

| Код | Смысл | Поведение |
|---|---|---|
| `MEM_CONTEXT_TOO_LARGE` | bundle превышает budget | пересобрать bundle с более жёстким отсечением |
| `MEM_CONFIRMATION_HASH_MISMATCH` | payload не совпадает с preview | запретить выполнение и запросить новый preview |
| `MEM_STALE_ARTIFACT` | ссылка ведёт на устаревший артефакт | пересобрать summary или snapshot refs |
| `MEM_ROLE_SCOPE_VIOLATION` | role memory смешана некорректно | блокировать bundle и логировать policy event |

## Наблюдаемость
Memory service публикует:
- размер и состав `ContextBundle`
- число исключённых фрагментов
- факт использования summary вместо raw artifacts
- события создания и завершения confirmation state
- нарушения role-scoped isolation

Детали observability-контуров приведены в [`docs/specs/observability-evals.md`](observability-evals.md).

## Критерии готовности реализации
- `ContextBundle` воспроизводим и ограничен budget policy;
- pending confirmation надёжно защищает от выполнения отличающегося payload;
- role-scoped memory не протекает между режимами;
- progress memory помогает следующим сценариям, не раздувая prompt;
- contracts совместимы с [`docs/specs/orchestrator.md`](orchestrator.md).

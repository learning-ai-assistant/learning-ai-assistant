# System Design: learning-ai-assistant

## 1. Scope and source documents

Этот документ фиксирует только архитектурные решения PoC.

Архитектурный scope этого документа:
- orchestration-first устройство PoC;
- границы модулей и их ответственность;
- execution flow и role handoff;
- state, memory и context budget handling;
- retrieval-контур;
- tool and API integration boundaries;
- failure handling, degradation и quality control;
- ссылки на модульные спецификации в [`docs/specs/`](docs/specs).

## 2. Architectural decisions

### AD-001 Orchestration-first core
Центром системы является `Session Orchestrator`, который управляет state graph, role handoff, routing, retries, fallbacks и policy enforcement.

### AD-002 Unified LLM gateway over OpenAI-compatible API
Внешние и локальные модели подключаются через единый `LLM Gateway`, работающий по OpenAI-compatible contract. Это позволяет использовать OpenAI, совместимых облачных провайдеров и локальные модели через Ollama без изменения orchestration contracts.

### AD-003 Role-scoped agent behavior
Режимы `assistant`, `interviewer`, `mentor` разделяются через `AgentRoleProfile`: у каждой роли свой prompt profile, tool allowlist, memory scope и safety policy.

### AD-004 Deterministic side effects
LLM не выполняет side effects напрямую. Все write, sandbox и persistence операции проходят через typed tool contracts, validation и policy checks.

### AD-005 Confirmation-first write policy
Любые изменения пользовательских markdown-артефактов выполняются только через preview plus explicit confirm. Исполняется только payload, который пользователь видел и подтвердил.

### AD-006 Retrieval snapshot as reproducible context
LLM работает не с произвольным накопленным контекстом, а с `RetrievalSnapshot` и `ContextBundle`, чтобы сделать reasoning воспроизводимым, ограничивать размер prompt и улучшать auditability.

### AD-007 Deferred AI work instead of hard failure
Если LLM недоступна или не завершает шаг, система сохраняет локально возможный результат, создаёт `DeferredAIWorkItem` и допускает последующую дообработку без потери пользовательской сессии.

## 3. Architectural constraints

Технические ограничения и scope-решения, влияющие на дизайн:
- базовый язык реализации — Python 3.13+ согласно [`pyproject.toml`](pyproject.toml:1)
- управление стеком — HSM-first согласно [`README.md`](README.md:93)
- все 4 PoC-сценария из [`docs/product-proposal.md`](docs/product-proposal.md:39) обязательны
- интеграция с LLM обязана работать через OpenAI-compatible API
- заметки и web-источники считаются untrusted input согласно [`docs/governance.md`](docs/governance.md:62)
- dual persistence обязателен: markdown reports плюс отдельное хранилище численных метрик
- алгоритмические задачи берутся из фиксированного банка, а не генерируются on the fly
- архитектура должна поддерживать local-first deployment на машине пользователя

## 4. Container view

| Container | Responsibility | Key outputs |
|---|---|---|
| Web UI | чат, preview, confirm flows, quiz and interview screens, stats UI | user commands, confirmations, rendered reports |
| Backend API | request validation, auth boundary, session bootstrap, sync entrypoint for UI | normalized request, response envelope |
| Session Orchestrator | intent routing, workflow graph, role handoff, retry and stop conditions | tool plans, LLM requests, state transitions |
| LLM Gateway | model selection, OpenAI-compatible calls, schema parsing, provider fallback | structured completions, provider telemetry |
| Retrieval Service | indexing, lookup, reranking, retrieval snapshot materialization | `RetrievalSnapshot`, ranked sources |
| Memory Service | session state, shared progress memory, role-scoped memory, context budget assembly | `SessionState`, `ContextBundle` |
| Tool Layer | vault IO, web search, sandbox, metrics write, report write, index maintenance | `ToolResult`, side effects |
| Persistence Layer | reports, metrics, index store, metadata, deferred jobs | durable artifacts and ids |
| Observability and Eval Layer | traces, logs, latency, token usage, quality and safety eval records | telemetry, alerts, eval records |

## 5. Boundaries and dependency rules

### Allowed dependency direction
`Web UI` → `Backend API` → `Session Orchestrator`

`Session Orchestrator` may call:
- `Memory Service`
- `Retrieval Service`
- `LLM Gateway`
- `Tool Layer`
- `Observability and Eval Layer`

`Tool Layer` may call:
- `Persistence Layer`
- external systems such as vault, web search and sandbox

### Forbidden shortcuts
- UI не вызывает LLM, retrieval или tools напрямую.
- LLM Gateway не знает про бизнес-policy, vault paths и interview rules.
- Retrieval Service не выполняет side effects.
- Tool Layer не принимает natural language intent.
- Memory Service не хранит policy logic и не принимает решений о вызовах инструментов.

## 6. Core execution model

### 6.1 Common request lifecycle
1. UI отправляет запрос и session metadata в Backend API.
2. Backend API валидирует payload и восстанавливает `SessionState`.
3. Orchestrator определяет intent, scenario step и активный role profile.
4. Memory Service собирает `ContextBundle` с учётом context budget.
5. При необходимости Retrieval Service формирует `RetrievalSnapshot`.
6. Orchestrator выбирает next action:
   - structured LLM step через `LLM Gateway`
   - deterministic tool step через `Tool Layer`
   - mixed step LLM → tool plan → confirm → tool execution
7. После шага обновляется state, telemetry и durable artifacts.
8. Если шаг не может быть завершён из-за внешней зависимости, создаётся deferred work record.

### 6.2 Scenario execution patterns
Подробное пользовательское поведение описано в [`docs/product-proposal.md`](docs/product-proposal.md). На архитектурном уровне сценарии отличаются так:

| Scenario | Primary retrieval scope | Critical guardrail | Durable output |
|---|---|---|---|
| Tagging | note plus tag index | explicit confirm before note write | updated note plus audit event |
| Augmentation | note plus web results | source provenance and explicit confirm | note patch plus source trace |
| Quiz | notes by tags plus prior progress | schema validation of quiz and grading payloads | markdown report plus metrics |
| Interview | fixed problem bank plus progress history | anti-cheating and sandbox isolation | markdown report plus metrics |

### 6.3 Role handoff model
- `assistant` отвечает за заметки, поиск материалов и общие пояснения
- `interviewer` ведёт quiz and interview flow, не раскрывая solution content
- `mentor` использует накопленный progress context для обратной связи и рекомендаций

Переключение ролей меняет:
- prompt profile
- tool allowlist
- доступный memory slice
- output policy

## 7. State, memory and context handling

### 7.1 Memory layers
| Memory layer | Scope | Stored data |
|---|---|---|
| Request context | one request | current user message, selected artifact refs, temporary preview |
| Session state | active session | role, scenario step, pending confirmation, active snapshot refs |
| Shared progress memory | long-lived | summaries of quizzes, weak topics, accepted note changes |
| Role-scoped memory | per role | interviewer flags, mentor recommendations, assistant working notes |
| Artifact memory | durable | report ids, metric ids, snapshot ids, deferred job refs |

### 7.2 Context budget rules
- В prompt передаётся только минимально достаточный `ContextBundle`.
- Большие заметки подаются через ranked snippets, а не полные raw files, если это не требуется явно.
- Дублирующиеся fragments и stale artifacts отбрасываются перед LLM step.
- Interview mode не получает готовые решения и hidden answer banks.
- Memory summaries пересобираются детерминированно, а не копируются бесконечно между шагами.

### 7.3 Confirmation state
Для risky actions хранится immutable `pending_confirmation` с hash payload. После подтверждения может быть исполнен только тот payload, который был показан пользователю в preview.

## 8. Retrieval design

### 8.1 Sources
- Obsidian notes and YAML tags
- tag index and note metadata
- fixed algorithm problem bank
- external web search results
- historical markdown reports and progress summaries

### 8.2 Retrieval pipeline
1. ingestion and normalization
2. incremental indexing
3. query planning per scenario
4. retrieval by metadata, tags and keyword features
5. optional reranking
6. snapshot materialization with provenance

### 8.3 Retrieval policies
- YAML frontmatter является каноническим источником тегов для note workflows
- web results используются как transient context до пользовательского подтверждения записи
- retrieval snapshot versioned и используется в reports для воспроизводимости
- interview retrieval не должен подмешивать hidden solution artifacts в user-visible context

Подробная спецификация retrieval boundary и contracts — [`docs/specs/retriever.md`](docs/specs/retriever.md).

## 9. LLM interaction architecture

### 9.1 Gateway responsibilities
`LLM Gateway` отвечает за:
- binding к OpenAI-compatible endpoint
- model profile selection
- timeout and retry policy
- structured output parsing
- provider portability
- token accounting

### 9.2 Model profile abstraction
Каждая модель описывается `ModelProfile`:
- `base_url`
- `model_name`
- `auth_ref`
- `timeout profile`
- `token budget`
- `capability flags`

### 9.3 LLM step contract
Orchestrator отправляет в gateway:
- role profile ref
- `ContextBundle`
- structured response schema ref
- tool schema refs when needed
- fallback policy

Gateway возвращает:
- parsed structured output
- refusal or policy signal
- usage metrics
- provider metadata needed for observability

Подробности конфигурации и portability boundary — [`docs/specs/serving-config.md`](docs/specs/serving-config.md).

## 10. Tool and API integration architecture

### 10.1 Tool categories
| Tool | Purpose | Side effect class |
|---|---|---|
| Vault read | read notes, tags, reports | none |
| Vault write | patch notes or reports | risky |
| Web search | fetch external materials | external read |
| Sandbox run | execute user code and tests | isolated compute |
| Metrics write | persist numeric aggregates | durable write |
| Index maintenance | refresh or reconcile retrieval index | internal write |

### 10.2 Tool execution rules
- каждый tool имеет typed input and output contract
- timeout и retry задаются per category
- идемпотентность обязательна для metrics and report completion flows
- tool errors классифицируются как retryable, non-retryable, user-fixable or policy-blocked
- credentials hidden from LLM

Подробные tool contracts и failure semantics — [`docs/specs/tools-and-apis.md`](docs/specs/tools-and-apis.md).

## 11. Persistence architecture

### Durable stores
| Store | Purpose |
|---|---|
| Markdown report storage | human-readable reports for quiz and interview sessions |
| Metrics store | numeric aggregates for UI and evals |
| Retrieval index store | notes, tags, metadata and source references |
| Session and metadata store | active state, snapshot refs, deferred jobs |

### Persistence rules
- report and metric writes связаны stable identifiers such as `session_id` and `event_id`
- частичный сбой одного storage не должен приводить к потере session outcome
- deferred completion обязана быть идемпотентной
- локальный файловый storage допустим для PoC, если сохраняются контракты и recovery semantics

## 12. Observability, quality control and evals

### What must be observable
- request and session ids
- active role and scenario step
- retrieval timings and hit counts
- LLM provider, model profile, latency and token usage
- tool calls, statuses and error codes
- confirmation accepted or rejected events
- deferred AI work lifecycle
- anti-cheating policy signals

### Quality control loops
- contract validation for structured LLM outputs before side effects
- scenario-based evals for tagging, augmentation, quiz and interview flows
- anti-cheating regression tests in interviewer mode
- portability smoke tests across OpenAI-compatible providers
- fallback drills for provider outage, web search outage and partial persistence failure

Подробный telemetry and eval plan — [`docs/specs/observability-evals.md`](docs/specs/observability-evals.md).

## 13. Failure handling and degradation

| Failure mode | Detection | Degradation strategy |
|---|---|---|
| LLM unavailable | timeout, 5xx, malformed response | retry, switch model profile, defer AI-only step |
| Web search unavailable | integration error, quota issue | continue with local notes and explain limitation |
| Vault write rejected | validation error, hash mismatch, path policy error | abort write and require new preview |
| Retrieval stale | reconcile mismatch, missing refs | trigger reindex and retry retrieval |
| Sandbox failed | container exit, timeout, policy violation | return deterministic execution summary and preserve attempt |
| Partial persistence failure | one store write failed | retry with idempotent ids and recover asynchronously |
| Anti-cheating risk | classifier or rule signal | block full answer and downgrade to hint-only response |

Базовые guardrails уже зафиксированы в [`docs/governance.md`](docs/governance.md), а этот документ добавляет архитектурное правило: любой fallback обязан сохранять session continuity и не расширять risk surface относительно normal flow.

## 14. Technical and operational targets

| Area | Architectural target |
|---|---|
| Latency | orchestration overhead without external LLM latency should remain within interactive UX budget |
| Cost | each `ModelProfile` has token ceilings, timeout profile and fallback policy |
| Reliability | durable artifacts use stable ids and recoverable writes |
| Security | untrusted content isolation, confirmation-first write policy, sandbox isolation |
| Portability | provider switch does not change orchestrator contracts |
| Local-first | deployment on user machine remains supported without cloud-only assumptions |

Конкретные продуктовые и технические метрики см. в [`docs/product-proposal.md`](docs/product-proposal.md:16).

## 15. Architecture artifacts map

### Diagrams
- context and boundaries — [`docs/diagrams/context.md`](docs/diagrams/context.md)
- containers — [`docs/diagrams/container.md`](docs/diagrams/container.md)
- orchestrator internals — [`docs/diagrams/component.md`](docs/diagrams/component.md)
- workflow and error branches — [`docs/diagrams/workflow.md`](docs/diagrams/workflow.md)
- data flow and logging boundaries — [`docs/diagrams/data-flow.md`](docs/diagrams/data-flow.md)

### Module specs
- orchestrator and session contracts — [`docs/specs/orchestrator.md`](docs/specs/orchestrator.md)
- retrieval architecture — [`docs/specs/retriever.md`](docs/specs/retriever.md)
- memory and context policy — [`docs/specs/memory-context.md`](docs/specs/memory-context.md)
- tools and integrations — [`docs/specs/tools-and-apis.md`](docs/specs/tools-and-apis.md)
- serving and configuration — [`docs/specs/serving-config.md`](docs/specs/serving-config.md)
- observability and evals — [`docs/specs/observability-evals.md`](docs/specs/observability-evals.md)

## 16. Open questions for implementation stage

- выбрать конкретный storage engine для metrics and metadata
- определить, нужен ли dedicated reranker в первом implementation increment
- выбрать канонический формат fixed problem bank
- решить, нужен ли отдельный background worker для deferred AI jobs

Эти вопросы intentionally оставлены на implementation stage, так как не меняют базовые boundaries и key contracts текущего system design.

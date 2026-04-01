# Архитектура агента

## Overview

Этот документ описывает внутреннюю архитектуру агента внутри контейнера [`Agent System`](diagrams/component.md) и дополняет общую системную архитектуру из [`docs/system-design.md`](system-design.md).

Агент строится на базе LangGraph по паттерну `supervisor plus subgraphs`.

Это означает:
- есть верхнеуровневый supervisor graph
- supervisor принимает пользовательский запрос и определяет сценарий
- специализированные ветки поведения оформляются как подграфы
- retrieval и memory используются как общие сервисы, но управление остаётся у supervisor
- завершение шага подграфа возвращает управление обратно supervisor или завершает пользовательский шаг

## Supervisor graph

Supervisor graph — верхнеуровневый граф, который управляет маршрутизацией запросов, role handoff, запуском подграфов и возвратом результата.

```mermaid
flowchart TD
    user[Пользователь] --> entry[User Request Entry]
    entry --> supervisor{Supervisor}

    subgraph global[Global Agent State]
        session[Session State]
        profile[Role and Progress State]
        pending[Pending Confirmation]
    end

    supervisor <--> session
    supervisor <--> profile
    supervisor <--> pending

    supervisor --> note[Note Workflow Subgraph]
    supervisor --> quiz[Quiz Workflow Subgraph]
    supervisor --> algo[Algo Interview Subgraph]
    supervisor --> retrieval[Shared Retrieval Subgraph]

    note --> supervisor
    quiz --> supervisor
    algo --> supervisor
    retrieval --> supervisor
```

Supervisor отвечает за:
- определение сценария выполнения
- выбор активной роли агента
- подготовку handoff в нужный подграф
- контроль stop conditions
- возврат к пользователю или переход в deferred режим
- координацию confirmation-first шагов

## Role model

В первой версии PoC фиксируются три роли агента.

| Роль | Назначение | Ограничения | Типичные сценарии |
|---|---|---|---|
| `assistant` | Помощь с заметками, тегами, augmentation и общими вопросами | не делает write без preview и confirm | tagging, augmentation, навигация по заметкам |
| `interviewer` | Ведёт квиз или алгоритмическое интервью | не раскрывает готовые ответы и полные решения | quiz flow, algo interview flow |
| `mentor` | Проводит разбор результатов и даёт развивающую обратную связь | работает на основе уже полученных результатов и прогресса | post-quiz review, post-interview discussion |

### Handoff между ролями
- `assistant` → `interviewer` при запуске квиза или интервью
- `interviewer` → `mentor` после завершения сессии или по явному переходу к разбору
- `mentor` → `assistant` после завершения обсуждения результатов

## Scoped state

LangGraph-архитектура агента требует явного разделения состояния по уровням.

| Слой состояния | Назначение | Примеры данных |
|---|---|---|
| Global agent state | Общее состояние графа и сессии | `session_id`, `active_role`, `active_subgraph`, `status` |
| Shared progress state | Долгоживущий прогресс пользователя | слабые темы, история квизов, история интервью |
| Pending confirmation state | Подтверждение risky actions | preview ref, payload hash, confirmation status |
| Subgraph state | Локальное состояние конкретного подграфа | текущий вопрос квиза, текущая задача интервью, note target |
| Artifact refs | Ссылки на долговечные артефакты | report refs, retrieval snapshot refs, deferred job refs |

### Принципы scoped state
- supervisor видит только то состояние, которое нужно для orchestration
- подграф получает только ту часть состояния, которая нужна для его сценария
- возврат из подграфа происходит через нормализованный handoff payload
- состояние подтверждений хранится отдельно от логики диалога
- история прогресса не должна бесконтрольно попадать в каждый prompt

## Subgraphs

В первой версии архитектуры агента фиксируются четыре подграфа.

### 1. Note workflow subgraph

Назначение:
- обработка tagging сценариев
- обработка augmentation сценариев
- управление preview и confirm для изменений заметок

Особенности:
- работает в роли `assistant`
- использует retrieval по заметкам и тегам
- использует `Tool Layer` для чтения и записи в [`Obsidian Vault`](diagrams/context.md)
- все write-операции проходят через confirmation-first policy

```mermaid
flowchart TD
    note_start[Start] --> note_load[Load Note Context]
    note_load --> note_route{Note Intent}

    note_route --> note_tag[Prepare Tagging Draft]
    note_route --> note_aug[Prepare Augmentation Draft]

    note_tag --> note_retrieve[Shared Retrieval]
    note_aug --> note_search[Shared Retrieval]

    note_retrieve --> note_preview[Build Preview]
    note_search --> note_preview

    note_preview --> note_confirm{Need Confirm}
    note_confirm -->|yes| note_wait[Await Confirmation]
    note_confirm -->|no| note_finish[Finish Step]

    note_wait --> note_apply[Apply Note Change]
    note_apply --> note_finish
```

### 2. Quiz workflow subgraph

Назначение:
- проведение квиза по выбранным темам или тегам
- управление вопросами, ответами и завершением сессии
- передача результатов в режим разбора

Особенности:
- начинает работу в роли `interviewer`
- при завершении может передать управление в роль `mentor`
- использует retrieval по заметкам и прогрессу
- сохраняет отчёты и численные результаты

```mermaid
flowchart TD
    quiz_start[Start] --> quiz_prepare[Prepare Quiz Context]
    quiz_prepare --> quiz_generate[Generate Questions]
    quiz_generate --> quiz_ask[Ask Current Question]
    quiz_ask --> quiz_input[Receive User Answer]
    quiz_input --> quiz_check{More Questions}

    quiz_check -->|yes| quiz_next[Store Answer and Next Question]
    quiz_next --> quiz_ask

    quiz_check -->|no| quiz_review[Mentor Review]
    quiz_review --> quiz_save[Save Report and Metrics]
    quiz_save --> quiz_finish[Finish Step]
```

### 3. Algo interview subgraph

Назначение:
- проведение алгоритмического интервью
- управление задачей, попытками решения и проверкой через sandbox
- передача результатов в режим разбора

Особенности:
- работает в роли `interviewer`
- вызывает [`Algo Sandbox`](diagrams/container.md)
- использует retrieval по fixed problem bank и прогрессу
- после завершения может передавать управление роли `mentor`

```mermaid
flowchart TD
    algo_start[Start] --> algo_select[Select Problem and Context]
    algo_select --> algo_present[Present Problem]
    algo_present --> algo_submit[Receive Code Submission]
    algo_submit --> algo_run[Run Sandbox Tests]
    algo_run --> algo_check{Finished}

    algo_check -->|no| algo_feedback[Return Test Feedback]
    algo_feedback --> algo_submit

    algo_check -->|yes| algo_review[Mentor Review]
    algo_review --> algo_save[Save Report and Metrics]
    algo_save --> algo_finish[Finish Step]
```

### 4. Shared retrieval subgraph

Назначение:
- единая точка подготовки поискового и справочного контекста
- выбор нужного retrieval path в зависимости от сценария
- возврат нормализованного retrieval snapshot

Особенности:
- используется supervisor и сценарными подграфами
- не принимает продуктовые решения
- возвращает подготовленные ссылки на контекст, а не финальный пользовательский ответ

```mermaid
flowchart TD
    ret_start[Start] --> ret_route{Retrieval Route}
    ret_route --> ret_notes[Load Notes and Tags]
    ret_route --> ret_progress[Load Progress Artifacts]
    ret_route --> ret_problems[Load Problem Bank]
    ret_route --> ret_web[Load Web Sources]

    ret_notes --> ret_pack[Build Retrieval Snapshot]
    ret_progress --> ret_pack
    ret_problems --> ret_pack
    ret_web --> ret_pack

    ret_pack --> ret_return[Return Context Refs]
```

## State graph

Ниже показан верхнеуровневый граф состояний выполнения агента.

```mermaid
flowchart TD
    start[Start] --> receive[Receive User Request]
    receive --> classify[Classify Intent and Role]
    classify --> retrieve{Need Retrieval}

    retrieve -->|yes| retrieval[Run Shared Retrieval]
    retrieve -->|no| route[Route to Subgraph]
    retrieval --> route

    route --> note[Note Workflow]
    route --> quiz[Quiz Workflow]
    route --> algo[Algo Interview Workflow]

    note --> confirm{Need Confirm}
    quiz --> progress{Finished}
    algo --> progress

    confirm -->|yes| await[Await Confirmation]
    confirm -->|no| respond[Respond to User]
    await --> execute[Execute Tool Action]
    execute --> respond

    progress -->|no| respond
    progress -->|yes| mentor[Mentor Review]
    mentor --> respond

    respond --> finish[Finish Step]
    route --> defer[Deferred AI Work]
    defer --> finish
```

Этот граф показывает:
- вход пользовательского запроса
- классификацию намерения и роли
- условный запуск retrieval
- выбор подграфа
- ветку confirmation для note workflows
- ветку mentor review после завершения quiz или algo flow
- ветку deferred AI work при невозможности завершить шаг синхронно

## Open questions

| ID | Вопрос |
|---|---|
| AQ-001 | Насколько supervisor должен быть rule-based, а насколько LLM-driven |
| AQ-002 | Нужно ли уже в первой реализации выделять отдельный mentor subgraph, или достаточно role handoff внутри quiz and algo flows |
| AQ-003 | Где проходит точная граница между subgraph state и persistent session state |
| AQ-004 | Нужен ли единый internal handoff contract для всех подграфов |
| AQ-005 | Нужно ли выделять shared retrieval как самостоятельный LangGraph subgraph или достаточно отдельного orchestration path |

## Примечания
- документ описывает архитектуру агента как отдельный слой поверх [`docs/system-design.md`](system-design.md) и [`docs/diagrams/component.md`](diagrams/component.md)
- диаграмма [`docs/diagrams/component.md`](diagrams/component.md) показывает структуру контейнера `Agent System`
- граф состояний и подграфы в этом документе показывают логику работы агента на уровне LangGraph

# Согласование документа `agent-architecture`

## Цель
Подготовить структуру и scope для отдельного документа [`docs/agent-architecture.md`](docs/agent-architecture.md), в котором будет описана именно архитектура агента и его графы, без дублирования общей системной архитектуры из [`docs/system-design.md`](docs/system-design.md).

## Основа для проектирования
При подготовке документа можно ориентироваться на следующие референсы:
- [`agent_documentation.md`](../lifelong_learning_assistant/agent_service/docs/agent_documentation.md:1)
- [`project_architecture.md`](../lifelong_learning_assistant/agent_service/docs/project_architecture.md:1)

## Согласованная структура документа
Документ [`docs/agent-architecture.md`](docs/agent-architecture.md) будет включать разделы:
1. `overview`
2. `supervisor graph`
3. `role model`
4. `scoped state`
5. `subgraphs`
6. `state graph`
7. `open questions`

## Предлагаемое содержание разделов

### 1. Overview
Кратко фиксируем:
- зачем в проекте нужен отдельный agent architecture document
- что агент строится на LangGraph
- что агентная архитектура отделена от общей системной архитектуры
- что документ описывает внутреннюю организацию `Agent System`

### 2. Supervisor graph
В этом разделе предлагается описать верхнеуровневый граф-оркестратор агента:
- вход пользовательского сообщения
- supervisor or router node
- выбор сценария или подграфа
- возврат управления в supervisor
- связь с общей памятью и состоянием

Здесь же можно вставить первую Mermaid-диаграмму верхнего уровня.

### 3. Role model
В этом разделе предлагается зафиксировать:
- роли `assistant`, `interviewer`, `mentor`
- чем различаются их системные инструкции, ограничения и доступ к инструментам
- какие роли могут вызывать какие ветки поведения
- какие guardrails обязательны для `interviewer`

### 4. Scoped state
В этом разделе предлагается описать модель состояния:
- глобальное состояние агента
- локальное состояние подграфов
- memory policy
- как передаются данные между supervisor и подграфами
- как хранятся `pending confirmation`, snapshot refs и session progress

### 5. Subgraphs
В этом разделе предлагается зафиксировать подграфы агента как самостоятельные архитектурные единицы.

Предварительно предполагаются такие подграфы:
- note workflow subgraph
- quiz workflow subgraph
- algo interview workflow subgraph
- shared retrieval subgraph

Для каждого подграфа стоит описать:
- назначение
- входы и выходы
- связь с supervisor
- какие инструменты и память доступны

### 6. State graph
Это отдельный раздел специально для графа выполнения агента.

Здесь предлагается показывать:
- основные состояния выполнения
- переходы между ними
- ветки confirmation
- ветки tool execution
- ветки degradation and deferred mode
- возвраты из подграфов к supervisor

Важно: именно сюда выносим логические вершины и переходы, а не в [`docs/diagrams/component.md`](docs/diagrams/component.md).

### 7. Open questions
В этот раздел предлагаем вынести ещё незафиксированные архитектурные решения, например:
- насколько supervisor должен быть rule-based или LLM-driven
- какие подграфы действительно нужны в первой реализации
- где проходит граница между graph state и persistent session state
- как именно моделировать handoff между `interviewer` и `mentor`

## Принципы документа
- не дублировать уже описанную контейнерную и компонентную архитектуру
- не смешивать структурную архитектуру контейнера и граф состояний агента
- описывать agent architecture как отдельный слой поверх [`docs/diagrams/component.md`](docs/diagrams/component.md) и [`docs/specs/orchestrator.md`](docs/specs/orchestrator.md)
- делать Mermaid-диаграммы максимально читаемыми и, при необходимости, разбивать их на несколько

## Следующий шаг
После согласования этого черновика следующим шагом можно создать сам документ [`docs/agent-architecture.md`](docs/agent-architecture.md) и начать заполнять его разделы сверху вниз, начиная с `overview` и `supervisor graph`.

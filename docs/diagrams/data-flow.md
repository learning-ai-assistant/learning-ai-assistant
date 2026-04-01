# Диаграмма: Data Flow

Диаграмма показывает движение данных между пользовательским запросом, orchestration-слоем, LLM, инструментами и хранилищами. Логические границы описаны в [`docs/system-design.md`](../system-design.md), а telemetry-контур — в [`docs/specs/observability-evals.md`](../specs/observability-evals.md).

```mermaid
flowchart LR
    user[User input]
    api[Backend API]
    orch[Session Orchestrator]
    memory[Memory Service]
    retrieval[Retrieval Service]
    snapshot[Retrieval Snapshot]
    llm[LLM Gateway]
    plan[Tool Plan or Response]
    tools[Tool Layer]
    vault[Obsidian Vault]
    reports[Markdown Reports]
    metrics[Metrics Store]
    jobs[Deferred Jobs]
    obs[Telemetry and Evals]

    user --> api --> orch
    orch --> memory
    orch --> retrieval --> snapshot --> orch
    orch --> llm --> plan --> orch
    orch --> tools
    tools --> vault
    tools --> reports
    tools --> metrics
    orch --> jobs
    orch --> obs
    llm --> obs
    retrieval --> obs
    tools --> obs
    reports --> obs
    metrics --> obs
```

## Что важно
- `Retrieval Snapshot` выступает отдельным артефактом между retrieval и reasoning.
- `Tool Plan or Response` отделяет LLM reasoning от фактического исполнения.
- `Deferred Jobs` позволяют сохранить continuity сценария при сбое внешней LLM.
- Telemetry собирается из всех ключевых слоёв, но не должна хранить лишний пользовательский контент.

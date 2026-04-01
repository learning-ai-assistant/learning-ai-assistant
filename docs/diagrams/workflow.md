# Диаграмма: Workflow

Диаграмма показывает общий workflow обработки пользовательского запроса с ветвями подтверждения, деградации и ошибок. Детали состояний описаны в [`docs/specs/orchestrator.md`](../specs/orchestrator.md).

```mermaid
flowchart TD
    start[User request]
    api[Backend API validate]
    route[Intent and role routing]
    context[Build context bundle]
    needret{Need retrieval}
    retrieve[Create retrieval snapshot]
    needllm{Need LLM step}
    llm[Call LLM Gateway]
    plan[Build tool or response plan]
    risky{Risky action}
    preview[Show preview]
    confirm{User confirm}
    tool[Execute tool]
    done[Return response]
    defer[Create deferred AI work]
    blocked[Safe refusal or blocked response]

    start --> api --> route --> context --> needret
    needret -->|yes| retrieve --> needllm
    needret -->|no| needllm
    needllm -->|yes| llm --> plan
    needllm -->|no| plan
    llm -->|provider failure| defer
    plan --> risky
    risky -->|yes| preview --> confirm
    confirm -->|yes| tool --> done
    confirm -->|no| blocked
    risky -->|no| done
    tool -->|tool failure| blocked
    defer --> done
```

## Что важно
- Retrieval и LLM являются условными шагами, а не обязательными для каждого запроса.
- Любой risky action проходит через preview и подтверждение.
- При сбое LLM шаг не обязан завершаться полной ошибкой: возможен deferred режим.
- Ошибки исполнения переводятся в управляемый blocked response, а не в неявное поведение.

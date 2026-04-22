# Git Context

## Root repository

- Root repository path: `./`
- Role: primary repository for product code, project documentation, migration work и durable project context `learning-ai-assistant`.

## Nested repositories

### `services/*`

- Path: `services/agent_service/`, `services/rag/`, `services/test_generator/`, `services/user_service/`, `services/web_ui_service/`
- Role: product services imported as standalone nested git repositories instead of git submodules in the root runtime layout.
- Git behavior: changes inside each service must be reviewed and committed in that service's own git context.

### `.kilo/`

- Path: `.kilo/`
- Role: runtime/config repository нового Kilo для project-local rules, agents и related artifacts.
- Git behavior: если изменения сделаны внутри `.kilo/`, git commands должны выполняться внутри `.kilo/`.

### `sot_layers/hyper-graph/assets/rules/`

- Path: `sot_layers/hyper-graph/assets/rules/`
- Role: отдельный nested repository reference rule assets.
- Git behavior: изменения внутри этого каталога должны коммититься в его собственном Git context.

## Related entry points

- [`repository-map.md`](repository-map.md) для top-level navigation.
- [`context-migration.md`](context-migration.md) для migration state.

## Working rules

- Run git commands in the repository that owns the changed files.
- Не смешивай root-repo changes, `.kilo/` changes и changes в nested methodology repos в одном git context.
- Не выполнять `git push`.
- Держать commits атомарными внутри каждого repository boundary.

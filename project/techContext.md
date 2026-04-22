# Technical Context

## Core stack

- Primary language: Python 3.13+.
- Project manifest: `pyproject.toml`.
- Runtime/config for agent system: `.kilo/`.

## Main technical areas

- `docs/` содержит long-lived engineering documentation.
- `operational_scope/` содержит execution-layer artifacts.
- `sot_layers/` содержит methodology и reference assets, не являющиеся local engineering SoT root-проекта.
- `.kilo/` содержит project-local Kilo runtime artifacts.

## Environment assumptions

- Primary development environment: Linux.
- Repository layout includes multiple nested git repositories.
- Project combines product artifacts и methodology/reference artifacts в одной workspace.

## External dependencies

- LLM provider APIs.
- Web search integration.
- User Obsidian vault.
- Docker sandbox для code execution scenarios.

## Important conventions

- Architecture, contracts и durable technical decisions должны жить в `docs/`.
- Durable repository context должен жить в `project/`.
- Temporary execution context должен жить в `operational_scope/` после migration rename.
- Comments, docstrings, identifiers и commit messages в code остаются на English.

## Related entry points

- [`overview.md`](overview.md) для product frame.
- [`entry-points.md`](entry-points.md) для ownership split между слоями.

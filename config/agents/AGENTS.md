# AGENTS.md

## Conversation Guidelines

- Always respond in Japanese
- When asked to generate code, explain and present only the changed parts clearly
- When unsure about facts or behavior, verify before asserting.

## Editing Rules

- Always read the target file before editing it.
- Check related files (tests, type definitions, callers) before editing.
- Prefer diff-style edits over rewriting whole files.

## Code Style Guidelines

- Do not write obvious code comments
- Remove unnecessary whitespace
- Always add a trailing newline when creating new files

## Preferred Tools

Use these tools instead of their standard alternatives:

| Tool        | Replaces | Description         |
| ----------- | -------- | ------------------- |
| `zsh`       | bash     | Shell               |
| `rg`        | grep     | Fast search         |
| `fd`        | find     | File finder         |
| `bat`       | cat      | Syntax highlighting |
| `eza`       | ls       | Git-aware listing   |
| `trash`     | rm       | Trash CLI (macOS)   |
| `trash-put` | rm       | Trash CLI (Linux)   |
| `jq`        | -        | JSON processor      |
| `gh`        | git      | GitHub CLI          |

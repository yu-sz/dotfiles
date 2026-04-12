# CLAUDE.md

## Conversation Guidelines

- Always respond in Japanese
- When asked to generate code, explain and present only the changed parts clearly
- When unsure about facts or behavior, verify before asserting.

## Editing Rules

- Always read the target file before editing it.
- Check related files (tests, type definitions, callers) before editing.
- Prioritize Edit (diff editing) over Write (overwriting the entire file).

## Code Style Guidelines

- Do not write obvious code comments
- Remove unnecessary whitespace
- Always add a trailing newline when creating new files

## Code Navigation

- Use LSP tools (goToDefinition, findReferences, documentSymbol, workspaceSymbol) for symbol search and reference lookup
- Before renaming or changing a function signature, use findReferences to find all call sites first
- Use Grep only for plain text search or when LSP is unavailable for the file type

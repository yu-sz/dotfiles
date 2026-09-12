# CLAUDE.md

@~/.config/agents/AGENTS.md

## Claude Code

### Code Navigation

- Use LSP tools (goToDefinition, findReferences, documentSymbol, workspaceSymbol) for symbol search and reference lookup
- Before renaming or changing a function signature, use findReferences to find all call sites first
- Use Grep only for plain text search or when LSP is unavailable for the file type

---
name: lua-review
description: Review uncommitted Lua changes using Neovim coding standards
allowed-tools: "Bash(git diff:*), Bash(git status:*), Read, Grep"
disable-model-invocation: true
---

# Lua Code Review

Review uncommitted changes (`git diff`) against Lua/Neovim coding standards.

## Steps

1. Run `git diff` to get changes
2. For Lua files (\*.lua), apply lua-standard Skill
3. Report issues based on Review Checklist

## Output Format

For each issue:

- file_path:line_number
- Issue type (Scoping / Type Annotation / Naming / API Usage / Error Handling)
- Recommended fix

---
allowed-tools: "Bash(git diff:*), Bash(git status:*), Read, Grep"
description: Review uncommitted changes using project standards
---

# Code Review

Review uncommitted changes (`git diff`) against project standards.

## Steps

1. Run `git diff` to get changes
2. For TypeScript files (_.ts/_.tsx), apply typescript-standard Skill
3. Report issues based on Review Checklist

## Output Format

For each issue:

- file_path:line_number
- Issue type
- Recommended fix

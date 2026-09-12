---
name: review-diff
description: "Execute structured code review"
argument-hint: "[--staged | --all | --base <branch> | PR# | commit | branch]"
context: fork
agent: reviewer
disable-model-invocation: true
---

# /review-diff - Code Review Command

Execute code review for PR or local changes using `reviewer` agent.

## Arguments

| Pattern           | Type        | Command                           |
| ----------------- | ----------- | --------------------------------- |
| (empty)           | no args     | `git diff HEAD`                   |
| `--staged`        | flag        | `git diff --staged`               |
| `--all`           | flag        | `git status --porcelain` + Read   |
| `--base <branch>` | base branch | `git diff <branch>...HEAD`        |
| digits only       | PR number   | `gh pr diff <number>`             |
| 40-char hex       | commit hash | `git show <hash>`                 |
| other             | branch name | `git diff origin/main...<branch>` |

## Target

$ARGUMENTS

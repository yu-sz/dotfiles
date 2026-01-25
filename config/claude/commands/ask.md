---
description: "Conduct an interview before starting work to align understanding, then execute"
argument-hint: "[task description]"
---

# /ask - Interactive Task Execution Command

Use this for small tasks that don't require plan mode.
Conduct an interview before starting work to prevent misunderstandings.

---

## [1/3] Interview

### Getting Task Description

- If `$ARGUMENTS` exists: use as-is
- If `$ARGUMENTS` is empty: ask "どのようなタスクを実行しますか？"

### Generating Questions

Analyze the task and generate questions to prevent misunderstandings.

**Important Rules**:

- Limit to 1-3 questions
- Don't ask obvious things
- Be specific ("Xについてどうしますか？" not "何かありますか？")

**When questions are unnecessary**:
If the task is clear enough, skip to [2/3].

### Example

Task: "このバグを修正して"

AskUserQuestion:

- question: "バグの再現手順や期待される動作を教えてください"
- header: "バグ詳細"
- options: "手順を説明", "期待動作を説明"

---

## [2/3] Confirmation

Summarize the interview results and request user approval.

### Summary Format

```
## タスク概要

**依頼内容**: [ユーザーが依頼した内容]

**実行する作業**:
- [具体的な作業1]
- [具体的な作業2]

**スコープ**: [対象ファイル/機能]

**制約・注意点**: [あれば記載]
```

### Approval Confirmation

AskUserQuestion:

- question: "上記の内容で作業を開始してよろしいですか？"
- header: "確認"
- options: "実行"（作業を開始する）, "修正が必要"（内容を修正する）

**If "実行"**: proceed to [3/3]
**If "修正が必要" or "Other"**: return to [1/3] for re-interview

---

## [3/3] Execution

Execute the task after approval.

**Task Management**: Use TodoWrite for multi-step tasks

**Execution Notes**:

- Work within the approved scope
- Don't make out-of-scope changes
- Use AskUserQuestion if additional decisions are needed

### Completion Report

Report results concisely after completion:

```
## 完了報告

**実行した作業**:
- [作業1]
- [作業2]

**変更ファイル**:
- [ファイルパス1]
- [ファイルパス2]
```

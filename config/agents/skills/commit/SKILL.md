---
name: commit
description: "Git commit message rules based on Conventional Commits. Use when: creating git commits. MUST load before creating any commit — never commit without this skill."
user-invocable: false
context: fork
model: sonnet
background: false
---

# Commit Message Rules

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) に従う。

## Format

```text
<type>(<scope>): <description>
```

## Types

| type       | 用途                                                              |
| ---------- | ----------------------------------------------------------------- |
| `feat`     | 新機能・新設定の追加                                              |
| `fix`      | バグ修正                                                          |
| `refactor` | 動作変更なしのコード再構成                                        |
| `docs`     | ドキュメントのみの変更（SKILL.md には使わない → 変更性質の type） |
| `style`    | フォーマット等、意味の変更なし                                    |
| `chore`    | メンテナンス（依存更新、不要ファイル削除等）                      |
| `revert`   | 以前のコミットの取り消し                                          |
| `ci`       | CI/CD 設定の変更                                                  |
| `perf`     | パフォーマンス改善                                                |

## Rules

- 言語は原則英語
- body は書かない（1 行目で完結させる）
- description: 命令形・小文字開始・末尾ピリオドなし・50 字以下
- 1 コミット = 1 つの論理的変更（description に `and` が出るなら分割）
- scope: トップレベルのコンポーネント名 1 語（小文字、サブパスまで掘らない）。複数領域にまたがる場合や自明な場合は省略可
- SKILL.md は Claude の挙動を規定するため、テキスト変更でも `docs` 扱いせず変更性質に応じた type を使う

## Workflow

1. `git status` と `git diff` で変更を把握する。呼び出し時の指示があればそれに従い、なければ tracked ファイルの変更から自分でコミット単位を判断する。untracked ファイルは明示的に指示された場合のみ対象にする
2. `git log --oneline -20` および `git log --follow -- <対象パス>` で、既存の scope 名とコミット慣習を確認する
3. type を Types テーブルと照合する。挙動・設定内容が変わる変更に `refactor` / `style` を使わない
4. Checklist を埋め、コミットを実行する

## Checklist

- [ ] description に `and` が含まれない（含まれるならコミット分割）
- [ ] scope が既存ログの scope 名と一致している（同じ対象に別名を作らない）
- [ ] SKILL.md 変更の type は変更性質を反映している

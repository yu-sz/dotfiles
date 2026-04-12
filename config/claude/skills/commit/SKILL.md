---
name: commit
description: "Git commit message rules based on Conventional Commits. Use when: creating git commits. MUST load before creating any commit — never commit without this skill."
user-invocable: false
---

# Commit Message Rules

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) ベース。

## Format

```text
<type>(<scope>): <description>

[body]
```

## Rules

- **description**: 命令形、小文字開始、末尾ピリオドなし、50文字以下
- **body**: description だけでは動機が伝わらない場合に「なぜ」を端的に書く（空行で区切る、72文字折り返し）
  - diff を見ればわかる「何を変えたか」は書かない
  - e.g. revert reason, migration/deletion background, technical tradeoffs, bug root cause
- **1コミット = 1つの論理的変更**（`and` が出たら分割を検討）

## Types

| type       | 用途                                         |
| ---------- | -------------------------------------------- |
| `feat`     | 新機能・新設定の追加                         |
| `fix`      | バグ修正                                     |
| `refactor` | 動作変更なしのコード再構成                   |
| `docs`     | ドキュメントのみの変更                       |
| `style`    | フォーマット等、意味の変更なし               |
| `chore`    | メンテナンス（依存更新、不要ファイル削除等） |
| `revert`   | 以前のコミットの取り消し                     |
| `ci`       | CI/CD 設定の変更                             |
| `perf`     | パフォーマンス改善                           |

## Scope

- 変更の影響範囲を端的に示す名前を使う（モジュール名、パッケージ名、ディレクトリ名等）
- 複数領域にまたがる場合や自明な場合は省略可
- プロジェクトの既存コミットログの慣習に従う

## Anti-patterns

- `and` で繋ぐ → コミットを分割
- ファイル名の羅列 → 意味的な変更内容を書く
- 「why」なしの大きな変更 → body で動機を説明

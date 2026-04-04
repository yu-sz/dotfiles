---
name: execute-plan
description: "Execute implementation following Plans document checklists. Use when: starting implementation of a Plans document. TRIGGER when user mentions 計画を実行, Plan 実行, Phase 実行, or references a Plans document for implementation."
argument-hint: "[plans file path]"
---

# 計画実行スキル

Plans ドキュメントのチェックリストに従い、進捗と予実を記録しながら実装を実行する。

## 起動

- `$ARGUMENTS` があればそのファイルを Plans として読み込む
- なければ `docs/plans/` から該当ファイルを探すか、ユーザーに確認する

## ルール

### チェックリスト駆動

- Plans の `- [ ] N-M: タスク` を作業単位とする
- 各タスク完了時に即座に Plans ファイルの該当行を `- [x]` に更新し、実行結果の要点を括弧で追記する

### コミット

- Phase 完了時にその Phase の変更をまとめてコミットする

### 予実差異の記録

- Phase 完了時に計画と実際の差異を Plans ファイルに記録する
- 差異がない場合は「予実差異なし」と明記する
- フォーマットは [PLANS_FORMAT.md](../writing-adr-plans/PLANS_FORMAT.md) の「予実差異」セクションに従う

## 実行フロー

1. **計画確認**: Plans を読み、未完了項目と Phase 依存関係を把握してユーザーに提示
2. **Phase 実行**: チェックリスト項目を順に実行し、完了ごとに即時更新。ユーザー操作が必要な場合は明確に指示
3. **完了報告**: 全 Phase 完了後、変更ファイル一覧を提示しコミットするか確認

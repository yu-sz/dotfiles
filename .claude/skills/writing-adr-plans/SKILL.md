---
name: writing-adr-plans
description: "Generates ADR (Architecture Decision Record) and Plans documents for this dotfiles repository. Use when: planning implementation work, recording architecture decisions, or the user asks to create ADR/Plans documents. TRIGGER when user mentions ADR, Plans, 実装計画, or starts a planning phase for code changes."
---

# ADR + Plans ドキュメント生成

計画フェーズの成果物として ADR と Plans を生成する。

## ワークフロー

### Step 1: スコープ判定

基本は ADR + Plans の両方を作成する。ADR はワンイシュー（1つの判断に1つの ADR）。複数施策がある場合、ADR は施策ごとに分け、Plans は1本にまとめる。

スコープが確定したら「ADR N本 + Plans 1本を作成します」とユーザーに提示し、AskUserQuestion で確認する。

### Step 2: 質問フェーズ

書き始める前に不明点を洗い出す。ADR 観点と Plans 観点でそれぞれ AskUserQuestion を実行する。明らかな点は聞かない。

ADR 観点（最大4問）:

- **Context**: 何が問題か、なぜ今この判断が必要か
- **選択肢**: 比較対象は何か、重視する観点は何か
- **決定の方向性**: すでに心が決まっているか、フラットに比較すべきか
- **スコープ**: 1つの ADR にまとめるか、施策ごとに分けるか

Plans 観点（最大4問）:

- **実装順序**: Phase の分け方、依存関係
- **設計の曖昧さ**: コード上の選択肢が複数ある箇所
- **エイリアス・命名**: 既存の命名規則との整合性
- **検証方法・影響範囲**: 確認手段、ドキュメント（CLAUDE.md 等）への波及

ADR の結論次第で Plans の設計が大きく変わる場合のみ、Plans 作成前に追加質問する。

### Step 3: ADR 作成

ADR を作成する場合のみ。フォーマットは [ADR_FORMAT.md](ADR_FORMAT.md) を参照。

構成:

1. **H1 タイトル** + Date + Status メタデータ
2. **## Context** — 問題・状況・制約
3. **## Decision** — 比較表 + 根拠（外部リンクで裏付け）
4. **## Consequences** — 結果・影響のリスト

ADR は「なぜその判断をしたか」の記録。簡潔さを最優先し、実装詳細は書かない。冗長な説明より比較表と箇条書きで伝える。

### Step 4: Plans 作成

フォーマットは [PLANS_FORMAT.md](PLANS_FORMAT.md) を参照。

構成:

1. **H1 タイトル + 「実装計画」**
2. **## 概要** — 施策の箇条書き + ADR 出典リンク
3. **## 決定事項** — 3列テーブル（項目・決定・備考）
4. **## 設計: [名前]** — コピペ可能なコード完成形（複数可）
5. **## 実装手順** — Phase 分割 + チェックリスト `- [ ] N-M: タスク`
6. **## 変更対象ファイル一覧** — Phase 横断のテーブル

## ファイル命名

```
docs/adr/YYYY-MM-DD-slug-kebab-case.md
docs/plans/YYYY-MM-DD-slug-kebab-case.md
```

## 文体ルール

- 日本語主体、技術用語・固有名詞は英語のまま
- 決定の動詞: `〜を採用する`, `〜に移行する`, `〜を削除する`
- Status 値:

  | Status                 | 意味                                    |
  | ---------------------- | --------------------------------------- |
  | `Accepted`             | 有効な決定                              |
  | `Partially Superseded` | 一部が後の ADR や Addendum で変更された |
  | `Superseded`           | 決定全体が別の ADR に置き換えられた     |

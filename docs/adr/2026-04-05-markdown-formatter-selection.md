# Markdown フォーマッター選定

Date: 2026-04-05
Status: Accepted

## Context

dotfiles の pre-commit に Markdown のチェックがない。フォーマッターとリンターの導入を検討したが、Markdown の標準規格（CommonMark）はパースの仕様のみ定義しており「どう書くべきか（フォーマット）」の正規形はない。この状況でフォーマッターを選定する必要がある。

## Decision

### フォーマッター比較

| 観点              | prettier                                        | mdformat                                                                       | dprint                                                                                                     |
| ----------------- | ----------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ★                 | 51,726                                          | 751                                                                            | 3,863 (MD プラグイン ★49)                                                                                  |
| ランタイム        | Node.js                                         | Python                                                                         | Rust                                                                                                       |
| メンテナー        | 多数                                            | **1人 (バスファクター1)**                                                      | **1人 (バスファクター1)**                                                                                  |
| データ損失バグ    | 稀                                              | **あり** ([#414](https://github.com/hukkin/mdformat/issues/414) alt text 消失) | **あり** ([#37](https://github.com/dprint/dprint-plugin-markdown/issues/37) テーブルセル消失、5年間未修正) |
| CommonMark 準拠   | 不完全 (remark-parse v8.x)                      | 完全                                                                           | prettier 互換                                                                                              |
| Neovim デファクト | **LazyVim デフォルト**, conform.nvim 公式レシピ | Mason 未対応                                                                   | 対応あり                                                                                                   |
| 開発状況          | アクティブ                                      | **2025-10 以降停滞**                                                           | アクティブ                                                                                                 |

### 決定: prettier を維持する

- mdformat, dprint はいずれもバスファクター1 + データ損失バグが未修正。本番運用のフォーマッターとしてリスクが高い
- prettier は Neovim の事実上の標準（[LazyVim デフォルト](https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lang/markdown.lua)、[conform.nvim 公式レシピ](https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md)）
- Node.js 依存は妥協点だが、[ADR: Mason 全廃と Nix 一本化](./2026-04-05-mason-to-nix-migration.md) により Nix で管理するため運用上の問題はない
- リンターとして markdownlint を pre-commit に追加し構造チェックを担保する。markdownlint は成熟 (★5,971, [GitHub 社が採用](https://github.com/github/markdownlint-github))

### リンター選定

| 観点          | markdownlint-cli         | markdownlint-cli2     | rumdl          |
| ------------- | ------------------------ | --------------------- | -------------- |
| git-hooks.nix | **ビルトインフックあり** | なし (カスタム定義要) | ビルトインあり |
| ルール数      | 53                       | 53 (同一ライブラリ)   | 新興           |
| 採用実績      | 多数                     | GitHub 社             | 少ない         |

→ **ビルトインの markdownlint を採用**。カスタム定義不要でシンプル。

## Consequences

- Markdown の構造チェック（heading 順序、リスト一貫性等）が pre-commit で強制される
- prettier による MD フォーマットも pre-commit で強制される
- 将来 Biome が MD フォーマッター対応（[PR #9693](https://github.com/biomejs/biome/pull/9693) 開発中）すれば、biome-check 一本で JS/TS/MD を統一できる可能性あり

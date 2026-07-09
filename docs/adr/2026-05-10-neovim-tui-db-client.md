# Neovim/TUI DB クライアントの導入とクレデンシャル戦略

Date: 2026-05-10
Status: Accepted

## Context

dotfiles 環境に DB クライアントが整備されておらず、業務で複数環境（prod/staging/dev × 複数アプリ + 分析系）の DB を日常的に切り替える必要がある。

要件:

- 「Neovim 内で SQL 編集→実行」と「TUI で探索」を**両方共存**させる
- 対象 DB は PostgreSQL + SQLite + 分析系 (DuckDB / BigQuery / Snowflake / ClickHouse)
- 接続数 5–15、書き込み含む日常用途、大きい結果セットあり
- クレデンシャルは PC ごとローカル管理（dotfiles リポにも 1Password にも置かない）
- 切替起点は Neovim 起動後の picker（`snacks.nvim` を主軸とした既存 UX に揃える）

## Decision

### Neovim プラグインスタック

| 観点         | dadbod 系                                | nvim-dbee                | dadbod-grip            |
| ------------ | ---------------------------------------- | ------------------------ | ---------------------- |
| 成熟度       | **LazyVim 公認・tpope 系・4.4k★**        | alpha 自称 (v0.1.9/2024) | 新興 (v1.10.0/2026-04) |
| 対応 DB      | 広範 (PG/MySQL/SQLite/BQ/SF/CH/DuckDB他) | 主要 RDBMS + 分析系      | PG/MySQL/SQLite/DuckDB |
| 同期/非同期  | 同期                                     | Go バックエンドで非同期  | 同期                   |
| 補完         | dadbod-completion (blink/nvim-cmp)       | 未対応                   | 未対応                 |
| エコシステム | LazyVim extras に codified               | 大手 distro 採用なし     | 採用例ごく少           |
| 採用判断     | **採用**                                 | 不採用                   | 不採用                 |

- [LazyVim `extras/lang/sql.lua`](https://www.lazyvim.org/extras/lang/sql) が dadbod スタックを公式化
- nvim-dbee は v0.1.9 (2024-07) 以降 release が止まっており書き込み主体の用途には早い
- 同期実行の弱点は LSP 側 (`:SqlsExecuteQuery`) と TUI (harlequin) で迂回する

### LSP

| 観点              | sqls (plain LSP) | nanotee/sqls.nvim          | sqlls  |
| ----------------- | ---------------- | -------------------------- | ------ |
| 補完・hover       | ✅               | ✅                         | ✅     |
| 非同期 query 実行 | ❌               | **✅ `:SqlsExecuteQuery`** | ❌     |
| 接続切替コマンド  | ❌               | **✅ `:SqlsSwitch*`**      | ❌     |
| 採用判断          | 不採用           | **採用**                   | 不採用 |

- [`nanotee/sqls.nvim`](https://github.com/nanotee/sqls.nvim/blob/main/doc/sqls-nvim.txt) が `:SqlsExecuteQuery` を提供、dadbod の同期問題の逃げ道になる
- `pkgs.sqls` は nixpkgs にあり、追加依存は plugin 1 行のみ

### TUI

| 観点           | harlequin                                | lazysql                      | dblab                        | rainfrog        |
| -------------- | ---------------------------------------- | ---------------------------- | ---------------------------- | --------------- |
| 言語           | Python + Textual                         | Go                           | Go                           | Rust            |
| 対応 DB        | **PG/MySQL/SQLite/DuckDB/BQ + 他**       | PG/MySQL/SQLite/MSSQL/Oracle | PG/MySQL/SQLite/Oracle/MSSQL | PG/MySQL/SQLite |
| 分析系         | **DuckDB ネイティブ + BQ/SF/CH adapter** | ❌                           | ❌                           | ❌              |
| URL/env で起動 | ✅                                       | ❌ (config.toml 直書き)      | ✅                           | △               |
| nixpkgs        | **✅ (PG/BQ/DuckDB/SQLite 同梱)**        | ✅                           | ✅                           | ❌              |
| 採用判断       | **採用**                                 | 不採用                       | 不採用                       | 不採用          |

- [`pkgs.harlequin`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ha/harlequin/package.nix) は `withPostgresAdapter` / `withBigQueryAdapter` がデフォ ON、DuckDB/SQLite 同梱
- lazysql は接続情報を `config.toml` 直書きしか受けず、カタログ駆動と相性が悪いため不採用
- dblab は harlequin とスコープ重複するため採用しない
- 既存の `pgcli` は ad-hoc PG REPL として維持

### クレデンシャル管理

| 観点                          | 1Password CLI | direnv 単体 (.envrc) | agenix                | **PC ローカル TOML**        |
| ----------------------------- | ------------- | -------------------- | --------------------- | --------------------------- |
| dotfiles に secret を含めるか | 含めない      | 含めない             | 暗号化して含める      | **含めない**                |
| 多環境カタログ化              | item 一覧で可 | 環境変数の手動切替   | 環境ごと age ファイル | **TOML に列挙**             |
| 設定の集中度                  | クラウド      | プロジェクト散在     | リポ内                | **`~/.config/db-catalog/`** |
| 追加依存                      | 1Password CLI | なし (既存)          | nix module + age 鍵   | **なし**                    |
| 採用判断                      | 不採用        | 不適合               | 不採用                | **採用**                    |

- direnv の `cd` トリガーは「1 プロジェクト = 1 接続」の設計で、5–15 環境のカタログ管理には合わない
- 1Password / agenix は本件のスコープには重く、ユーザー要件「PC ごとローカル管理」と直接合致しない
- TOML を SSOT として Neovim・zsh の双方からパース、`vim.g.dbs` と `db <name>` で同一カタログを参照

### Phase 分割

| Phase                  | スコープ                                                                                            |
| ---------------------- | --------------------------------------------------------------------------------------------------- |
| **Phase 1**            | PG / BigQuery / DuckDB / SQLite。`pkgs.harlequin` 標準 adapter で完結                               |
| **Phase 2** (条件付き) | Snowflake / ClickHouse adapter を nixpkgs overlay で追加。月 5 回以上 fallback で不便を感じたら着手 |

## Consequences

- LazyVim と同等の dadbod スタックが手に入り、エコシステム情報・サンプルが豊富。同期実行の弱点は sqls / harlequin で迂回
- 接続定義が 1 ファイル (TOML) に集中し、Neovim・zsh から同じソースを引く。環境追加が 1 行で済む
- Snowflake / ClickHouse は Phase 1 では `clickhouse-client` / `snowsql` への routing fallback のみ。完全 polyglot は overlay を書くまで保留
- クレデンシャルは平文だが PC ローカル + `chmod 600`。クラウド同期 / マシン間共有は今回スコープ外
- TOML カタログ未配置時は Neovim・zsh ともサイレントに no-op、新規マシンで壊れない
- vim-dadbod-ui の同期実行 + 大きい結果セット問題は workflow ルール（`LIMIT` 強制 + 重い query は harlequin に逃がす）で対処、自動化はしない

実装計画: [Plans: Neovim/TUI DB クライアント](../plans/2026-05-10-neovim-tui-db-client.md)

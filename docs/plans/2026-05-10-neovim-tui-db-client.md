# Neovim/TUI DB クライアント 実装計画

> **状態: Phase 1 完了**（2026-07-10 時点）。Phase 2 (zsh wrapper + カタログ) 以降が未着手。

## 概要

- vim-dadbod + vim-dadbod-ui + vim-dadbod-completion を導入し SQL ファイル編集と実行を Neovim 内で完結させる
- nanotee/sqls.nvim + `pkgs.sqls` を導入し、PG/SQLite の非同期 query 実行 (`:SqlsExecuteQuery`) を提供する。接続情報は catalog から自動注入
- TUI として `pkgs.harlequin` を導入し DuckDB/BigQuery/PG/SQLite を 1 ツールでカバー、既存 `pgcli` は ad-hoc 用に維持
- `~/.config/db-catalog/connections.toml` をローカル SSOT として、Neovim と zsh の双方から yq でパースして同じ接続情報を引く
- `:DBPick` (snacks.picker) と `db <name> [tool]` (zsh function) で Neovim 起動後 / シェル両方の起点を整備
- Phase 1–3 は PG/BQ/DuckDB/SQLite のみ。Snowflake/ClickHouse の harlequin adapter は条件付き Phase 4 (ADR の Phase 2 に対応)

**出典**:

- [ADR: Neovim/TUI DB クライアントの導入とクレデンシャル戦略](../adr/2026-05-10-neovim-tui-db-client.md)

---

## 決定事項

| 項目                     | 決定                                                                     | 備考                                                                                                    |
| ------------------------ | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Neovim プラグイン        | **vim-dadbod + vim-dadbod-ui + vim-dadbod-completion**                   | LazyVim extras 同等構成                                                                                 |
| LSP プラグイン           | **nanotee/sqls.nvim** + `pkgs.sqls`                                      | upstream は sqls-server/sqls (旧 lighttiger2505) でメンテ継続中。現行 main は `vim.lsp.enable` 前提     |
| sqls 接続設定            | **`after/lsp/sqls.lua` で catalog から自動生成**                         | workspace/configuration 経由。sqls は DuckDB/BQ 非対応のため postgres/sqlite エントリのみ変換           |
| TUI                      | **harlequin** (`pkgs.harlequin`)                                         | v2.5.2。PG/BQ adapter デフォルト ON、SQLite/DuckDB はコア同梱                                           |
| 既存ツール               | **`pgcli` を維持**                                                       | PG ad-hoc REPL                                                                                          |
| カタログファイル         | **`~/.config/db-catalog/connections.toml`**, `chmod 600`                 | dotfiles リポ外、PC ローカル                                                                            |
| TOML パーサ (両側)       | **`yq-go` (mikefarah) に一本化**                                         | Neovim は `vim.system` シェルアウト + `vim.json.decode`、zsh は直接。lua-toml vendor は廃止 (未メンテ)  |
| 追加パッケージ           | **harlequin, yq-go, duckdb, sqlite → dev.nix / sqls → lsp-tools.nix**    | `duckdb`/`sqlite3` CLI は dadbod のシェルアウト先。macOS のシステム sqlite3 依存を避け Linux でも動かす |
| picker                   | **`Snacks.picker.pick`**                                                 | `:DBPick` で起動                                                                                        |
| 接続選択時の動作         | **`vim.g.db = url` を更新後 `:DBUI`**                                    | `g:dbs` は startup 時に確定。DBUI は `g:dbs` を初回のみ読む (実行時変更はドロワーで `R`)                |
| blink.cmp 設定の置き場所 | **dadbod プラグイン spec 内 (`per_filetype`/`providers` を deep-merge)** | sql ファイルタイプでは dadbod source を使用 (`lsp` source は含めない。sqls 補完は dadbod と重複のため)  |
| keymap                   | **`<leader>db` (pick), `<leader>du` (UI toggle), `<leader>dd` (Find)**   | `<leader>df` / `<leader>dp` は diffview が使用中のため回避                                              |
| 接続定義不在時の挙動     | **サイレントに no-op、Neovim/zsh とも正常起動**                          | catalog 不在・yq 不在は無言 skip、TOML 構文エラーは `vim.notify` WARN のみで起動継続                    |
| Phase 4 トリガー         | **月 5 回以上、fallback の不便を感じたら overlay 着手**                  | 現時点では着手しない                                                                                    |

---

## 設計: カタログファイル (PC ローカル、リポ外)

```toml
# ~/.config/db-catalog/connections.toml
# chmod 600 必須

[connections.prod-app1]
driver = "postgres"
url = "postgres://user:pass@prod.example.com:5432/app1_prod"

[connections.staging-app1]
driver = "postgres"
host = "staging.example.com"
port = 5432
user = "app1"
password = "secret"
database = "app1_staging"

[connections.analytics-bq]
driver = "bigquery"
project = "my-analytics"

[connections.local-duck]
driver = "duckdb"
path = "~/data/local.duckdb"
```

- `url` 直書きと field 分割の双方を builder で受ける
- builder は URL エンコードを行わない。password 等に URL 特殊文字 (`@` `:` `/` `#` `%`) を含む場合は field 分割ではなく `url` にパーセントエンコード済みで直書きする

## 設計: catalog.lua

```lua
-- config/nvim/lua/db/catalog.lua
local M = {}

local CATALOG_PATH = "~/.config/db-catalog/connections.toml"

---@param conn table
---@return string|nil
local function build_url(conn)
  if conn.url then
    return conn.url
  end
  local d = conn.driver
  if d == "postgres" then
    return string.format(
      "postgres://%s:%s@%s:%d/%s",
      conn.user, conn.password, conn.host, conn.port or 5432, conn.database
    )
  elseif d == "duckdb" then
    return "duckdb:" .. vim.fn.expand(conn.path)
  elseif d == "sqlite" then
    return "sqlite:" .. vim.fn.expand(conn.path)
  elseif d == "bigquery" then
    -- dadbod の bigquery スキームは `bigquery:project[:dataset]` (`//` なし)
    return "bigquery:" .. conn.project
  end
  -- 未知 driver (clickhouse 等 zsh 専用エントリ) は DBUI に出さない
  return nil
end

---@return table|nil
local function parse_catalog()
  local path = vim.fn.expand(CATALOG_PATH)
  if vim.fn.filereadable(path) == 0 or vim.fn.executable("yq") == 0 then
    return nil
  end
  local out = vim.system({ "yq", "-o", "json", "-p", "toml", path }, { text = true }):wait()
  if out.code ~= 0 then
    vim.notify("db-catalog: TOML parse error\n" .. (out.stderr or ""), vim.log.levels.WARN)
    return nil
  end
  local ok, data = pcall(vim.json.decode, out.stdout)
  if not ok then
    vim.notify("db-catalog: JSON decode error", vim.log.levels.WARN)
    return nil
  end
  return data
end

function M.load()
  local data = parse_catalog()
  if not data then
    return
  end
  local dbs = {}
  for name, conn in pairs(data.connections or {}) do
    local url = build_url(conn)
    if url then
      table.insert(dbs, { name = name, url = url, _meta = conn })
    end
  end
  table.sort(dbs, function(a, b)
    return a.name < b.name
  end)
  vim.g.dbs = dbs
end

---sqls 向け接続リスト (sqls は postgres/sqlite のみ対応)
---@return table[]
function M.sqls_connections()
  if not vim.g.dbs then
    M.load()
  end
  local conns = {}
  for _, d in ipairs(vim.g.dbs or {}) do
    local driver = (d._meta or {}).driver
    if driver == "postgres" then
      table.insert(conns, { alias = d.name, driver = "postgresql", dataSourceName = d.url })
    elseif driver == "sqlite" then
      local path = d._meta.path and vim.fn.expand(d._meta.path) or d.url:gsub("^sqlite:", "")
      table.insert(conns, { alias = d.name, driver = "sqlite3", dataSourceName = "file:" .. path })
    end
  end
  return conns
end

return M
```

## 設計: picker.lua

```lua
-- config/nvim/lua/db/picker.lua
local M = {}

function M.pick()
  local items = vim.tbl_map(function(d)
    return { text = d.name, driver = (d._meta or {}).driver or "?", url = d.url }
  end, vim.g.dbs or {})

  Snacks.picker.pick({
    title = "DB Connections",
    items = items,
    format = function(item)
      return {
        { string.format("%-20s ", item.text), "Identifier" },
        { string.format("[%s]", item.driver), "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.g.db = item.url
      vim.cmd("DBUI")
      vim.notify("DB: " .. item.text, vim.log.levels.INFO)
    end,
  })
end

return M
```

dadbod の接続解決はドキュメント上 `w:db` → `t:db` → `b:db` → `$DATABASE_URL` → `g:db` だが、実装 (`autoload/db.vim` の `s:resolve`) では **`g:db` が `$DATABASE_URL` に勝つ** (w → t → b → g → env)。
解決は `:DB` 実行のたびに行われるため、`g:db` の実行時更新は次の `:DB` から即座に有効。DBUI のドロワーは `g:dbs` 全件を表示し `g:db` も 1 エントリとして拾うが、`g:dbs` の読み込みは初回のみでドロワーの `R` (Redraw) まで再読込されない。

## 設計: dadbod プラグイン spec

```lua
-- config/nvim/lua/plugins/dadbod.lua
return {
  {
    "tpope/vim-dadbod",
    cmd = { "DB", "DBUI", "DBUIToggle", "DBUIFindBuffer", "DBUIRenameBuffer" },
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      "kristijanhusak/vim-dadbod-completion",
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_execute_on_save = 0
      require("db.catalog").load()
    end,
    keys = {
      { "<leader>db", function() require("db.picker").pick() end, desc = "DB: pick" },
      { "<leader>du", "<cmd>DBUIToggle<cr>", desc = "DB: UI toggle" },
      { "<leader>dd", "<cmd>DBUIFindBuffer<cr>", desc = "DB: find buffer" },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = { sql = { "snippets", "dadbod", "buffer" } },
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
  },
  {
    "nanotee/sqls.nvim",
    ft = "sql",
  },
}
```

- `init` は startup で実行される (yq シェルアウトは ~15ms、許容)
- sqls.nvim 現行 main は Neovim 0.11+ 前提。`:SqlsExecuteQuery` 等はプラグイン同梱の `lsp/sqls.lua` が定義する on_attach でバッファローカル登録される。`vim.lsp.enable("sqls")` (lsp/init.lua) との組み合わせで動作し、旧 API の `require("sqls").on_attach` は存在しないため呼ばないこと
- `ft = "sql"` の遅延ロードで attach 時に `lsp/sqls.lua` が見つからない場合は `lazy = false` に切り替える (Phase 3-7 で検証)

## 設計: after/lsp/sqls.lua (catalog → sqls 接続ブリッジ)

```lua
-- config/nvim/after/lsp/sqls.lua
return {
  settings = {
    sqls = {
      connections = require("db.catalog").sqls_connections(),
    },
  },
}
```

sqls は接続定義なしでも起動するが、query 実行は `database connection is not open` で失敗し補完もキーワードのみになる。workspace/configuration (sqls 公式パターン) で catalog から接続を注入し、SSOT を維持する。

## 設計: ユーザーコマンド

```lua
-- config/nvim/lua/commands/db.lua
vim.api.nvim_create_user_command("DBPick", function()
  require("db.picker").pick()
end, { desc = "Pick a DB connection from catalog" })
```

```lua
-- config/nvim/lua/commands/init.lua への追加
require("commands.db")
```

## 設計: zsh wrapper

```zsh
# config/zsh/lazy/db.zsh
db() {
  local catalog=~/.config/db-catalog/connections.toml
  local name="${1:?usage: db <name> [tool]}"
  local tool="${2:-}"
  local conn driver url

  # yq は欠損キーで null/exit 0 を返すため -e が必須
  conn=$(yq -e -o json -p toml ".connections.\"$name\"" "$catalog" 2>/dev/null) || {
    echo "db: connection '$name' not found in $catalog" >&2
    return 1
  }
  driver=$(jq -r .driver <<<"$conn")
  url=$(jq -r '.url // empty' <<<"$conn")

  case "$driver" in
    postgres)
      if [[ -z "$url" ]]; then
        local user pass host port db
        user=$(jq -r .user <<<"$conn")
        pass=$(jq -r .password <<<"$conn")
        host=$(jq -r .host <<<"$conn")
        port=$(jq -r '.port // 5432' <<<"$conn")
        db=$(jq -r .database <<<"$conn")
        url="postgres://${user}:${pass}@${host}:${port}/${db}"
      fi
      case "${tool:-pgcli}" in
        pgcli)         pgcli "$url" ;;
        hq|harlequin)  harlequin -a postgres "$url" ;;
        *)             echo "db: unknown tool '$tool'" >&2; return 1 ;;
      esac ;;
    duckdb)
      harlequin -a duckdb "$(jq -r .path <<<"$conn" | sed "s|^~|$HOME|")" ;;
    sqlite)
      harlequin -a sqlite "$(jq -r .path <<<"$conn" | sed "s|^~|$HOME|")" ;;
    bigquery)
      harlequin -a bigquery --project "$(jq -r .project <<<"$conn")" ;;
    clickhouse)
      command -v clickhouse-client >/dev/null || {
        echo "db: clickhouse-client not installed (Phase 4 未着手)" >&2
        return 1
      }
      clickhouse-client --host="$(jq -r .host <<<"$conn")" ;;
    snowflake)
      echo "snowflake: write Phase 4 overlay or configure snowsql" >&2
      return 1 ;;
    *)
      echo "db: unknown driver '$driver'" >&2; return 1 ;;
  esac
}

_db_complete() {
  local catalog=~/.config/db-catalog/connections.toml
  [[ -r "$catalog" ]] || return
  local -a names
  names=("${(@f)$(yq -p toml '.connections | keys | .[]' "$catalog" 2>/dev/null)}")
  compadd -- "${names[@]}"
}
compdef _db_complete db
```

- harlequin の接続文字列は位置引数 (`-P` はプロファイル選択フラグであり不可)
- sheldon は `lazy/*.zsh` を glob で読むため `plugins.toml` の変更は不要。ロード順はアルファベット順で `completion.zsh` (compinit) → `db.zsh` となり `compdef` は利用可能

## 設計: Nix 変更

```nix
# nix/home/packages/dev.nix への追加
duckdb
harlequin
sqlite
yq-go
```

```nix
# nix/home/packages/lsp-tools.nix への追加
sqls
```

```lua
-- config/nvim/lua/lsp/init.lua の servers リストに "sqls" を追加
```

`duckdb` / `sqlite` は dadbod の各アダプタがシェルアウトする CLI (`duckdb`, `sqlite3`)。harlequin は自前ドライバ内蔵のため TUI 側には不要だが、Neovim 経路に必須。

---

## 実装手順

### Phase 1: 基盤 + Neovim スタック

- [x] 1-1: `nix/home/packages/dev.nix` に `duckdb`, `harlequin`, `sqlite`, `yq-go` を追加 (アルファベット順で挿入)
- [x] 1-2: `nix/home/packages/lsp-tools.nix` に `sqls` を追加 (shfmt と stylua の間)
- [x] 1-3: `git add` 後に `! nrs` をユーザーに依頼して反映 (Nix flake は git 追跡ファイルのみ参照)
- [x] 1-4: `which harlequin yq sqls duckdb sqlite3` で導入確認 (全て PATH 解決。yq v4.53.3 mikefarah、harlequin 2.5.2 + duckdb/sqlite/postgres/bigquery アダプタ)
- [x] 1-5: `config/nvim/lua/db/catalog.lua` を作成 (yq シェルアウト版、設計通り)
- [x] 1-6: `config/nvim/lua/db/picker.lua` を作成 (設計通り)
- [x] 1-7: `config/nvim/lua/plugins/dadbod.lua` を作成 (blink.cmp sources 注入含む。`Lazy! install` で 4 プラグイン導入済み)
- [x] 1-8: `config/nvim/lua/commands/db.lua` を作成し `:DBPick` を登録
- [x] 1-9: `config/nvim/lua/commands/init.lua` に `require("commands.db")` を追加
- [x] 1-10: `config/nvim/lua/lsp/init.lua` の servers リストに `"sqls"` を追加
- [x] 1-11: `config/nvim/after/lsp/sqls.lua` を作成 (catalog → sqls 接続ブリッジ)
- [x] 1-12: 新規ファイルを `git add` (stylua --check パス、headless 起動でエラーなし・catalog 不在時 no-op を確認)

> **予実差異**: `commands/init.lua` の既存 require 構成が計画時点と異なっていた (`copy-buffer-name`/`copy-buffer-path` が `copy-buffer` に統合済み)。挿入位置を調整したのみで影響なし。`lazy-lock.json` はこのリポジトリでは gitignore 対象のためコミット対象外。`harlequin --version` 実行時に click の UserWarning (アダプタ間の短縮フラグ重複、upstream 起因) が出るが動作に影響なし。

### Phase 2: zsh wrapper + カタログ整備

- [ ] 2-1: `config/zsh/lazy/db.zsh` を作成 (上記設計通り。`sheldon/plugins.toml` の変更は不要)
- [ ] 2-2: 新規シェル起動で `db` 関数 + 補完が読み込まれることを確認
- [ ] 2-3: `~/.config/db-catalog/` を作成し `chmod 700`
- [ ] 2-4: `connections.toml` を作成し最低 1 件 (例: SQLite ローカル) を記述、`chmod 600`
- [ ] 2-5: `yq -e -o json -p toml '.connections' ~/.config/db-catalog/connections.toml` でパース成功を確認

### Phase 3: 動作検証

- [ ] 3-1: `sqlite3 /tmp/test.sqlite "create table t(id int, name text); insert into t values(1,'a'),(2,'b');"` でテスト DB 作成
- [ ] 3-2: 上記を catalog に `[connections.local-test]` として追加
- [ ] 3-3: Neovim 起動後 `:lua vim.print(vim.g.dbs)` で `local-test` を含むテーブルが返る
- [ ] 3-4: `:DBPick` を実行し snacks picker に `local-test [sqlite]` が表示、選択で `:DBUI` ドロワーが開く
- [ ] 3-5: ドロワーで `t` テーブルを展開、preview に行表示されることを確認 (`sqlite3` CLI 経由)
- [ ] 3-6: `*.sql` バッファで `select * from t where` の直後にスペースを打ち、blink.cmp が `t` の column を補完することを確認 (出ない場合は DBUI の query buffer で再確認)
- [ ] 3-7: `:checkhealth vim.lsp` で sqls の attach を確認し、`:SqlsExecuteQuery` で `select 1;` を実行、preview window に結果が出ることを確認 (コマンドが存在しない場合は sqls.nvim を `lazy = false` に変更して再検証)
- [ ] 3-8: `db local-test` で harlequin 起動、`t` テーブルがカタログに表示されることを確認
- [ ] 3-9: `db <TAB>` で connection 名が補完されることを確認
- [ ] 3-10: `ls -la ~/.config/db-catalog/connections.toml` が `-rw-------` であることを確認
- [ ] 3-11: 一時的に `mv connections.toml connections.toml.bak`、Neovim を起動して `vim.g.dbs` が空でも error なく起動、`db <TAB>` も無補完になるだけで他のシェル機能が壊れないことを確認、戻す
- [ ] 3-12: catalog に故意の TOML 構文エラーを入れ、Neovim が WARN 通知のみで正常起動することを確認、戻す

### Phase 4 (条件付き): Snowflake / ClickHouse overlay

> **トリガー条件**: Phase 3 完了後、`clickhouse-client` / `snowsql` での routing fallback で月 5 回以上不便を感じたら着手

- [ ] 4-1: `nix/overlays/harlequin-extras.nix` で `harlequin-clickhouse` (PyPI v0.1.1、nixpkgs 未収録) を `python3.pkgs.buildPythonPackage` で定義
- [ ] 4-2: Snowflake は `harlequin-snowflake` が PyPI に存在しないため、着手時に `harlequin-adbc[snowflake]` + `adbc-driver-snowflake` の実在と harlequin 対応状況を検証してから定義 (**未検証**)
- [ ] 4-3: `nix/overlays/default.nix` から overlay を統合し `harlequin` に追加 (nixpkgs は textual を 8.2.4 に固定しているため依存整合に注意)
- [ ] 4-4: `db.zsh` の `clickhouse` / `snowflake` ケースを harlequin 呼び出しに切替
- [ ] 4-5: 検証 (Phase 3 同様の手順を SF/CH の catalog エントリで実施)

---

## 変更対象ファイル一覧

| ファイル                                | Phase 1                                         | Phase 2       | Phase 3      | Phase 4 (条件付き)              |
| --------------------------------------- | ----------------------------------------------- | ------------- | ------------ | ------------------------------- |
| `nix/home/packages/dev.nix`             | `duckdb`, `harlequin`, `sqlite`, `yq-go` を追加 | -             | -            | -                               |
| `nix/home/packages/lsp-tools.nix`       | `sqls` を追加                                   | -             | -            | -                               |
| `config/nvim/lua/db/catalog.lua`        | 新規                                            | -             | -            | -                               |
| `config/nvim/lua/db/picker.lua`         | 新規                                            | -             | -            | -                               |
| `config/nvim/lua/plugins/dadbod.lua`    | 新規                                            | -             | -            | -                               |
| `config/nvim/lua/commands/db.lua`       | 新規                                            | -             | -            | -                               |
| `config/nvim/lua/commands/init.lua`     | `require("commands.db")` を追加                 | -             | -            | -                               |
| `config/nvim/lua/lsp/init.lua`          | servers リストに `"sqls"` を追加                | -             | -            | -                               |
| `config/nvim/after/lsp/sqls.lua`        | 新規 (catalog → sqls 接続ブリッジ)              | -             | -            | -                               |
| `config/zsh/lazy/db.zsh`                | -                                               | 新規          | -            | clickhouse/snowflake ケース更新 |
| `~/.config/db-catalog/connections.toml` | -                                               | 新規 (リポ外) | エントリ追加 | -                               |
| `nix/overlays/harlequin-extras.nix`     | -                                               | -             | -            | 新規                            |
| `nix/overlays/default.nix`              | -                                               | -             | -            | overlay 統合                    |

## 実現可能性レビュー

2026-07-07 に一次ソース (各リポジトリのソースコード・nixpkgs・PyPI) とリポジトリ実コードに対して全面検証済み。

| 懸念                                                            | 検証結果       | 根拠                                                                                                                             |
| --------------------------------------------------------------- | -------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `Snacks.picker.pick` のカスタム items / format / confirm の API | 利用可能       | snacks.nvim docs/picker.md。リポジトリで picker 有効・`Snacks` グローバル利用中                                                  |
| `pkgs.harlequin` で PG/BQ/DuckDB/SQLite が箱出しで動くか        | 動く           | nixpkgs v2.5.2: `withPostgresAdapter`/`withBigQueryAdapter ? true`、SQLite/DuckDB はコア同梱                                     |
| `pkgs.sqls` の存在とメンテ状況                                  | 存在・現役     | nixpkgs v0.2.45。upstream は sqls-server/sqls に移管済みで 2026-05 も commit あり。**対応 DB に DuckDB/BQ は含まれない**         |
| harlequin への接続文字列の渡し方                                | 位置引数       | `cli.py` で `conn_str` は positional。**`-P` はプロファイル選択フラグ** (旧版の `-P "$url"` 記載は誤りだったため修正済み)        |
| harlequin BigQuery adapter のフラグ                             | `--project`    | joshtemple/harlequin-bigquery `cli_options.py`。認証は Application Default Credentials                                           |
| `yq-go` で TOML→JSON 変換                                       | 可能           | v4.33.1+ で `-p toml` 対応。**欠損キーは null/exit 0 のため `-e` 必須** (旧版のエラーハンドリングは機能しなかったため修正済み)   |
| dadbod のアダプタと URL スキーム                                | 全対象あり     | postgresql/sqlite/duckdb/bigquery/clickhouse すべて存在。**BQ は `bigquery:project` (`//` なし)**、CLI は psql/sqlite3/duckdb/bq |
| `vim.g.db` 更新で `:DB` が同一接続を参照するか                  | する           | `s:resolve` は `:DB` ごとに評価。実装上の優先順は w → t → b → **g:db → $DATABASE_URL** (doc の記載と env の位置が逆)             |
| `g:dbs` の list-of-dicts + 余分キー (`_meta`)                   | 問題なし       | dadbod-ui は `name`/`url` のみ参照。ただし **`g:dbs` の読込は初回のみ**、実行時変更はドロワーの `R` まで反映されない             |
| blink.cmp source モジュールパス                                 | 正しい         | vim-dadbod-completion README: `module = "vim_dadbod_completion.blink"`。既存 blink spec とは新規キーのため deep-merge で衝突なし |
| sqls.nvim の現行 API                                            | 要注意→対応済  | main は Neovim 0.11+ / `vim.lsp.enable` 前提、旧 `require("sqls").on_attach` は削除済み。**接続設定なしでは query 実行不可**     |
| 空の `after/lsp/sqls.lua`                                       | **エラー**     | Neovim 0.12 runtime loader は table を返さない lsp/\*.lua で `error("not a table")` → 接続ブリッジを返す設計に変更               |
| `<leader>d` prefix の空き                                       | **一部使用中** | `<leader>df`/`<leader>dp` は diffview が使用 → FindBuffer は `<leader>dd` に変更                                                 |
| dadbod がシェルアウトする CLI の充足                            | **不足→追加**  | psql/bq は導入済み、`duckdb`/`sqlite3` は未導入だったため dev.nix に追加。macOS のシステム sqlite3 依存も解消                    |
| lua-toml vendor の安全性                                        | **不採用**     | jonstoler/lua-toml は 2017 年から未メンテ・TOML 0.4 止まり・無限ループ issue (#27) → yq シェルアウトに変更                       |
| `config/zsh/lazy/db.zsh` の自動ロード                           | される         | sheldon の lazy エントリは `lazy/*.zsh` glob。compinit (`completion.zsh`) が先にロードされ `compdef` 利用可                      |
| `~/.config/db-catalog/` が symlink 自動化と衝突するか           | 衝突しない     | `symlinks.nix` の `xdg.configFile` に該当エントリなし。HM は宣言済みパスしか管理しない                                           |
| Snowflake/ClickHouse adapter が nixpkgs にあるか                | **ない**       | `harlequin-snowflake` は PyPI 自体に存在せず (404)、`harlequin-clickhouse` は PyPI v0.1.1 のみ。Phase 4 で overlay が必要        |

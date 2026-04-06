# Lua Lint CI 導入 実装計画

## 概要

- selene + stylua による Lua lint / format check を CI に導入する
- 独立した GitHub Actions ワークフローとして作成する（`.lua` と `.nix` でトリガー条件が異なるため）
- Justfile に `lint-lua` タスクを追加し、ローカル実行と CI の両方で使う

**出典**:

- [ADR: Lua linter として selene を採用する](../adr/2026-04-07-lua-linter-selection.md)

---

## 決定事項

| 項目             | 決定                                          | 備考                                |
| ---------------- | --------------------------------------------- | ----------------------------------- |
| Lua linter       | **selene**                                    | luacheck から置き換え               |
| pre-commit hook  | **`selene.enable = true`（ビルトイン）**      | git-hooks.nix 提供                  |
| stylua CI 実施   | **`stylua --check` を同ワークフローに含める** | stylua-check はカスタム hook        |
| stylua.toml 配置 | **ルートに移動**                              | 全 Lua ファイル対象                 |
| ワークフロー     | **`lua-lint.yml`（独立）**                    | `nix-lint.yml` とはトリガーが異なる |
| Justfile タスク  | **`lint-lua`、`ci` にも追加**                 | ローカル / CI 共用                  |

---

## 設計: selene 設定

```toml
# selene.toml
std = "vim"
```

```yaml
# vim.yml
---
base: lua51

globals:
  vim:
    any: true
```

## 設計: pre-commit hooks

```nix
# flake.nix (pre-commit.settings.hooks に追加)
selene.enable = true;
stylua-check = {
  enable = true;
  name = "stylua-check";
  description = "Check Lua formatting with stylua";
  entry = "${pkgs.stylua}/bin/stylua --check";
  language = "system";
  types = [ "lua" ];
};
```

## 設計: Justfile

```just
# Justfile (lint ターゲットの後に追加)

# Lua ファイルの lint + フォーマットチェック
lint-lua:
    selene config/nvim/ config/wezterm/
    stylua --check config/nvim/ config/wezterm/
```

```just
# ci ターゲット（lint-lua を追加）
ci:
    nix flake check
    just lint
    just lint-lua
    shellcheck -x -e SC1091 scripts/**/*.sh
    nix build .#darwinConfigurations.yu-sz.system --dry-run
```

## 設計: GitHub Actions ワークフロー

```yaml
# .github/workflows/lua-lint.yml
name: Lua Lint

on:
  push:
    paths:
      - "config/nvim/**"
      - "config/wezterm/**"
      - "selene.toml"
      - "vim.yml"
      - "stylua.toml"
      - ".github/workflows/lua-lint.yml"

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: cachix/install-nix-action@v31
        with:
          extra_nix_config: |
            access-tokens = github.com=${{ github.token }}

      - uses: nix-community/cache-nix-action@v7
        with:
          primary-key: nix-${{ runner.os }}-${{ hashFiles('**/*.nix', '**/flake.lock') }}
          restore-prefixes-first-match: nix-${{ runner.os }}-
          gc-max-store-size-linux: 1G
          purge: true
          purge-prefixes: nix-${{ runner.os }}-
          purge-last-accessed: P7D
          purge-primary-key: never

      - name: Lua lint & format check
        run: nix develop --command just lint-lua
```

---

## 実装手順

### Phase 1: パッケージ + 設定ファイル

- [x] 1-1: `flake.nix` devShell の `pkgs.luaPackages.luacheck` を `pkgs.selene` に変更
- [x] 1-2: `nix/home/packages/lsp-tools.nix` の `luaPackages.luacheck` を `selene` に変更
- [x] 1-3: `selene.toml` をルートに作成
- [x] 1-4: `vim.yml` をルートに作成
- [x] 1-5: `config/nvim/stylua.toml` をルートに移動
- [x] 1-6: `.luacheckrc` と `config/nvim/.luacheckrc` を削除
- [x] 1-7: `git add` して `drs` を実行（ユーザー操作）

> **予実差異**: selene 実行時に `mixed_table` 警告が 111 件発生。folke/lazy.nvim と同様に `[lints] mixed_table = "allow"` で抑制。`Snacks` グローバルと `lua_versions = ["luajit"]` も `vim.yml` に追加。

### Phase 2: pre-commit hooks + Justfile

- [x] 2-1: `flake.nix` に `selene.enable = true` と `stylua-check` hook を追加
- [x] 2-2: Justfile に `lint-lua` タスクを追加
- [x] 2-3: Justfile の `ci` タスクに `just lint-lua` を追加
- [x] 2-4: `nix develop --command just lint-lua` で動作確認

> **予実差���**: `stylua --check` で既存 Lua ファイルにフォーマット差分が検出された（インデントずれ等）。`stylua` で自動修正を実施。`insert-link-to-markdown.lua` のグローバル関数を `local function` + `vim.keymap.set` にリファクタ。

### Phase 3: CI ワークフロー + エディタ連携

- [x] 3-1: `.github/workflows/lua-lint.yml` を作成
- [x] 3-2: `config/nvim/lua/plugins/nvim-lint.lua` の `luacheck` を `selene` に変更
- [ ] 3-3: push して GitHub Actions の Lua Lint ワークフロー発火を確認

---

## 変更対象ファイル一覧

| ファイル                                 | Phase 1               | Phase 2                | Phase 3         |
| ---------------------------------------- | --------------------- | ---------------------- | --------------- |
| `flake.nix`                              | `luacheck` → `selene` | hooks 追加             | -               |
| `nix/home/packages/lsp-tools.nix`        | `luacheck` → `selene` | -                      | -               |
| `selene.toml`（新規）                    | 作成                  | -                      | -               |
| `vim.yml`（新規）                        | 作成                  | -                      | -               |
| `stylua.toml`（移動）                    | ルートへ移動          | -                      | -               |
| `.luacheckrc`                            | 削除                  | -                      | -               |
| `config/nvim/.luacheckrc`                | 削除                  | -                      | -               |
| `Justfile`                               | -                     | `lint-lua` + `ci` 更新 | -               |
| `.github/workflows/lua-lint.yml`（新規） | -                     | -                      | 作成            |
| `config/nvim/lua/plugins/nvim-lint.lua`  | -                     | -                      | `selene` に変更 |

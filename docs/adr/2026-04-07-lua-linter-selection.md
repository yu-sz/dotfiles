# Lua linter として selene を採用する

Date: 2026-04-07
Status: Accepted

## Context

dotfiles リポジトリには Lua ファイルが 88 個あり（Neovim 設定 83 + WezTerm 5）、CI で lint されていない。Lua はランタイムエラー型の言語で、typo や未使用変数が Neovim 起動まで検出できない。

devShell に `luaPackages.luacheck` が入っているが、未設定のまま使われていなかった。Lua lint の CI 導入にあたり、linter を正式に選定する。

## Decision

### luacheck vs selene

| 観点                        | luacheck                      | **selene**                        |
| --------------------------- | ----------------------------- | --------------------------------- |
| 実装言語                    | Lua                           | **Rust（高速）**                  |
| 設定形式                    | `.luacheckrc`（Lua）          | **`selene.toml`（TOML）**         |
| Neovim `vim` グローバル対応 | `--globals vim`               | **`vim.yml` std 定義**            |
| git-hooks.nix ビルトイン    | `luacheck.enable = true`      | **`selene.enable = true`**        |
| nvim-lint サポート          | あり                          | **あり**                          |
| nixpkgs                     | `luaPackages.luacheck`        | **`selene`**                      |
| 初リリース                  | 2014                          | 2020                              |
| 採用例                      | Neovim 本体、多くのプラグイン | **lazy.nvim、folke 系プラグイン** |

**selene を採用する。** 根拠:

- 設定が TOML（宣言的）。プロジェクト内の他の設定（`.markdownlint.yaml`, `stylua.toml`）と統一感がある。`.luacheckrc` は Lua で書く必要があり、linter の設定に Lua を使うのは冗長
- stylua と同じモダン Lua ツールチェーン（Rust 製）の組み合わせ。[selene + stylua は folke/lazy.nvim でも採用](https://github.com/folke/lazy.nvim/blob/main/selene.toml)
- git-hooks.nix にビルトイン hook があり、既存の `statix.enable = true` 等と同じパターンで追加可能（[cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix)）
- luacheck との機能差は小さいが、luacheck を積極的に選ぶ理由もない。既に devShell にあったが未使用だった

## Consequences

- `luacheck` 関連ファイル（`.luacheckrc` x2, devShell/lsp-tools のパッケージ）を削除し、`selene` に置き換える
- `selene.toml` + `vim.yml` の 2 ファイルをルートに追加する必要がある
- WezTerm の Lua は `local wezterm = require("wezterm")` でローカル変数として使用しており、追加の std 定義なしで lint 可能

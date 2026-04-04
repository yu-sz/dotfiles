---
name: wezterm-guide
description: "WezTerm terminal configuration guide. Use when: editing WezTerm Lua modules (styles, keymaps, hooks, tab_bar) or adding new config modules."
user-invocable: false
paths:
  - "config/wezterm/**"
---

# WezTerm Guide

## Module Structure

`wezterm.lua` がエントリポイント。`utils.merge_tables(config, module)` でモジュールを合成する。

| ファイル       | 役割                                                   |
| -------------- | ------------------------------------------------------ |
| `wezterm.lua`  | エントリポイント、モジュールを順にマージ               |
| `styles.lua`   | カラースキーム、フォント、透明度、装飾                 |
| `tab_bar.lua`  | タブタイトルのフォーマット、右ステータスバー、タブ色   |
| `keymaps.lua`  | キーバインド → WezTerm アクション                      |
| `hooks.lua`    | イベントハンドラ（透明度/ブラー切替、zen-mode 連携）   |
| `my_utils.lua` | ヘルパー: cwd 取得、Git リポジトリ検出、テーブルマージ |

## Conventions

- 各モジュールは部分的な config テーブルを返す（メイン config にマージされる）
- LuaCATS 型アノテーション必須: `---@type Wezterm`, `---@type Config`, `---@type WeztermMyUtils` を各ファイル冒頭で使用
- イベントハンドラ（`update-status`, `format-tab-title`）は config 構築前に登録する必要がある
- タブタイトルキャッシュ: `pane_id → title` マップで高コストな git 呼び出しを回避。`pane-destroyed` でクリーンアップ
- Git リポジトリ検出: リモート URL → git root ディレクトリ → 断念の順

## 2つの設定パターン

1. **`merge_tables`（静的設定）** — モジュールが config テーブルを返し、`wezterm.lua` でマージ。`styles`, `tab_bar`, `keymaps` がこのパターン
2. **`config_overrides`（ランタイム切替）** — `hooks.lua` のカスタムイベント（`toggle-opacity`, `toggle-blur`, `toggle-zen-mode`）が使用。`window:set_config_overrides()` で実行中に設定を動的変更する

## Adding New Module

1. `new_module.lua` を作成し config テーブルを返す
2. `wezterm.lua` に `utils.merge_tables(config, require("new_module"))` を追加

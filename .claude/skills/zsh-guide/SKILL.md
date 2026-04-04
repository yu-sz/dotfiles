---
name: zsh-guide
description: "Zsh/Sheldon/Zabrze configuration guide. Use when: editing shell startup (.zshenv, .zshrc), Sheldon plugins (plugins.toml), eager/lazy scripts, or Zabrze snippet TOML files."
user-invocable: false
paths:
  - "config/zsh/**"
  - "config/zabrze/**"
---

# Zsh & Zabrze Guide

## Startup Sequence

1. `.zshenv` — `unsetopt GLOBAL_RCS`、XDG 変数、ロケール、**`ZDOTDIR=$XDG_CONFIG_HOME/zsh`**（これにより `.zshrc` が `config/zsh/` から読まれる）
2. `.zshrc` — brew/mise/sheldon のキャッシュ付きブートストラップ

## Cache Pattern（.zshrc）

`.zshrc` の brew・mise・sheldon は全て **write-through キャッシュ**パターンを使用（ソースの mtime > キャッシュなら再生成）。新しいツールを追加する場合も同じパターンに従うこと。

Sheldon 固有: `sheldon::load` が設定/スクリプトの mtime 変更を検出し自動再構築。プラグイン更新は `sheldon::update` を使用。

## Sheldon Plugin Loading

設定: `config/zsh/sheldon/plugins.toml`

- **eager/** — 即時ロード（`apply = ["source"]`）。起動直後に必要な設定（PATH、シェルオプション等）
- **lazy/** — `zsh-defer` で遅延ロード（`apply = ["defer"]`）。ドメインごとに1ファイルの規約

新しい zsh 設定ファイルの追加:

1. `eager/` または `lazy/` にファイル作成
2. `sheldon/plugins.toml` にエントリ追加
3. 次回シェル起動時に `sheldon::load` がキャッシュを自動再構築

## Gotchas

- `GLOBAL_RCS` が off — `/etc/zshrc` は実行されない。Nix 環境は `eager/path.zsh` で明示的に source する必要がある
- パスエントリは `(N-/)` glob 修飾子で存在しないディレクトリを無視している
- Sheldon キャッシュは `sheldon::load` が mtime 比較で自動再構築する。手動削除（`rm ~/.cache/sheldon/*.zsh*`）は外部プラグインの更新が反映されない場合のみ

## Zabrze Snippets

`config/zabrze/` の TOML ファイル。ドメインごとに分割。

```toml
[[snippets]]
name = "説明"
trigger = "短縮形"
snippet = "展開コマンド"
evaluate = true       # 任意: シェル式を評価
context = "^pattern$" # 任意: 入力がパターンに一致する場合のみ発動
```

- スニペット内の `{}` = 展開後のカーソル位置
- `evaluate = true` で動的コンテンツ（例: 現在のブランチ名）
- `context` でトリガーを特定のコマンドプレフィックスに制限

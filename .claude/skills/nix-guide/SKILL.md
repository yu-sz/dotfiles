---
name: nix-guide
description: "Nix configuration reference for this dotfiles repo. Use when: editing Nix files (flake.nix, nix/**/*.nix), adding packages, modifying overlays or symlinks."
user-invocable: false
paths:
  - "nix/**"
  - "flake.nix"
  - "flake.lock"
---

# Nix Guide

## Module Structure

```text
flake.nix                    # エントリポイント（flake-parts）
nix/
├── home/
│   ├── default.nix          # home.packages（CLI ツール）、imports
│   ├── shell.nix            # direnv、enableZshIntegration = false
│   ├── symlinks.nix         # mkOutOfStoreSymlink でドットファイルリンク
│   ├── darwin.nix           # macOS 専用パッケージ（mkIf isDarwin）
│   └── programs/
│       └── default.nix      # import リスト（新規追加時ここに追記）
├── hosts/
│   └── darwin-shared.nix    # nix-darwin システム設定、Homebrew casks、fonts
└── overlays/
    └── default.nix          # overlay エントリポイント
```

**データフロー**: `flake.nix` の `mkDarwinConfig` → `darwin-shared.nix`（システム）+ `nix/home/`（ユーザー）。`specialArgs` で `username` を全モジュールに渡す。

## Toolchain

### Flake Inputs（インフラ）

| ツール                 | 役割                                            |
| ---------------------- | ----------------------------------------------- |
| nixpkgs unstable       | ベースパッケージセット                          |
| nix-darwin             | macOS システム管理（`darwinSystem`）            |
| home-manager           | ユーザー環境・ドットファイル管理                |
| flake-parts            | Flake のモジュラー構成（`perSystem` / `flake`） |
| nix-homebrew           | Homebrew cask と Nix の共存                     |
| git-hooks.nix (cachix) | pre-commit フック自動化                         |

### 開発ツール

| ツール              | 役割                                    | 備考                                        |
| ------------------- | --------------------------------------- | ------------------------------------------- |
| nh                  | darwin-rebuild ラッパー（nom/nvd 内蔵） | `nrs` / `just switch` / `just clean`        |
| just                | タスクランナー                          | `Justfile` 参照。`switch`, `fmt`, `lint` 等 |
| direnv + nix-direnv | `.envrc` で devShell 自動ロード         | `nix develop` 手動不要                      |
| nixd                | Nix LSP                                 | エディタ補完・定義ジャンプ                  |
| shellcheck          | シェルスクリプト静的解析                | pre-commit で自動実行                       |

## Conventions

| 項目                          | 規約                                                                               |
| ----------------------------- | ---------------------------------------------------------------------------------- |
| 関数シグネチャ                | 引数を使う場合 `{ pkgs, ... }:`、使わない場合 `_:`（2 引数 overlay も `_: prev:`） |
| programs モジュール           | `nix/home/programs/<name>.nix` に 1 ファイル 1 プログラム                          |
| `home.packages` vs `programs` | HM モジュールがある場合は `programs.<name>` を優先（宣言的設定が可能）             |
| Zsh integration               | `home.shell.enableZshIntegration = false`（Sheldon が管理）                        |
| フォーマッタ / リンタ         | `nixfmt-tree`, `statix`, `deadnix`（pre-commit で自動適用）                        |
| flake-parts                   | `perSystem` = dev tooling、`flake` = マシン構成                                    |
| unfree パッケージ             | `flake.nix` の `allowUnfreePredicate` にパッケージ名を追加                         |

## Key Patterns

### 条件分岐

```nix
# モジュールオプション内 → lib.mkIf
home.packages = lib.mkIf pkgs.stdenv.isDarwin [ pkgs.terminal-notifier ];

# 通常の attrset マージ → lib.optionalAttrs
xdg.configFile = { ... } // lib.optionalAttrs pkgs.stdenv.isDarwin { ... };
```

### シンボリックリンク

```nix
# XDG 準拠（~/.config/ 配下）
xdg.configFile."<name>".source = mkLink "config/<name>";

# それ以外（~/ 直下や ~/.claude/ 等）
home.file."<path>".source = mkLink "config/<source>";
```

`mkLink` = `mkOutOfStoreSymlink` のラッパー。Nix Store を経由せず直接リンクするため、設定変更が即時反映される。

### Overlay

#### 新規パッケージ追加

```nix
# nix/overlays/default.nix
_: prev: {
  package-name = prev.callPackage ./package-name.nix { };
}
```

#### Upstream バグの workaround

nixpkgs のバグを一時回避する overlay は、対象パッケージの **バージョンと書き換え対象属性を `lib.assertMsg` で固定** し、上流が修正されたら eval を止めて再評価を強制する。これにより workaround の死蔵を構造的に防ぐ。

```nix
# nix/overlays/<pkg>.nix
# FIXME(nixpkgs#XXXX): 症状の1行説明
# - Issue: https://github.com/NixOS/nixpkgs/issues/XXXX
# - Fix:   https://github.com/NixOS/nixpkgs/pull/YYYY
{ lib }:
_: prev: {
  <pkg> =
    assert lib.assertMsg
      (prev.<pkg>.version == "X.Y.Z" && (prev.<pkg>.<attr> or true))
      "Overlay may no longer be needed: <pkg>=${prev.<pkg>.version}. Try removing.";
    prev.<pkg>.overrideAttrs (_: { <attr> = <value>; });
}
```

assertion の条件は **「現状の workaround が必要な状態」と等価** にする。バージョン bump で fix される想定なら version、属性変更で fix される想定なら属性値を含める（両方該当する場合は AND で連結）。

##### 設計原則

| 原則                         | 理由                                                                            |
| ---------------------------- | ------------------------------------------------------------------------------- |
| **assertion で self-expire** | 主題。修正反映時に必ず eval が止まり workaround の放置を構造的に防ぐ            |
| 固定する属性は最小限         | 「workaround が必要な条件」と等価にする。広すぎると誤発火、狭すぎると検知漏れ   |
| scope を最小化               | `doCheck = false` より `disabledTests = [ ... ]` 等、検知能力を残す上書きを優先 |
| URL を併記                   | Issue / Fix PR / 根本原因の 3 点を残し、半年後でも文脈を辿れる                  |
| 1 ファイル 1 workaround      | 削除タイミングが個別なため                                                      |

### programs モジュール

```nix
# cask 管理のアプリ（nixpkgs でビルドしない場合）
_: { programs.app-name = { enable = true; package = null; settings = { ... }; }; }
```

### ハッシュ更新（overlay のバージョンアップ）

1. `version` を更新、`hash`（と `cargoHash`）を `""` に設定
2. ビルド → エラーメッセージに正しいハッシュが表示される
3. ハッシュを置換して再ビルド（`cargoHash` がある場合は 2 回繰り返す）

## Gotchas

| 項目                   | 詳細                                                                                          |
| ---------------------- | --------------------------------------------------------------------------------------------- |
| `stateVersion`         | `home.stateVersion` と `system.stateVersion` は**絶対に変更しない**（マイグレーション基準値） |
| `git add` 必須         | Flake は Git 管理ファイルのみ参照。新規ファイル作成後は必ず `git add` してから `nrs`          |
| `sessionVariables`     | `.zshenv` の `unsetopt GLOBAL_RCS` により HM の変数設定は機能しない。明示的パスを使用         |
| `enableZshIntegration` | 全プログラムで `false`（shell.nix でグローバル設定済み）。Zsh hooks は Sheldon が管理         |
| `package = null`       | cask でインストールするアプリの programs モジュールに必要（nixpkgs ビルドをスキップ）         |
| `cleanup`              | `"uninstall"` を使用。`"zap"` はアプリの設定データも削除してしまう                            |
| pre-commit             | `nix develop` 内でコミットすること（hooks は devShell で提供）                                |

## References

- flake-parts 構成: `flake.nix` の `perSystem` / `flake` ブロック

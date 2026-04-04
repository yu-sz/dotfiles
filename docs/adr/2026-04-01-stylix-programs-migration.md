# Stylix テーマ統一 + lazygit/ghostty/yazi の programs 移行

Date: 2026-04-01
Status: Partially Superseded

## Context

tokyo-night を各ツールで独立管理（ghostty: `theme`、yazi: `flavors/`、bat/fzf: 個別設定）しており、カラースキーム変更時に全ファイルの手動修正が必要。[Stylix](https://github.com/nix-community/stylix) を導入すれば `base16Scheme` の1行変更で一斉切替が可能。

ただし Stylix は `xdg.configFile` や `programs.*` 経由でファイルを生成するため、`symlinks.nix` の `mkOutOfStoreSymlink` と同一パスで競合する。解決には対象ツールを `programs.*` に移行してシンボリンクを廃止する必要がある。

[前回 ADR](2026-03-31-home-manager-programs-migration.md) で除外した lazygit・ghostty・yazi を再調査した結果、いずれも移行コストが低いと判明（lazygit: YAML 18行、ghostty: key-value 1:1 変換、yazi: 236行 TOML の大半がデフォルトのコピペ）。

また最大4台（macOS + Linux）への展開を見据え、ghostty を Homebrew cask から nixpkgs に統一すれば1ファイルで全マシン対応できる。

## Decision

### 方針: ツールごとの対応

| ツール   | 対応                                                       | 理由                                                                                           |
| -------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| lazygit  | `programs.lazygit` に移行 + Stylix 有効化                  | YAML 18行、1:1 変換可能                                                                        |
| ghostty  | `programs.ghostty` に移行 + Stylix 有効化 + cask → nixpkgs | key-value 1:1 変換、Linux 共通化。macOS は `ghostty-bin`、Linux は `ghostty`                   |
| yazi     | `programs.yazi` に移行 + Stylix 有効化                     | 設定の大半がデフォルト。プラグインは `pkgs.yaziPlugins` で管理、`init.lua` は `initLua` で渡す |
| wezterm  | シンボリンク維持、Stylix 除外                              | Lua 6ファイル構成で移行コスト高。macOS の nixpkgs ビルド不安定                                 |
| neovim   | シンボリンク維持、Stylix 除外                              | Lua + lazy.nvim 独自管理。Stylix 競合リスク高                                                  |
| vim      | シンボリンク維持、Stylix 除外                              | 移行メリット小                                                                                 |
| starship | 移行済み、Stylix 除外                                      | パワーライン記号 + 背景グラデーションで Stylix 自動設定では再現不可                            |
| tmux     | シンボリンク維持                                           | TPM + 複雑な固有構文                                                                           |
| zsh      | シンボリンク維持                                           | Sheldon + zsh-defer で移行コスト大                                                             |

### Stylix 設定方針

- カラースキーム: `tokyo-night-dark`
- フォント: PlemolJP Console NF
- `autoEnable = false` で対象ツールのみ個別有効化（競合回避）
- ghostty のフォント競合時は `stylix.targets.ghostty.fonts.enable = false` で対応

## Consequences

- yazi の `config/`（236行 TOML + plugins + flavors）が数行の Nix 定義に集約
- `config/` と `symlinks.nix` のエントリが lazygit・ghostty・yazi の3つ分減る
- `ya pack` によるプラグイン管理は Nix に統一（`ya pack` ワークフローは使用不可に）
- `drs` 経由の適用が必要になり、ghostty/yazi の raw config 即時反映は失われる（変更頻度が低いため影響小）
- wezterm・neovim 等はカラースキーム変更時に手動修正が引き続き必要

---

## Addendum (2026-04-03): Stylix テーマ統一の見送り

Status: **Partially Superseded** — programs 移行（B〜E）は実施、Stylix テーマ統一（A）は見送り

### 経緯

ghostty に Stylix を適用したところ色味に違和感が発生。原因は **Stylix の base16 パレットマッピングが公式 TokyoNight テーマと大きく乖離**していたこと。

| ANSI slot  | 期待される色 | TokyoNight 公式 | Stylix base16       |
| ---------- | ------------ | --------------- | ------------------- |
| 1 (red)    | 赤系         | `#f7768e`       | `#c0caf5`（青系）   |
| 3 (yellow) | 黄系         | `#e0af68`       | `#0db9d7`（シアン） |
| foreground | 明るい白     | `#c0caf5`       | `#a9b1d6`（暗い）   |

### 変更した決定

| 項目              | 元の決定                                | 変更後                                                                        |
| ----------------- | --------------------------------------- | ----------------------------------------------------------------------------- |
| Stylix テーマ統一 | bat, fzf, lazygit, ghostty, yazi に適用 | **すべて無効化**。`autoEnable = false` + targets 空                           |
| ghostty テーマ    | Stylix 管理                             | `theme = "tokyonight"`（ghostty ビルトイン）                                  |
| yazi テーマ       | Stylix 管理                             | `programs.yazi.flavors` + `theme` で BennyOe tokyo-night flavor を直接設定    |
| lazygit テーマ    | Stylix 管理                             | テーマ設定なし（ターミナルカラーに従う）                                      |
| bat/fzf テーマ    | Stylix 管理                             | テーマ設定なし（ターミナルカラーに従う）                                      |
| ghostty 本体      | cask → nixpkgs `ghostty-bin`            | **cask 維持**（`package = null`）。nix 版はウィンドウ操作・フォント描画に問題 |

### Stylix 基盤の残置

`flake.nix` の stylix input、`darwin-shared.nix` の core 設定、`nix/home/stylix.nix`（targets 空）は残置。将来の base16 改善時やエディタ系ツールへの適用時に再利用可能。

# Stylix テーマ統一 + lazygit/ghostty/yazi の programs 移行

Date: 2026-04-01
Status: Accepted

## Context

### カラースキーム変更時に全ファイルを手動修正する必要がある

現在 tokyo-night をカラースキームとして使用しているが、ghostty は `theme = tokyonight`、yazi は `flavors/tokyo-night.yazi`、bat/fzf は個別設定と、各ツールで独立して管理している。今後さまざまなカラースキームを試したいが、変更のたびに各ツールの設定ファイルを個別に修正する必要がある。Stylix を導入すれば `base16Scheme` の1行変更で対応ツール全体のカラースキームが一斉に切り替わる。

### Stylix 導入にはシンボリンクとの競合問題がある

Stylix はテーマを適用する際、home-manager の `xdg.configFile` や `programs.*` 経由で設定ファイルを生成する。このプロジェクトでは `symlinks.nix` の `mkOutOfStoreSymlink` で `config/` ディレクトリを `~/.config/` にシンボリンクしているため、**同じパスに Stylix の生成ファイルとシンボリンクが共存できない**（home-manager が `Conflicting managed target files` エラーを出す）。

Stylix を有効化するには、対象ツールのシンボリンクを廃止して `programs.*` に移行するか、Stylix を無効にしてシンボリンクを維持するかの二択になる。

### 前回の移行で除外したツールの再評価

[ADR: home-manager programs 移行](2026-03-31-home-manager-programs-migration.md) で lazygit, ghostty, yazi を「独自言語設定」として `programs.*` 移行から除外した。しかし再調査の結果:

- lazygit: YAML 18行の key-value 設定で、移行基準を満たす
- ghostty: key-value 設定で 1:1 の Nix 変換が可能。`programs.ghostty` モジュールの存在を前回見落としていた
- yazi: 236行の TOML はほぼ公式デフォルトのコピペで、実際の差分は数行。プラグインも `programs.yazi.plugins` + nixpkgs で管理可能

いずれも移行コストが低く、Stylix 統合のために移行する価値がある。

### 最大4台のマシンへの展開を見据えた共通化

今後 macOS/Linux 合わせて最大4台のマシンでこの dotfiles を運用する予定がある。ghostty は現在 Homebrew cask で管理しているが、cask は macOS 専用であり Linux マシン追加時に別の管理方法が必要になる。nixpkgs に統一すれば `programs.ghostty` の1ファイルで macOS/Linux 両対応できる。

## Decision

### A. Stylix によるテーマ統一

今後さまざまなカラースキームを試したいという要求に応えるため、[Stylix](https://github.com/nix-community/stylix) を導入する。Stylix は1つの Base16 カラースキーム定義から対応ツール全体のテーマを自動生成する仕組みで、`base16Scheme` の1行変更で全ツールの色が一斉に切り替わる。

- カラースキーム: `tokyo-night-dark`（現在使用中のテーマ）
- モノスペースフォント: PlemolJP Console NF
- `autoEnable = false` とし、対象ツールのみ個別に有効化（シンボリンク競合を回避するため）

### B. シンボリンク競合の解決方針

Stylix とシンボリンクの競合に対して、ツールごとに2つの方針で対応する。

**方針 1: `programs.*` に移行して Stylix 統合を有効化**

シンボリンクを廃止し、`programs.*` で設定を管理することで Stylix との競合を解消する。移行コストが低く、Stylix 統合のメリットがあるツールはこの方針で対応:

| ツール | 移行コスト | 判断理由 |
|--------|-----------|---------|
| ghostty | 低（key-value 設定が 1:1 で Nix に変換可能） | Stylix 統合 + Linux 共通化のメリットが大きい |
| yazi | 低（設定はほぼデフォルト、差分数行） | Stylix 統合 + flavor/plugin 管理の簡素化 |
| lazygit | 低（YAML 18行） | Stylix 統合のメリットあり |

**方針 2: シンボリンク管理を維持し、Stylix を除外**

`programs.*` への移行コストが高い、または移行しても Stylix の恩恵が薄いツールはシンボリンク管理を維持し、`autoEnable = false` により Stylix を暗黙的に無効とする:

| ツール | 判断理由 |
|--------|---------|
| wezterm | Lua 6ファイル構成（`wezterm.lua`, `styles.lua`, `tab_bar.lua`, `hooks.lua`, `keymaps.lua`, `my_utils.lua`）で `programs.wezterm.extraConfig` への移行コストが高い。また nixpkgs の wezterm は macOS でクラッシュ報告がある |
| neovim | Lua + lazy.nvim の独自プラグイン管理。Stylix との競合リスクが高く、テーマは colorscheme プラグインで管理すべき |
| vim | config/ で自前管理。Stylix 統合のメリットが小さい |
| starship | 移行済み（`programs.starship`）だが、パワーライン記号 + 背景グラデーションで色を組み込んでおり Stylix の自動設定では再現不可 |

### C. lazygit の home-manager 移行

Stylix のテーマ統一対象にするため、`programs.lazygit` に移行する（方針 1）。

- 前回の除外理由: 独自言語設定として一括除外
- 再評価: 設定は key-value 的な YAML（18行）で `programs.*` 移行の判断基準を満たす
- YAML → Nix 変換がシンプルで、既存の移行パターン（git, gh 等）がそのまま適用可能

### D. ghostty の home-manager 移行 + Homebrew cask → nixpkgs

Stylix 統合と Linux 共通化の2つの目的で、`programs.ghostty` に移行し、本体も Homebrew cask から nixpkgs に移す（方針 1）。

- 前回は `programs.ghostty` モジュールの存在を見落としていた
- key-value 設定なので Nix 変換が 1:1 で対応
- 本体パッケージ: macOS は `ghostty-bin`（公式 .dmg のリパッケージ、Ghostty 公式が Nix ユーザーに推奨）、Linux は `ghostty`（ソースビルド）
- Homebrew cask → nixpkgs に移す理由: cask は macOS 専用であり、最大4台のマシン（macOS + Linux）展開時に管理方法が二分される。nixpkgs に統一することで `programs.ghostty` の1ファイルで全マシン対応
- `theme` 設定は Stylix が管理するため削除
- Stylix のフォント設定と `font-family` が競合する場合は `stylix.targets.ghostty.fonts.enable = false` で対応

### E. yazi の home-manager 移行

Stylix のテーマ統一対象にするため、`programs.yazi` に移行する（方針 1）。加えて、236行の TOML がほぼデフォルトのコピペであることが判明し、移行により大幅に設定が簡素化される。

- 前回の除外理由: 「Lua プラグイン + 大きな TOML 設定」
- 再評価:
  - `yazi.toml`（236行）はほぼ公式デフォルトのコピペ。実際の差分は数行（`mgr.show_hidden = true` 等）
  - プラグインは `programs.yazi.plugins` で管理可能（smart-enter, starship, full-border は `pkgs.yaziPlugins` に公式パッケージあり）
  - `init.lua` は `initLua` オプションで渡せる
- `theme.toml` + `flavors/` は Stylix が担当するため不要
- `package.toml`（`ya pack` 管理）は Nix 管理に統一されるため不要
- 注意: `ya pack` によるプラグイン管理のワークフローは使えなくなる

### F. 移行しないもの（前回判断を維持、Stylix 除外含む）

| ツール | 理由 |
|--------|------|
| neovim | Lua + lazy.nvim の独自プラグイン管理。Stylix 競合リスク高（方針 2） |
| wezterm | Lua 6ファイル構成で移行コスト高。macOS の nixpkgs ビルド不安定（方針 2） |
| vim | config/ で自前管理。移行メリット小（方針 2） |
| starship | 移行済みだが Stylix 統合は不可（方針 2） |
| tmux | TPM + 複雑な tmux.conf 固有構文 |
| zsh | Sheldon + zsh-defer。`programs.zsh` への移行コストが大きい |

## Consequences

- ~~カラースキーム変更が `base16Scheme` の1行変更で bat, fzf, lazygit, ghostty, yazi に反映~~ → Addendum 参照
- ~~ghostty が nixpkgs 管理になり、Linux 展開時の差分が減る~~ → Addendum 参照
- yazi の `config/` ディレクトリ（236行 TOML + plugins + flavors）が数行の Nix 定義に集約
- `config/` ディレクトリと `symlinks.nix` のエントリが lazygit, ghostty, yazi の3つ分減る
- `ya pack` によるプラグイン管理が Nix に統一される（`ya pack` のワークフローは使えなくなる）
- `drs` で設定変更を適用する必要があり、ghostty/yazi の raw config の「即時反映」は失われる。ただし設定変更頻度が低いため実用上の影響は小さい
- wezterm, neovim 等のシンボリンク管理ツールはカラースキーム変更時に手動修正が引き続き必要

---

## Addendum (2026-04-03): Stylix テーマ統一の見送り

Status: **Partially Superseded** — programs 移行（B〜E）は実施、Stylix テーマ統一（A）は見送り

### 経緯

Phase 2 で Stylix 基盤を導入し Phase 3-4 で lazygit・ghostty に適用したところ、ghostty の色味に違和感が発生。調査の結果、**Stylix の base16 パレットマッピングが公式 TokyoNight テーマと大きく乖離**していることが判明。

### 根本原因: base16 と ANSI カラーの設計思想の違い

base16 スキームはエディタ向けに設計された 16 色定義で、ANSI ターミナルカラー（palette 0-15）とは用途が異なる。Stylix は base16 の色を機械的に ANSI パレットにマッピングするが、結果として色の意味が崩れる:

| ANSI slot | 期待される色 | TokyoNight 公式 | Stylix base16 |
|-----------|-------------|----------------|---------------|
| 1 (red) | 赤系 | `#f7768e` | `#c0caf5`（青系） |
| 3 (yellow) | 黄系 | `#e0af68` | `#0db9d7`（シアン） |
| foreground | 明るい白 | `#c0caf5` | `#a9b1d6`（暗い） |

### 対象ツールの特性

lazygit, yazi, bat, fzf はすべてターミナル上で動作し、ターミナルの ANSI パレットをそのまま使用する。ghostty の公式 TokyoNight テーマ（正確な ANSI カラー定義）を使えば、これらのツールは自動的に正しい色で表示される。Stylix で別のパレットを注入する必要がない。

### 変更した決定

| 項目 | 元の決定 | 変更後 |
|------|---------|--------|
| Stylix テーマ統一 | bat, fzf, lazygit, ghostty, yazi に適用 | **すべて無効化**。`autoEnable = false` + targets 空 |
| ghostty テーマ | Stylix 管理 | `theme = "tokyonight"`（ghostty ビルトイン） |
| yazi テーマ | Stylix 管理 | `programs.yazi.flavors` + `theme` で BennyOe tokyo-night flavor を直接設定 |
| lazygit テーマ | Stylix 管理（`mkForce` で上書き） | テーマ設定なし（ターミナルカラーに従う） |
| bat/fzf テーマ | Stylix 管理 | テーマ設定なし（ターミナルカラーに従う） |
| ghostty 本体 | Homebrew cask → nixpkgs `ghostty-bin` | **Homebrew cask を維持**（`package = null`）。nix 版はウィンドウ操作・フォント描画に問題 |

### Stylix 基盤の残置

`flake.nix` の stylix input、`darwin-shared.nix` の core 設定、`nix/home/stylix.nix`（targets 空）はそのまま残す。将来 base16 パレットマッピングが改善された場合や、エディタ系ツール（neovim 等）への適用を検討する際に再利用可能。

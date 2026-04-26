# macOS ウィンドウ管理スタックを AeroSpace + SketchyBar + JankyBorders で導入する

Date: 2026-04-25
Status: Accepted

## Context

現状は macOS 標準の Spaces / Cmd+Tab + Raycast Window Management で運用しているが、次の課題がある:

- **ワークスペースの永続化が弱い**: Raycast WM は macOS Spaces 上の Snap 補助に過ぎず、レイアウトが固定されない。アプリの起動位置もばらつく
- **外部モニタスリープでレイアウトが壊れる**: macOS の仕様で、外部ディスプレイがスリープ／切断されるとウィンドウが内蔵ディスプレイへ集約される。Stacking + Snap モデルでは復旧手段がない
- **コード管理が成立しない**: Raycast WM の設定は GUI 主体で、dotfiles へ取り込めない
- **アプリ選択の見通し・操作性が悪い**: Cmd+Tab はサムネイル無しで同種アプリの区別が難しく、ワークスペース横断にも弱い

加えて、メニューバー・ウィンドウ枠といった画面まわりの **見た目を自分好みに統一したい**（既存の Tokyo Night ベースの見た目に合わせて、bar とウィンドウ枠もエモく整える）。

これらを解決するため、コード管理可能な Tiling WM をベースに、ステータスバー・ウィンドウ枠装飾・ウィンドウ切替を含むスタックを導入する。

## Decision

### A. ウィンドウマネージャ本体

**この決定の核心は「Tiling WM を採用する」こと自体**。macOS 標準は Stacking WM（ウィンドウが重なる前提・OS が z-order で管理）であり、Rectangle / Magnet / Loop / Raycast WM は Stacking WM 上で動く Snap 補助ユーティリティに過ぎない。Tiling WM は「ウィンドウが重ならない・自動配置・ワークスペース固定」が根本的に異なる。

比較は「**Tiling WM のメジャー 2 種 (AeroSpace / yabai)**」と「**現状利用中の Stacking + Snap 補助 (Raycast Window Management)**」を並べる。

| 観点                                          | AeroSpace (Tiling)                                     | yabai (Tiling)                            | Raycast WM (Stacking + Snap 補助)           |
| --------------------------------------------- | ------------------------------------------------------ | ----------------------------------------- | ------------------------------------------- |
| カテゴリ                                      | **Tiling WM (tree, i3)**                               | Tiling WM (BSP)                           | Stacking WM 上の Snap 補助                  |
| ウィンドウ重なり                              | **不可（自動配置）**                                   | 不可（自動配置）                          | 可（macOS 既定の重なり）                    |
| ワークスペース固定                            | **○**                                                  | ○ (Spaces 流用)                           | × (Spaces 概念に依存)                       |
| 自動タイル配置                                | **○**                                                  | ○                                         | × (毎回 hotkey で手動 snap)                 |
| SIP 無効化要否                                | **不要**                                               | 部分要                                    | 不要                                        |
| 設定・管理の取り回し（plain text / nix 経路） | **TOML (Nix attrset → 自動生成) + nixpkgs (lag 1 日)** | rc + brew + code-signing 再実施が必要     | Raycast 設定 GUI 主体（Pro 課金で sync 可） |
| WS モデル                                     | **i3 風独自**                                          | macOS Spaces 流用                         | macOS Spaces 流用                           |
| キーバインド mode                             | **任意定義 (main/service/resize)**                     | skhd 等別ツール                           | 単発 hotkey のみ                            |
| 外部モニタ上の安定性                          | **○ (WS 概念で吸収)**                                  | × (Spaces 流用、スリープ時集約問題が残る) | × (Spaces 依存、スリープ時集約問題が残る)   |
| OSS / 配布                                    | OSS                                                    | OSS                                       | クローズドソース (Raycast 拡張、cask 経由)  |
| GitHub stars (2026-04-25)                     | 20.4k                                                  | 28.7k                                     | N/A (Raycast 本体は閉)                      |

- [AeroSpace 公式 README "Why AeroSpace?"](https://github.com/nikitabobko/AeroSpace#why-aerospace) — SIP 不要・tree tiling・plain text 設定・外部ディスプレイ対応を明記
- [yabai は SIP 部分無効化が必要](https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection)。バイナリ更新ごとに code-signing 再実施
- Raycast WM は Stacking モデルに留まるため、「ワークスペース固定」「自動タイル配置」を構造上提供できない → Tiling WM を選ぶ理由そのもの
- 外部モニタの「スリープ時にウィンドウが内蔵モニタに集約される」問題は macOS の仕様で、Stacking + Snap 補助 (Raycast WM 含む) では解決できない。AeroSpace は WS 概念がモニタから独立しているため吸収できる

Tiling のもう 1 候補 **Amethyst** (16.1k stars) は AeroSpace と同方向（SIP 不要・YAML 設定・nixpkgs あり）だが、i3 風の mode 切替・コマンド DSL を持たず独自 layout 切替のみ。AeroSpace の柔軟性に対する優位はないため除外。

その他カテゴリ（比較表の対象外）:

| ツール                    | カテゴリ              | 不採用理由                                              |
| ------------------------- | --------------------- | ------------------------------------------------------- |
| Rectangle / Magnet / Loop | Stacking + Snap 補助  | Raycast WM と同カテゴリで、機能差は採用判断に影響しない |
| Hammerspoon / Phoenix     | Lua/JS scripting 基盤 | WM 本体ではなく、WM 機能を構築するなら DIY 実装が必要   |
| chunkwm                   | 廃止 (yabai の前身)   | リポジトリ削除済                                        |

**決定**: AeroSpace を採用する。

### B. ステータスバー・枠装飾

AeroSpace と組み合わせて使う付帯ツール群は実質的に **SketchyBar + JankyBorders 一択** （比較対象が乏しい領域）。

採用理由:

- AeroSpace 公式の [goodness ドキュメント](https://nikitabobko.github.io/AeroSpace/goodness) に SketchyBar 連携 (`exec-on-workspace-change`) のサンプルがある
- SketchyBar / JankyBorders は同作者 (FelixKratz) の姉妹ツールで思想・配色作法が揃っている
- nix-darwin に両モジュール (`services.sketchybar` / `services.jankyborders`) が存在
- C 製で軽量、常駐デーモンとしての副作用が小さい
- SketchyBar 本体に加え、Lua 拡張の **sbarlua**（同 nixpkgs 提供）と表示用本文フォントの **nerd-fonts.hack**（nixpkgs `fonts.packages`）を併用する。SketchyBar の設定を Lua で記述する事実上の標準構成（公式 Setup ドキュメント / SoichiroYamane dotfiles 例）に揃えるため

不採用候補: Übersicht（HTML/CSS/JS 基盤で重く、目的に対し過剰）。

**決定**: SketchyBar + JankyBorders を採用する。

### C. ウィンドウ切替プレビュー

サムネイル付きスイッチャーは **alt-tab 一択**（macOS Cmd+Tab・Raycast Switch Window はサムネイル非表示）。

採用理由:

- macOS Cmd+Tab は AeroSpace の独自 WS 横断に弱い
- Raycast Switch Window はサムネイルなし
- 既存 cask 群 (cursor / raycast / dbeaver / docker-desktop / karabiner-elements) と挙動が一致

**決定**: alt-tab を `homebrew.casks` で導入する。Sparkle 自動更新あり、許容。

hotkey は `⌘ Tab` (Cmd+Tab) を充て、macOS 標準のアプリスイッチャを置換する。AeroSpace 側 `alt-tab = "workspace-back-and-forth"` (Option+Tab、ワークスペース直前へ戻る) と modifier が異なるため衝突しない。alt-tab cask の **スペースからウィンドウを表示する = 現在のスペース** 設定により、AeroSpace のワークスペース運用とウィンドウ切替の責務を分離できる（ワークスペース横断は AeroSpace の数字キー、現在ワークスペース内のウィンドウ切替は alt-tab cask）。

### D. インストール経路の統一

[ADR: nix-package-management](./2026-03-28-nix-package-management.md) の規約と整合させ、**3 経路に収束**:

| カテゴリ                 | 経路                                |
| ------------------------ | ----------------------------------- |
| CLI / デーモン           | nixpkgs（無ければ `nix/overlays/`） |
| フォント                 | nixpkgs `fonts.packages`            |
| .app バンドル GUI アプリ | `homebrew.casks`                    |

手動 URL DL は規約外で不採用。upstream → nixpkgs 追従ラグの実測（2026-04-25 現在）:

- AeroSpace v0.20.3-Beta: **1 日**
- SketchyBar v2.23.0: **同日**
- JankyBorders v1.8.4: **13 日**

→ いずれも nix 経路で実害なし。sketchybar-app-font は nixpkgs 未提供のため `nix/overlays/sketchybar-app-font.nix` で `fetchurl` パッケージ化する。

**決定**: aerospace / sketchybar / sbarlua / jankyborders / nerd-fonts.hack は nixpkgs、sketchybar-app-font は overlay、alt-tab は cask。

### E. 各ツールの設定の保管場所

リポ既存規約「**HM モジュールがある場合は `programs.<name>` を優先**」（`nix-guide` skill）を最優先指針として、各ツールの設定形式・モジュール完成度に合わせて保管場所を決める:

| ツール       | 保管場所                                                                                                    | 理由                                                                                                                                                                                                           |
| ------------ | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AeroSpace    | **HM `programs.aerospace.settings` (Nix attrset)**                                                          | リポ規約「`programs.<name>` 優先」と一致。HM モジュールが `pkgs.formats.toml` で TOML を生成し、`onChange` フックで `aerospace reload-config` を自動実行（hot reload）。HM 側 launchd agent が起動を担う       |
| SketchyBar   | **HM `programs.sketchybar` (`configType = "lua"` + `source = ./config/sketchybar`)** + `config/sketchybar/` | nix-darwin `services.sketchybar.config` は単一 bash 文字列で Lua ツリー非対応。HM `programs.sketchybar` は `configType = "lua"` + `sbarLuaPackage` で LUA_PATH/CPATH 自動設定、`source` でディレクトリ symlink |
| JankyBorders | **nix-darwin `services.jankyborders.{width,active_color,...}` (Nix attribute 群)**                          | bordersrc を読まず CLI 引数化されるモジュール仕様。HM 版 `programs.jankyborders` は存在しないため nix-darwin 一択                                                                                              |

**重要な地雷**: nix-darwin `services.aerospace` と HM `programs.aerospace` を併用すると launchd agent が二重に作られて同じバイナリを取り合う（`services/aerospace/default.nix:249-256` と `programs/aerospace.nix:` が同名 agent を生成）。本リポは HM 側に統一する。

**マルチ OS 整合性**: `flake.nix` で `darwinConfigurations` と `homeConfigurations.ci@linux` の両方が同じ `./nix/home` を import するため、Darwin-only HM プログラムは **既存 `nix/home/darwin.nix` と同じく `lib.mkIf pkgs.stdenv.isDarwin { ... }` で内部ガード**する（Pattern C）。
`config = lib.mkIf cfg.enable { assertions = [...] }` の構造により、`enable` が false なら `assertPlatform` も発火しない。

→ `config/aerospace/` ディレクトリと `config/borders/` ディレクトリは作らない。`config/sketchybar/` は HM `programs.sketchybar.source` が symlink を貼るため `nix/home/symlinks.nix` への追記も不要。

### F. カラーパレット

リポジトリ整合性が支配的な観点なので **`tokyonight` 一択**（パレット選定に独立した検討要素は無い）。

採用理由:

- 既存 dotfiles で WezTerm (`tokyonight_night`) / Neovim (`tokyonight-night`) / Lualine が同パレットを採用済 → リポジトリ内一貫性が取れる
- 公開されている SketchyBar 設定例 [SoichiroYamane/dotfiles colors.lua](https://github.com/SoichiroYamane/dotfiles/blob/main/.config/sketchybar/colors.lua) も `tokyonight` パレットがベース → コミュニティ事例の見た目を自然に再現できる
- SketchyBar / JankyBorders / AeroSpace いずれも公式テーマ機構を持たず、folke/tokyonight, catppuccin (org 直下), rose-pine (org 直下) も対応リポを提供していない（2026-04-25 時点） → どのパレットを選んでも hex 直書きの作業量は同じ。となれば既存 dotfiles と整合する選択が圧倒的優位

**決定**: `folke/tokyonight.nvim` のパレットを `config/sketchybar/colors.lua` に手動移植し、JankyBorders の `active_color` / `inactive_color` にも同パレットの hex を適用する。

## Consequences

- 純正メニューバーが常時非表示 (`_HIHideMenuBar = true`) になり、アプリメニュー操作は Raycast `Search Menu Bar` (`Cmd+Shift+/`) / hover / `Ctrl+F2` 経由になる
- macOS 純正 Spaces は AeroSpace 独自 WS と並存する。Mission Control の使用感が変わる
- GUI 自動更新を持たないため、flake update のタイミングで意図的にバージョンを上げる運用になる。実測ラグは 1 日〜2 週間で許容範囲
- sketchybar-app-font は週次更新で新アプリのアイコンが追加される。新規アプリ採用時にアイコン未対応で気付くので、その時点で overlay の `version` + `hash` を bump
- Raycast WM 拡張廃止により `Ctrl+Option+矢印` 等の hotkey 領域が解放される
- AeroSpace 設定が Nix attrset 化されるため、TOML 直書きより Nix 知識が要求される。代わりに型チェック・補完が効く
- SketchyBar の表示フォントは Ghostty (`nix/home/programs/ghostty.nix`) と統一して `Moralerspace Xenon HW`（v2.0.0 以降は Nerd Fonts 標準搭載）を使用。`fonts.packages` への追加は不要

## 参考文献

- AeroSpace 公式 — [Why AeroSpace?](https://github.com/nikitabobko/AeroSpace#why-aerospace) / [Guide](https://nikitabobko.github.io/AeroSpace/guide) / [Commands](https://nikitabobko.github.io/AeroSpace/commands) / [Goodness](https://nikitabobko.github.io/AeroSpace/goodness)
- yabai — [README](https://github.com/koekeishiya/yabai) / [Disabling SIP](https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection)
- SketchyBar — [README](https://github.com/FelixKratz/SketchyBar) / [Setup](https://felixkratz.github.io/SketchyBar/setup)
- JankyBorders — [README](https://github.com/FelixKratz/JankyBorders)
- sketchybar-app-font — [README](https://github.com/kvndrsslr/sketchybar-app-font)
- [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim) — パレット由来
- home-manager programs — [aerospace](https://github.com/nix-community/home-manager/blob/master/modules/programs/aerospace.nix) / [sketchybar](https://github.com/nix-community/home-manager/blob/master/modules/programs/sketchybar.nix)
- nix-darwin services
  - [jankyborders](https://github.com/nix-darwin/nix-darwin/blob/master/modules/services/jankyborders/default.nix)
  - [aerospace](https://github.com/nix-darwin/nix-darwin/blob/master/modules/services/aerospace/default.nix)（参考: 本ADR当初は不採用、後の Plans 実装で採用に切替）
  - [sketchybar](https://github.com/nix-darwin/nix-darwin/blob/master/modules/services/sketchybar/default.nix)（参考: 本ADRでは不採用、競合理由は §E 参照）
- 関連 ADR — [nix-package-management](./2026-03-28-nix-package-management.md)
- 国内事例（参考）
  - [mozumasu「macOS のウィンドウマネジメントを快適にする」](https://zenn.dev/mozumasu/articles/mozumasu-window-costomization)
  - [takeokunn 「Setting AeroSpace」](https://www.takeokunn.org/posts/fleeting/20251124235900-setting_aerospace/)
  - [takeokunn 「Setting SketchyBar」](https://www.takeokunn.org/posts/fleeting/20251124235900-setting_sketchybar/)
  - [SoichiroYamane/dotfiles](https://github.com/SoichiroYamane/dotfiles)

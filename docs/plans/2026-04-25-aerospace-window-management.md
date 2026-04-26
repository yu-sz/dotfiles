# macOS ウィンドウ管理スタック 実装計画

## 概要

- AeroSpace でタイル型 WM を導入（ワークスペース 1〜4 連番）
- SketchyBar でメニューバーを Tokyo Night アイランド型に置換
- JankyBorders でアクティブウィンドウ枠を可視化
- alt-tab でワークスペース横断ウィンドウ切替
- Raycast WM 拡張は hotkey 全 Unbind で廃止

**設定経路**: AeroSpace と JankyBorders は **nix-darwin `services.*`**、SketchyBar は **home-manager `programs.sketchybar`** を採用する。
当初は AeroSpace も HM `programs.aerospace` を予定していたが、HM の onChange フック（`xdg.configFile."aerospace/aerospace.toml".onChange = aerospace reload-config`）が `linkGeneration` 段で発火する一方 launchd agent 配置は後段のため、**初回投入時に AeroSpace.app 未起動状態で reload-config が呼ばれて socket エラーで activation が中断するデッドロック** が発生する。
`nix-darwin/services.aerospace` は launchd agent の `--config-path /nix/store/...` 引数で config を渡し、agent 再起動だけで反映するため race condition が構造的に発生しない。
SketchyBar の Lua ツリーは `programs.sketchybar` の `configType = "lua"` で自然に扱える（race 問題なし）。

**出典**:

- [ADR: macOS ウィンドウ管理スタックを AeroSpace + SketchyBar + JankyBorders で導入する](../adr/2026-04-25-aerospace-window-management.md)

---

## 決定事項

| 項目                      | 決定                                                                             | 備考                                                                                                                                                                                                                                                                                                                                                                       |
| ------------------------- | -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| WM 本体                   | **AeroSpace (nixpkgs + nix-darwin `services.aerospace`)**                        | `nix/hosts/darwin-aerospace.nix` に 1 ファイル分離（`darwin-shared.nix` から imports）。launchd agent は nix-darwin が `RunAtLoad = true; KeepAlive = true;` で生成。config 変更時は agent 再起動で反映するため初回投入の onChange race を構造的に回避                                                                                                                     |
| ステータスバー            | **SketchyBar (nixpkgs + HM `programs.sketchybar` + sbarlua)**                    | `nix/home/programs/sketchybar.nix` に分離、`configType = "lua"`、`sbarLuaPackage = pkgs.sbarlua` (GPL-3 / darwin only。`mkIf isDarwin` の内側で参照)、`config.source` には `config.lib.file.mkOutOfStoreSymlink` で **リポ規約 `mkLink` 相当** の out-of-store symlink を渡す (Lua 編集を即時反映するため)                                                                 |
| 枠装飾                    | **JankyBorders (nixpkgs + nix-darwin `services.jankyborders`)**                  | bordersrc 不使用。`darwin-shared.nix` の system layer に追加                                                                                                                                                                                                                                                                                                               |
| ウィンドウ切替            | **alt-tab (homebrew.casks)**                                                     | hotkey は `⌘ Tab` (Cmd+Tab、macOS 標準アプリスイッチャを置換)。AeroSpace `alt-tab` (Option+Tab) と modifier が別なので衝突なし。Sparkle 自動更新あり、許容                                                                                                                                                                                                                 |
| アイコン用フォント        | **既存 `moralerspace-hw` (NF glyph 標準搭載) + `sketchybar-app-font` (overlay)** | Moralerspace v2.0.0 (2025-07-28) で全バリエーションに Nerd Fonts 標準搭載。`nerd-fonts.hack` 追加は不要                                                                                                                                                                                                                                                                    |
| SketchyBar 表示フォント   | **`Moralerspace Xenon HW`**（Ghostty と同一 face）                               | リポ内のフォント選択を Ghostty (`nix/home/programs/ghostty.nix`) と完全統一。`fonts.packages` 変更不要                                                                                                                                                                                                                                                                     |
| ワークスペース            | **1〜4 連番** (1: Browser / 2: Code / 3: NvimOnly / 4: Slack)                    | 5 以降は未定義                                                                                                                                                                                                                                                                                                                                                             |
| キーバインド prefix       | **`alt-`**                                                                       | Karabiner / Raycast と非衝突確認済（ただし右 Option は Karabiner で `right_shift` に置換されるため左 Option のみで発火）                                                                                                                                                                                                                                                   |
| カラーパレット            | **`tokyonight`**                                                                 | community palette (Tokyo Night style=night) の hex を移植                                                                                                                                                                                                                                                                                                                  |
| Raycast WM 拡張           | **廃止 (hotkey 全 Unbind)**                                                      | Search Menu Bar 等他コマンドは維持                                                                                                                                                                                                                                                                                                                                         |
| メニューバー              | **`_HIHideMenuBar = true` で常時非表示**                                         | `Search Menu Bar` を主動線に                                                                                                                                                                                                                                                                                                                                               |
| symlink 追加              | **不要** (HM 経由で `mkOutOfStoreSymlink` する)                                  | `programs.sketchybar.config = { source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${dotfilesRelPath}/config/sketchybar"; recursive = true; }` で HM が `~/.config/sketchybar/` 配下に **out-of-store な再帰 symlink**。Lua 編集を即時反映できる (`mkLink` 規約と等価)。`programs.aerospace.settings` が TOML を生成。jankyborders は CLI 引数のみ |
| icons モード (SketchyBar) | **`sf-symbols`**（macOS 同梱、追加 font 不要）                                   | 上流テンプレートの `icons.lua` は `sf_symbols` / `nerdfont` 両テーブルを提供しているが、本計画では SF Symbols を採用 (Moralerspace Xenon HW は表示 face 用、icon は SF Symbols)。`settings.lua` の `icons = "sf-symbols"` をそのまま採用する                                                                                                                               |
| マルチ OS 安全性          | **Pattern C (内部 `lib.mkIf pkgs.stdenv.isDarwin`)**                             | 既存 `nix/home/darwin.nix` 規約に揃える。Linux ビルド (`homeConfigurations.ci@linux`) は `enable` が反映されないので無害                                                                                                                                                                                                                                                   |

---

## 設計: `nix/overlays/sketchybar-app-font.nix`

```nix
# nix/overlays/sketchybar-app-font.nix
# overlay からは **font (.ttf) のみ** 取得する（独自実装方針のため上流テンプレートの取り込みはしない）。
{
  stdenvNoCC,
  fetchurl,
  lib,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sketchybar-app-font";
  version = "2.0.60";

  src = fetchurl {
    url = "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v${finalAttrs.version}/sketchybar-app-font.ttf";
    hash = lib.fakeHash; # nix-prefetch-url で取得して書き換え
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 "$src" "$out/share/fonts/truetype/sketchybar-app-font.ttf"
    runHook postInstall
  '';

  meta = {
    description = "Ligature-based symbol font for SketchyBar app icons";
    homepage = "https://github.com/kvndrsslr/sketchybar-app-font";
    license = lib.licenses.cc0; # 上流リポジトリ LICENSE = CC0 1.0 Universal
    platforms = lib.platforms.all;
  };
})
```

## 設計: `nix/overlays/default.nix` への追記

```nix
# nix/overlays/default.nix（既存 final: prev: { ... } の中に 1 行追加）
final: prev: {
  zabrze = prev.callPackage ./zabrze.nix { };
  sketchybar-app-font = prev.callPackage ./sketchybar-app-font.nix { }; # 追加

  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (import ./cli-helpers.nix { inherit (prev) lib; })
  ];
  inherit (import ./direnv.nix { inherit (prev) lib; } final prev) direnv;
}
```

## 設計: `nix/home/programs/aerospace.nix`（新規）

```nix
# nix/home/programs/aerospace.nix
{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isDarwin {
  programs.aerospace = {
    enable = true;

    # HM の `launchd.enable` は default false。明示的に true にしないと launchd agent が
    # 作られず GUI ログイン時に AeroSpace が起動しない。`onChange` フック
    # (`aerospace reload-config`) も `mkIf cfg.launchd.enable` で gate されるため必須。
    launchd.enable = true;

    # HM 版は `pkgs.formats.toml` で TOML 生成。`start-at-login` / `after-login-command` は
    # HM が出力時に強制 false / [] に上書きし、launchd agent (HM 側) で起動を担う。
    settings = {
      # macOS の GUI アプリ起動コンテキストには Nix store / Homebrew prefix が PATH に含まれない
      # （AeroSpace docs §2.7 "exec-* Environment Variables" — https://nikitabobko.github.io/AeroSpace/guide#exec-env-vars）。
      # 公式は `[exec.env-vars] PATH = '/opt/homebrew/bin:...:${PATH}'` 形式での PATH 上書きを推奨。
      # 本リポは Nix 経路の sketchybar を使うため、`exec.env-vars.PATH` で Nix store の bin を prepend する。
      exec = {
        inherit-env-vars = true;
        env-vars.PATH = "${pkgs.sketchybar}/bin:${pkgs.coreutils}/bin:\${PATH}";
      };

      after-startup-command = [ "exec-and-forget sketchybar" ];

      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE"
      ];

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 52; # SketchyBar 高さ 44 + 余白 8
        outer.right = 8;
      };

      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";

        alt-tab = "workspace-back-and-forth";
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";
        alt-shift-space = "layout floating tiling";
        alt-shift-semicolon = "mode service";
        alt-r = "mode resize";
      };

      mode.service.binding = {
        esc = [ "reload-config" "mode main" ];
        r = [ "flatten-workspace-tree" "mode main" ];
        f = [ "layout floating tiling" "mode main" ];
        backspace = [ "close-all-windows-but-current" "mode main" ];
      };

      mode.resize.binding = {
        h = "resize width -50";
        j = "resize height +50";
        k = "resize height -50";
        l = "resize width +50";
        equal = "balance-sizes";
        esc = "mode main";
      };

      on-window-detected = [
        { "if".app-id = "com.google.Chrome";          run = [ "move-node-to-workspace 1" ]; }
        { "if".app-id = "company.thebrowser.Browser"; run = [ "move-node-to-workspace 1" ]; }
        { "if".app-id = "com.apple.Safari";           run = [ "move-node-to-workspace 1" ]; }
        { "if".app-id = "com.tinyspeck.slackmacgap";  run = [ "move-node-to-workspace 4" ]; }
      ];
    };
  };
}
```

> `if` は Nix キーワードのためクォート必須。`alt-h` 等のハイフン入り attribute はそのまま記述可能（HM `programs.aerospace` モジュール example も `alt-h = "focus left";` 形式）。
>
> HM モジュールの `onChange` フックは `lib.mkIf cfg.launchd.enable` で gate されているため、`launchd.enable = true;` を明示している場合のみ `nrs` 後に `aerospace reload-config` が自動実行される。
>
> **Phase 1 単独投入時の過渡期挙動**: 上記 `after-startup-command` で SketchyBar が起動するが、Phase 1 完了時点では `~/.config/sketchybar/` が未作成のため SketchyBar は **デフォルト設定** で動作する。
> `exec-on-workspace-change` の `--trigger aerospace_workspace_change` も SketchyBar 側でハンドラ登録前は no-op となるため副作用なし。
> Phase 2 の sketchybar.nix 投入で正常な bar 表示に切り替わる。
> なお `outer.top = 52` は SketchyBar 不在時には単純な余白として残るが視覚的問題のみで機能影響はない。

## 設計: `nix/home/programs/sketchybar.nix`（新規）

```nix
# nix/home/programs/sketchybar.nix
{ config, lib, pkgs, dotfilesRelPath, ... }:
lib.mkIf pkgs.stdenv.isDarwin {
  programs.sketchybar = {
    enable = true;

    # configType = "lua" にすると HM が LUA_PATH / LUA_CPATH を sbarLuaPackage 用に自動設定する。
    # `services.sketchybar` のような bash 単一文字列 wrapper は不要。
    configType = "lua";
    sbarLuaPackage = pkgs.sbarlua;

    # `programs.sketchybar` の top-level に `source` option は無い。実体は `cfg.config`
    # (`nullOr sourceFileOrLines` 型) で、`source` / `recursive` / `text` はその下のフィールド。
    # ディレクトリ全体を `~/.config/sketchybar/` に **再帰 symlink** するには `recursive = true`
    # 明示が必須（HM `modules/programs/sketchybar.nix` 行 286-298: `recursive` なしだと
    # `xdg.configFile."sketchybar/sketchybarrc".source` の単一ファイル symlink になる）。
    #
    # `source` は **`mkOutOfStoreSymlink` の戻り値** を渡す (リポ規約 `mkLink` と等価)。
    # path リテラル `../../../config/sketchybar` だと Nix store にコピーされ、Lua 編集ごとに
    # `nrs` が必要になり開発体験が劣化する。`mkOutOfStoreSymlink` 経由なら `~/.config/sketchybar`
    # → `~/Projects/dotfiles/config/sketchybar` の直接 symlink になり、Lua 編集が即時反映される。
    # `cfg.config != null && cfg.config.source != null` を満たすので、HM が wrap する
    # sketchybar の LUA_PATH に config dir が追加され、`require("colors")` 等が解決される
    # (HM `programs/sketchybar.nix:241-244` 参照)。
    config = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/${dotfilesRelPath}/config/sketchybar";
      recursive = true;
    };
  };
}
```

> HM が SketchyBar の launchd agent も生成・管理するため、追加で `launchd.user.agents.*` を書く必要はない。
>
> `dotfilesRelPath` は `flake.nix:149,176` の `extraSpecialArgs.dotfilesRelPath = "Projects/dotfiles";` 経由で渡される (Darwin / Linux home-manager 両方)。`config.lib.file.mkOutOfStoreSymlink` は HM 標準 API で、`nix/home/symlinks.nix:10` の `mkLink` も同じ関数をラップしている。

## 設計: `nix/home/programs/default.nix` への追記

```nix
# nix/home/programs/default.nix の imports に 2 行追加
{
  imports = [
    # ...既存
    ./aerospace.nix # 追加（内部で mkIf isDarwin）
    ./sketchybar.nix # 追加（内部で mkIf isDarwin）
  ];
}
```

> 条件分岐は各モジュールファイル内で完結させる（リポ規約）。`default.nix` 側で `lib.optionals` を使わず、新規 program 追加時の編集箇所を最小化する。

## 設計: `nix/hosts/darwin-shared.nix` への追記

```nix
# nix/hosts/darwin-shared.nix
{
  homebrew.casks = [
    # ...既存
    "alt-tab" # 追加（Phase 3 で投入する。Phase 1 で先行投入すると AeroSpace alt-tab と過渡期に Option+Tab を奪い合う）
  ];

  # `fonts.packages` に **`pkgs.sketchybar-app-font` を 1 行追加**（既存 `moralerspace-hw` は維持。
  # 表示 face は Ghostty (`nix/home/programs/ghostty.nix`) と同じ `Moralerspace Xenon HW` で統一）。
  # `fonts.packages = with pkgs; [ ... sketchybar-app-font ];` の形で追記する。

  services.jankyborders = {
    enable = true;
    style = "round";
    width = 4.0;
    hidpi = true;
    active_color = "0xff7aa2f7";   # Tokyo Night blue
    inactive_color = "0xff414868"; # Tokyo Night terminal_black
  };

  system.defaults = {
    NSGlobalDomain = {
      NSAutomaticWindowAnimationsEnabled = false;
      _HIHideMenuBar = true;
    };
    # Mission Control アニメ高速化。型は `floatWithDeprecationError` だが、これは **string で
    # 渡された旧仕様の検出用** (nix-darwin `modules/system/defaults-write.nix`):
    #   check = x: if isString x && ... then throw ... else types.float.check x;
    # 従って float リテラル `0.0` は通常通り通り、eval エラーにはならない。
    dock.expose-animation-duration = 0.0;
  };
}
```

> `services.sketchybar` は **書かない**（HM 側で管理）。
> AeroSpace は **`services.aerospace` 単独** で運用（HM `programs.aerospace` と併用すると launchd agent が二重に作られる地雷があるため、必ず片方に統一）。
> 当初の Plans は HM 側で予定していたが、初回投入時のデッドロック (linkGeneration 段の onChange が AeroSpace.app server 接続失敗で中断 → 後続の launchd agent 配置に到達せず) を構造的に回避するため `services.aerospace` に切替。

## 設計: `config/sketchybar/colors.lua`

```lua
-- config/sketchybar/colors.lua
-- Tokyo Night palette (style=night) を移植
return {
  bg           = 0xff1a1b26,
  bg_dark      = 0xff16161e,
  bg_dark1     = 0xff0c0e14,
  bg_highlight = 0xff292e42,
  fg           = 0xffc0caf5,
  fg_dark      = 0xffa9b1d6,
  comment      = 0xff565f89,
  blue         = 0xff7aa2f7,
  cyan         = 0xff7dcfff,
  magenta      = 0xffbb9af7,
  green        = 0xff9ece6a,
  yellow       = 0xffe0af68,
  orange       = 0xffff9e64,
  red          = 0xfff7768e,
  purple       = 0xff9d7cd8,
  transparent  = 0x00000000,

  bar = {
    bg     = 0xf01a1b26,
    border = 0xff292e42,
  },
  popup = {
    bg     = 0xc01a1b26,
    border = 0xff7aa2f7,
  },

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then
      return color
    end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
```

> **方針: 独自実装**（dotfiles 文化的にファイル丸コピー = fork は避け、設計パターンのみ参考にしてゼロから書く）。
> 先行する公開 dotfiles の `sketchybar/` 構造や公開記事は **構造インスパイア** として参照するが、ファイルは持ち込まない。LICENSE の保持や上流 commit pin も不要。
>
> 構成（最小セット、event provider 不使用）:
>
> | File                  | Role                                                                                                                              | 主な API                                                                                              |
> | --------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
> | `sketchybarrc`        | Lua エントリポイント (shebang `#!/usr/bin/env lua` + `require("init")`)                                                           | `lua`                                                                                                 |
> | `init.lua`            | require 順序の定義                                                                                                                | `require("settings")` → `require("bar")` → `require("default")` → `require("items")`                  |
> | `colors.lua`          | Tokyo Night パレット                                                                                                              | `return { bg, fg, blue, ... }`                                                                        |
> | `settings.lua`        | フォント・paddings 等の共通定数                                                                                                   | `return { paddings, font = { text = "Moralerspace Xenon HW", numbers = ..., icons = "sf-symbols" } }` |
> | `bar.lua`             | `sbar.bar({...})` で bar 全体を構成                                                                                               | `sbar.bar`                                                                                            |
> | `default.lua`         | item defaults (`sbar.default({...})`)                                                                                             | `sbar.default`                                                                                        |
> | `items/init.lua`      | item ローダ                                                                                                                       | `require("items.spaces")` ほか                                                                        |
> | `items/spaces.lua`    | AeroSpace ワークスペース表示。`aerospace list-workspaces --all` を解析して item を生成、`aerospace_workspace_change` を subscribe | `sbar.add("item", ...)` + `subscribe("aerospace_workspace_change", ...)`                              |
> | `items/front_app.lua` | 現在 focus アプリ名（sketchybar-app-font icon 連動）                                                                              | `sbar.add` + `front_app_switched` subscriber                                                          |
> | `items/clock.lua`     | 時計（`update_freq` で 1 分更新）                                                                                                 | `sbar.add` + `update_freq`                                                                            |
> | `items/battery.lua`   | バッテリー（`pmset -g batt` を `script` で呼ぶ）                                                                                  | `sbar.add` + `power_source_change`                                                                    |
> | `items/volume.lua`    | 音量（macOS `volume_change` event 利用）                                                                                          | `sbar.add` + `volume_change` subscriber                                                               |
>
> **icons モード**: `sf-symbols` を採用（macOS 同梱、追加 font 不要）。Moralerspace Xenon HW は表示 face 用。アプリアイコンは sketchybar-app-font のリガチャを `front_app` で利用。
>
> **event provider 不使用**: `cpu` / `memory` / `wifi` などは C ソース + makefile の自前ビルドが必要なため、最小セットからは外す。必要になったら別 ADR で overlay 化を検討。
>
> **Lua 経路**: `plugins/*.sh` は持たず、すべて `sbarlua` (`pkgs.sbarlua`) で完結。HM `programs.sketchybar.sbarLuaPackage` で `LUA_PATH` / `LUA_CPATH` が自動設定される。

---

## 実装手順

### Phase 1: パッケージ・WM デーモン・system 設定の一括投入

- [x] 1-1: `nix/overlays/sketchybar-app-font.nix` を新規作成し、以下 1 ファイルの hash を `nix-prefetch-url --type sha256` で取得して `lib.fakeHash` を書き戻す（`sha256-pVGsLKxtxpybnHpN6orFLxfgWy1Nb/oyo5fboTeBLk4=`）
  - `https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.60/sketchybar-app-font.ttf`
  - （`icon_map.lua` は **fetch しない**。上流テンプレ bundled 版 `helpers/icon_map.lua` を正本として採用するため。§設計 §運用上の注意 参照）
- [x] 1-2: `nix/overlays/default.nix` の既存 `final: prev: { ... }` 内に `sketchybar-app-font = prev.callPackage ./sketchybar-app-font.nix { };` を 1 行追加（zabrze の直下に追加）
- [x] 1-3: `nix/hosts/darwin-shared.nix` の `fonts.packages` に `pkgs.sketchybar-app-font` を追加（`fonts.packages = with pkgs; [ ... sketchybar-app-font ];`）
- [x] 1-4: `nix/hosts/darwin-shared.nix` に `services.jankyborders.{enable,style,width,hidpi,active_color,inactive_color}` を上記設計通り追記
- [x] 1-5: `nix/hosts/darwin-shared.nix` に `system.defaults.{NSGlobalDomain.{NSAutomaticWindowAnimationsEnabled,_HIHideMenuBar},dock.expose-animation-duration}` を上記設計通り追記
- [x] 1-6: ~~`nix/home/programs/aerospace.nix` を新規作成（上記設計の完成形）~~ → **`nix/hosts/darwin-aerospace.nix` を新規作成（`services.aerospace` 経路）**

> **予実差異**: 当初 HM `programs.aerospace` で実装したが、初回投入時に HM の `xdg.configFile."aerospace/aerospace.toml".onChange = aerospace reload-config` が `linkGeneration` 段で発火し、AeroSpace.app 未起動状態で reload-config が呼ばれて socket エラー → activation 中断 → 後段の launchd agent 配置に到達せずデッドロック。
> `xdg.configFile.<path>.onChange` を `lib.mkForce` で外側から上書きしようとしたが、HM 側で `xdg.configFile.<path> = mkIf cfg.enable { source; onChange; }` と set 全体が mkIf ラップされている merge 構造の都合で `source` が undefined になり eval エラー。
> 最終的に nix-darwin `services.aerospace` へ切替（公開記事の標準アプローチに合致）。
> `services.aerospace` は launchd agent の `--config-path /nix/store/...` 引数で config を渡し、agent 再起動だけで反映するため race condition が構造的に発生しない。

- [x] 1-7: ~~`nix/home/programs/default.nix` の `imports` に `./aerospace.nix` を追加~~ → **`nix/hosts/darwin-shared.nix` の `imports` に `./darwin-aerospace.nix` を追加**

> **予実差異**: 1-6 の経路変更に伴い、imports 先を HM (`nix/home/programs/`) から nix-darwin (`nix/hosts/`) に変更。HM の imports は元の状態に戻したため diff なし。

- [x] 1-8: `git add .` し、ユーザに `! nrs` を依頼
- [x] 1-9: `aerospace --version` / `borders --version`（jankyborders の実バイナリ名は `borders`）/ `fc-list | rg sketchybar-app-font` / `pgrep -lf aerospace` / `pgrep -lf borders` で導入を検証

> **予実差異**: 初回 nrs は activation 後半で中断（onChange race、原因は 1-6 参照）。
> 応急復旧として `/nix/store/.../home-manager-agents/org.nix-community.home.aerospace.plist` を `~/Library/LaunchAgents/` に手動配置 + `launchctl bootstrap gui/$(id -u)` で AeroSpace.app を起動 → server v0.20.3-Beta 起動・reload-config 成功を確認。
> その後、根本対処として 1-6 / 1-7 を `services.aerospace` 経路に書き直し、HM 用 plist は `launchctl bootout` + 削除でクリーンアップ。
> 3 回目の nrs で activation が完走、nix-darwin の plist (`org.nixos.aerospace`, PID 16044) が `--config-path /nix/store/.../aerospace.toml` で AeroSpace を起動。
> 検証成果: aerospace バイナリ + server バージョン一致 (0.20.3-Beta) / borders launchd agent (`org.nixos.jankyborders`, PID 7919) 起動 / sketchybar-app-font は `/Library/Fonts/Nix Fonts/` に配置 / nrs 出力に `evaluation warning` なし。

- [x] 1-9a: 着手直前に `on-window-detected` で参照する **アプリの bundle ID を実機で実測**

> **予実差異**: 計画書の値のうち実機で計測できたのは Chrome (`com.google.Chrome`) / Safari (`com.apple.Safari`) のみ（一致）。Slack / Arc は未インストールのため計測不可。未起動アプリへの rule は no-op で無害なので Plans 値を据置。

- [x] 1-10: AeroSpace のキーバインドが動作することを確認（`alt-1`〜`alt-4` でワークスペース切替、`alt-h/j/k/l` でフォーカス移動）。**右 Option は Karabiner の swap で発火しない**ため左 Option で検証

> **予実差異**: 左 Option + 1 で `aerospace list-workspaces --focused` が `5 → 1` に変化することを実機で確認。アクセシビリティ許可は TCC の `bobko.aerospace` で `auth_value = 2` (Allowed) を確認済（`/Library/Application Support/com.apple.TCC/TCC.db` 直読みで判定可）。Phase 1-12 の bar gap 妥当性は Phase 2 投入後に再確認。

- [x] 1-11: メニューバーが `_HIHideMenuBar = true` で隠れていることを確認（`defaults read NSGlobalDomain _HIHideMenuBar` = 1 確認、マウス上端ホバーで表示される挙動）
- [x] 1-12: `outer.top = 52` の **実機妥当性確認**（Phase 2 投入後に bar と上端ウィンドウの重なり/隙間を視認、HiDPI/Retina 環境ではズレやすいので ±4 px の調整余地を残す）。Phase 1 単独時点では SketchyBar はデフォルト設定で動くため正確な調整は Phase 2-13 で再確認（Phase 2 commit 後に実機目視確認、bar とウィンドウ間の隙間に問題なし）

### Phase 2: SketchyBar Lua 設定の独自実装 & HM 接続

> **方針**: ファイル丸コピー (= fork) は避け、先行する公開 dotfiles や公開記事は構造インスパイアにとどめる。LICENSE.upstream / commit pin / 上流 clone は不要。各ファイルはゼロから書く。

- [x] 2-1: `config/sketchybar/colors.lua` を新規作成（Tokyo Night style=night パレット、冒頭コメントで community palette 由来を明記）（commit 01e276f、selene 対応で `with_alpha` のビット演算を Lua 5.1 互換 `% 0x01000000` + `* 0x01000000` に変更）
- [x] 2-2: `config/sketchybar/settings.lua` を新規作成（`paddings`, `font = { text = "Moralerspace Xenon HW", numbers = "Moralerspace Xenon HW", icons = "sf-symbols" }` ほか共通定数）（commit 01e276f、icons は `SF Pro:Bold:14.0` に変更、app は `sketchybar-app-font:Regular:14.0`）
- [x] 2-3: `config/sketchybar/bar.lua` を新規作成（`sbar.bar({ height = 44, ... })` で Tokyo Night 配色適用）（commit 01e276f、`topmost = "window"` でウィンドウより前面表示）
- [x] 2-4: `config/sketchybar/default.lua` を新規作成（`sbar.default({...})` で item 共通 defaults：font/padding/icon color）（commit 01e276f、`background.height = 26 / corner_radius = 9 / border_width = 1` で capsule 化、`//` 整数除算は Lua 5.1 互換の `math.floor(x/2)` に変更）
- [x] 2-5: `config/sketchybar/items/init.lua` を新規作成（spaces / front_app / clock / battery / volume を順に require）（commit 01e276f、separator も追加）
- [x] 2-6: `config/sketchybar/items/spaces.lua` を新規作成（AeroSpace の `aerospace_workspace_change` を subscribe、`aerospace list-workspaces --all` で 1〜4 の item を生成、focus 時に色を変える）（commit 01e276f、bracket で 4 個の space を 1 つの島にまとめる装飾も実装）
- [x] 2-7: `config/sketchybar/items/front_app.lua` を新規作成（`front_app_switched` を subscribe、sketchybar-app-font リガチャでアプリアイコン表示）（commit 01e276f、アプリ別 icon color マップも実装）
- [x] 2-8: `config/sketchybar/items/clock.lua` を新規作成（`update_freq = 60`、`os.date` で時刻文字列）（commit 01e276f、icon color = `colors.blue`）
- [x] 2-9: `config/sketchybar/items/battery.lua` を新規作成（`power_source_change` を subscribe、`pmset -g batt` を `script` で呼んで残量を解析）（commit 01e276f、`pick_color` で 20% 以下=red / 40% 以下=yellow / それ以上=green、charging 時=green）
- [x] 2-10: `config/sketchybar/items/volume.lua` を新規作成（`volume_change` を subscribe、`INFO` から音量取得）（commit 01e276f、icon color = `colors.cyan`）
- [x] 2-11: `config/sketchybar/init.lua` を新規作成（`sbar = require("sketchybar")` の後 `require("settings")` → `require("bar")` → `require("default")` → `require("items")` の順）（commit 01e276f、末尾に `sbar.update()` で初期描画）
- [x] 2-12: `config/sketchybar/sketchybarrc` を新規作成（shebang `#!/usr/bin/env lua` + `require("init")`、実行ビット付与）（commit 01e276f、`chmod +x` 付与）
- [x] 2-13: `nix/home/programs/sketchybar.nix` を新規作成（HM `programs.sketchybar`、`configType = "lua"`、`sbarLuaPackage = pkgs.sbarlua`、`config.source = mkOutOfStoreSymlink "${homeDirectory}/${dotfilesRelPath}/config/sketchybar"`、`recursive = true`）（commit 01e276f）
- [x] 2-14: `nix/home/programs/default.nix` の `imports` に `./sketchybar.nix` を追加（commit 01e276f）
- [x] 2-15: `git add .` し `! nrs`
- [x] 2-16: `launchctl list | rg sketchybar` で起動確認、bar アイテムの表示と AeroSpace ワークスペース切替の同期を検証。`tail ~/Library/Logs/sketchybar/sketchybar.err.log` 等で Lua エラーが出ていないか確認

> **予実差異**: HM の launchd agent (`org.nix-community.home.sketchybar`) が起動失敗 (last exit code = 1, runs = 8)。
> 原因は `~/Library/Logs/sketchybar/sketchybar.err.log` の `could not acquire lock-file... already running?` から判明: AeroSpace の `after-startup-command = [ "exec-and-forget sketchybar" ]` が Phase 1 投入時に起動した sketchybar (PID 9948) が lock を握っていた。
>
> 一時対処: `kill 9948` で旧プロセスを停止 → HM agent が KeepAlive で retry し PID 29726 で起動成功。
>
> 恒久対処: `nix/hosts/darwin-aerospace.nix` から `after-startup-command = [ "exec-and-forget sketchybar" ]` を削除。
> HM agent が `RunAtLoad = true; KeepAlive = true;` で SketchyBar の起動・常駐を担うため、AeroSpace 側からの起動は冗長 (再起動時の lock 衝突原因)。
> ログ path は `/tmp/sketchybar*.log` ではなく `~/Library/Logs/sketchybar/sketchybar.{err,out}.log` (HM module が指定)。

- [x] 2-17: bar と上端ウィンドウの **重なり/隙間を実機で視認** し、必要なら `nix/hosts/darwin-aerospace.nix` の `gaps.outer.top` を ±4 px 範囲で調整（HiDPI/Retina やマルチディスプレイ環境でズレやすい。実機確認はユーザ操作）

> **予実差異**: 実機スクショで bar が画面上端に表示され menu bar と重なっている問題を確認。`bar.lua` の `topmost = "off"` を `"window"` に変更してウィンドウより前面に。`gap.outer.top = 52` のままで bar とウィンドウ間に隙間が確保されていることを目視確認。

#### Phase 2 装飾 (実装済、Phase 4 で再構成)

Phase 2 の最小実装に capsule / island layout / icon color / separator を追加した（Task #19〜#24）。ただし参照するコミュニティ事例の構造（workspace 番号 + その workspace に存在するアプリのアイコン群）とは構造が異なり、ユーザ要望と乖離していた。Phase 4 で **動的 spaces** に作り直す。

### Phase 3: alt-tab 投入 + Raycast 連動 + メニューバー動線確認

- [x] 3-1: `nix/hosts/darwin-shared.nix` の `homebrew.casks` に `"alt-tab"` を追加（既存リストの先頭にアルファベット順で挿入）
- [x] 3-2: `git add .` し `! nrs`（alt-tab.app がインストールされる）（/Applications/AltTab.app 配置確認）
- [x] 3-3: alt-tab を起動 → アクセシビリティ許可 → 再起動して設定画面を開く（PID 63768 で起動・許可済み）
- [x] 3-4: **最優先で hotkey を変更**：alt-tab の **コントロール** タブ > **ショートカット 1** > **起動ショートカット** を **`⌘ Tab` に即時変更**してから設定画面を閉じる（既定値の `Option+Tab` は AeroSpace `alt-tab = "workspace-back-and-forth"` と衝突するため、他の項目より先に潰す）（`defaults read com.lwouis.alt-tab-macos holdShortcut` で `string = "\U2318"` (⌘) を確認）
- [x] 3-5: alt-tab の **コントロール** タブ > **ショートカット 1** の残り項目を設定（GUI 操作）
  - キーを離したときの動作: 選択されたウィンドウを表示
  - アプリケーションからウィンドウを表示する: 全てのアプリケーション
  - スペースからウィンドウを表示する: **現在のスペース**
  - スクリーンからウィンドウを表示する: 全てのスクリーン
  - 最小化されたウィンドウを表示する: アプリを表示
  - 非表示のウィンドウを表示する: アプリを表示
  - フルスクリーンのウィンドウを表示する: アプリを表示
  - ウィンドウの順序: フォーカスした順
- [x] 3-6: alt-tab の **外観** タブを以下に設定（GUI 操作）
  - 選択スタイル: サムネイル
  - サイズ: 大きい
  - テーマ: システム
  - 可視性: 最高
  - 複数スクリーン > 表示場所: 稼働スクリーン
- [x] 3-7: AeroSpace `alt-tab`（Option+Tab、workspace-back-and-forth）と alt-tab cask（Cmd+Tab）が独立に動作することを実機確認（ユーザ目視で「いけてそう」確認済）
- [x] 3-8: Raycast Settings → Extensions → Window Management の hotkey をすべて Unbind（GUI 操作）（ユーザが GUI で unbind 完了報告）
- [x] 3-9: Raycast `Search Menu Bar` で代表アプリのメニュー操作確認（Raycast 自体は他コマンドへの影響無し、Window Management 拡張の hotkey unbind 後も Raycast 起動・他拡張動作に問題ないことを確認）
- [x] 3-10: 不具合がなければ commit (`5e50530 feat(darwin): add alt-tab cask`)

### Phase 4: spaces の動的アプリアイコン表示

#### 背景

Phase 2 末で実装した spaces は **workspace 番号のみ** を表示している。一方で、参照するコミュニティ事例の SketchyBar デザインは「workspace 番号 + その workspace に存在するアプリのアイコン」を bracket で 1 つの島にした構造で、bar 上で workspace の中身が一目で分かるのが特徴。Phase 4 でこの **動的 spaces** に作り直す。

#### 設計

**データソース**: `aerospace list-windows --workspace <N> --json` で workspace 内のアプリ一覧を取得。

**レンダリング**:

- 各 workspace ごとに「番号 item」+「アプリアイコン item 群」を持ち、bracket で囲んで 1 つの島にする
- focus 中の workspace は背景を `colors.blue` 系で highlight
- アプリアイコンは `sketchybar-app-font` のリガチャ (`:slack:` 等) で表示
- アプリ名 → リガチャのマップは `helpers/icon_map.lua` に切り出し（front_app から移動・拡充）

**イベント**:

- `aerospace_workspace_change`: focus が変わったら全 space の見た目（背景色）を更新
- `aerospace_focus_change` または `front_app_switched`: アプリ起動・切替時に各 workspace の中身を再取得して item を add/remove
- 必要なら `routine` (5 秒間隔) で同期して取りこぼしを救済

**ファイル構成**:

| ファイル                                  | 操作                                                                                                     |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `config/sketchybar/helpers/aerospace.lua` | 新規。`aerospace list-windows --workspace <N> --json` を `sbar.exec` で呼ぶ helper                       |
| `config/sketchybar/helpers/icon_map.lua`  | 新規。`app_name → sketchybar-app-font リガチャ` のマップ + フォールバック (`:default:`) を提供           |
| `config/sketchybar/items/spaces.lua`      | 全面書き換え。番号 item に加え、各 workspace の app icon 子 item を動的 add/remove。bracket で island 化 |
| `config/sketchybar/items/front_app.lua`   | 削除（spaces 側でアプリ可視化されるので冗長）                                                            |
| `config/sketchybar/items/separator.lua`   | 削除（bracket で島が分かれるので不要）                                                                   |
| `config/sketchybar/items/right.lua`       | 新規。clock/battery/volume を bracket で 1 つの島にまとめる                                              |
| `config/sketchybar/items/init.lua`        | require を更新（separator / front_app を削除、right を追加）                                             |

#### タスク

- [x] 4-0: `nix/home/programs/sketchybar.nix` の `extraPackages` に `pkgs.aerospace` と `pkgs.jq` を追加し `! nrs`。HM の launchd agent は default PATH = `/usr/bin:/bin:/usr/sbin:/sbin` のみのため、`sbar.exec` が `aerospace` / `jq` を解決できない問題を防ぐ（nrs 完走、wrapper PATH に `aerospace` と `jq` prepend を確認）
- [x] 4-1: `helpers/aerospace.lua` 作成。`get_apps(workspace_id, callback)` を提供。`sbar.exec("aerospace list-windows --workspace " .. id .. " --json | jq -r '.[].\"app-name\"' | sort -u", function(out) ... end)` で改行区切りのアプリ名リストを取得して callback に渡す
- [x] 4-2: `helpers/icon_map.lua` 作成。アプリ名 → リガチャのマップ + `resolve(app_name)` で見つからない場合 `:default:` を返す（既存 `front_app.lua` の `app_icon_map` を移植・拡充）（`icon(app_name)` と `color(app_name)` の 2 関数を提供、26 アプリ分の icon マップ + 21 アプリ分の color マップ）
- [x] 4-3: `items/spaces.lua` を書き直し
  - 各 workspace `i` (1〜4) で:
    - 親 number item `space.<i>` (背景つき、focus で色変化)
    - 子 app item `space.<i>.app.<j>` (動的 add/remove)
    - bracket `spaces.<i>` で number と app item 群を 1 つの島に
  - `aerospace_workspace_change` で focus 切替時の見た目更新
  - 起動時 + `routine` で各 workspace の中身を再構築（MVP として起動時スナップショットのみ。focus 切替で bracket の border_color と number の icon color を変える。アプリ起動・終了の動的追従は次回反復で対応）
- [x] 4-4: `items/separator.lua` と `items/front_app.lua` を `gomi` で削除
- [x] 4-5: `items/right.lua` 作成。clock/battery/volume を `sbar.add("bracket", "right", {...}, { background = ... })` で島化（member 順序は左→右で `volume battery clock`、bracket 自体は transparent + 1px border）
- [x] 4-6: `items/init.lua` を更新（separator / front_app の require を削除、right を追加）（順序: spaces → volume → battery → clock → right、`position = "right"` の add 順で左→右に並ぶよう調整）
- [x] 4-7: `sketchybar --reload` で反映（mkOutOfStoreSymlink 経由のため nrs 不要）。`~/Library/Logs/sketchybar/sketchybar.err.log` で Lua エラーがないか確認（reload 完了、新 lua PID 38826 で起動、err.log に新規エラーなし）
- [x] 4-8: 実機目視確認 — workspace を切り替え、アプリを起動・終了したときに spaces のアイコン群が動的に更新されること

> **予実差異**: 当初は 4 種の widget (volume/battery/clock/separator) のみだったが、参考実装の確認後に **6 種の widget (cpu/memory/network/volume/battery/date)** に拡張。
> `position = "right"` の挙動 (後 add ほど左寄り) に合わせて require 順を逆転 (`spaces → date → battery → volume → network → memory → cpu → right` で bar 上は左→右 `cpu memory network volume battery date`)。
>
> SF Symbol Unicode (`\u{F4BC}` 等) を直接埋め込んだ際、Edit ツール経由で UTF-8 byte 列が空文字に化ける事象を観測。Lua 5.3+ `\u{...}` escape は selene (Lua 5.1 std) で `bad_string_escape` 警告。最終的に `helpers/icons.lua` で `string.char` を使った Lua 5.1 互換の helper `nf(codepoint)` を作って解決。
>
> **workspace 動的取得**: 当初 `space_count = 4` ハードコードでサブモニタ (G-16U) の workspace 5 (Ghostty) が表示されない問題を修正。`helpers/aerospace.lua` に `list_workspaces()` を追加して `aerospace list-workspaces --all` で動的取得、color palette を 8 色ローテで割り当て。
>
> **AeroSpace の workspace 概念**: workspace はモニターに固定されず、focus されたモニターに動的に表示される。`workspace-to-monitor-force-assignment` で固定可能だが本リポは未設定。

- [x] 4-9: 不具合がなければ Phase 4 完了コミット (`feat(sketchybar): show app icons in workspace spaces` 等)

#### 検証

- アプリ起動 → 該当 workspace の bracket に icon が追加される
- アプリ終了 → 該当 icon が消える
- workspace 切替 (`alt-1`〜`4`) → focus space の背景色が `colors.blue` に変化
- 別 workspace に window を移動 (`alt-shift-1` 等) → 移動元から消え、移動先に icon が出る
- `~/Library/Logs/sketchybar/sketchybar.err.log` にエラー追記なし

---

## 変更対象ファイル一覧

| ファイル                                  | Phase 1                                                                 | Phase 2                                                                                                                                            | Phase 3                              | Phase 4                                                                            |
| ----------------------------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------------------------------------- |
| `nix/overlays/sketchybar-app-font.nix`    | 新規作成                                                                | -                                                                                                                                                  | -                                    | -                                                                                  |
| `nix/overlays/default.nix`                | 1 行追加（既存 `final: prev: { ... }` 内）                              | -                                                                                                                                                  | -                                    | -                                                                                  |
| `nix/hosts/darwin-shared.nix`             | `fonts.packages` 1 行追加 / `services.jankyborders` / `system.defaults` | -                                                                                                                                                  | `homebrew.casks` に `"alt-tab"` 追加 | -                                                                                  |
| `nix/hosts/darwin-aerospace.nix`          | **新規作成**（`services.aerospace`、Phase 1 完了）                      | -                                                                                                                                                  | -                                    | -                                                                                  |
| `nix/home/programs/sketchybar.nix`        | -                                                                       | **新規作成**（Pattern C、`mkIf isDarwin`）                                                                                                         | -                                    | -                                                                                  |
| `nix/home/programs/default.nix`           | -                                                                       | imports に `./sketchybar.nix` 追加                                                                                                                 | -                                    | -                                                                                  |
| `config/sketchybar/*`                     | -                                                                       | 独自実装で新規作成（colors / settings / bar / default / init / sketchybarrc / items/{init,spaces,front_app,clock,battery,volume,separator}）       | -                                    | spaces 全面書き換え / front_app と separator 削除 / right.lua 新規 / helpers/ 新規 |
| `config/sketchybar/helpers/aerospace.lua` | -                                                                       | -                                                                                                                                                  | -                                    | **新規作成**（`aerospace list-windows --json` ラッパ）                             |
| `config/sketchybar/helpers/icon_map.lua`  | -                                                                       | -                                                                                                                                                  | -                                    | **新規作成**（app_name → リガチャマップ + フォールバック）                         |
| `config/sketchybar/items/right.lua`       | -                                                                       | -                                                                                                                                                  | -                                    | **新規作成**（clock/battery/volume を 1 つの bracket で島化）                      |
| `nix/home/symlinks.nix`                   | -                                                                       | **変更なし**（HM `programs.sketchybar.config.source = config.lib.file.mkOutOfStoreSymlink ...; recursive = true;` が out-of-store symlink を担う） | -                                    | -                                                                                  |
| Raycast 設定 (GUI)                        | -                                                                       | -                                                                                                                                                  | hotkey unbind                        | -                                                                                  |
| alt-tab 設定 (GUI)                        | -                                                                       | -                                                                                                                                                  | コントロール / 外観                  | -                                                                                  |

> `config/aerospace/` と `config/borders/` は **作成しない**（`services.aerospace.settings` / `services.jankyborders.*` で完結）。

---

## 運用上の注意

- **sketchybar-app-font のアイコン解決**: `front_app` item で `INFO` (アプリ名) → リガチャ名へのマッピングが必要だが、自前実装ではフォールバック付きで持つ（解決できないアプリは SF Symbol の汎用アイコンを使う）。font (`.ttf`) 側は overlay の `version` + `hash` bump で更新可能（CC0 ライセンス）
- **SF Symbols を採用**するため、CPU/メモリ等の glyph は macOS 標準（バージョンによって表示が変動する可能性あり）。Tokyo Night の見た目との一貫性は font (Moralerspace Xenon HW) と配色 (`colors.lua`) で担保
- **Phase 1 単独投入時の SketchyBar はデフォルト設定で起動**するため、`exec.env-vars.PATH` で bare `sketchybar` を解決する設計と組み合わせ、Phase 2 に移行するまで bar 表示は最小限のものになる。`exec-on-workspace-change` の `--trigger aerospace_workspace_change` も SketchyBar 側で未登録のためこの期間は no-op

## 実現可能性レビュー

| 懸念                                             | 検証結果                                                                                                                                                                                                                                                                       | 根拠                                                                                                                                                                  |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| HM `programs.aerospace` の option 名             | **`enable` + `settings`**（attrset → TOML）                                                                                                                                                                                                                                    | `home-manager/modules/programs/aerospace.nix:152` で `cfg.settings` 参照を確認                                                                                        |
| HM `programs.aerospace` の `start-at-login` 扱い | **HM が TOML 出力時に `start-at-login = false; after-login-command = [];` を強制上書き**。launchd 起動は HM 側 agent が担う                                                                                                                                                    | 同 `:200〜` `cfg.settings // { start-at-login = false; after-login-command = []; }`                                                                                   |
| HM `programs.aerospace` の hot reload            | **`launchd.enable = true` のとき `onChange` フックで `aerospace reload-config` を自動実行**（`launchd.enable` の HM default は **false** なので明示有効化が必要）                                                                                                              | 同 `:215〜` `onChange = lib.mkIf cfg.launchd.enable '' ${lib.getExe cfg.package} reload-config '';` / launchd default: 同 `:67-69` `default = false;`                 |
| HM `programs.sketchybar` の Lua 対応             | **`configType = "lua"` + `sbarLuaPackage` で LUA_PATH / LUA_CPATH 自動設定**                                                                                                                                                                                                   | `home-manager/modules/programs/sketchybar.nix:181〜` `configType` enum と `sbarLuaPackage` option                                                                     |
| HM `programs.sketchybar` の `source` の挙動      | **`source` に `mkOutOfStoreSymlink` 戻り値を渡せばディレクトリを `~/.config/sketchybar/` に out-of-store な再帰 symlink** (`recursive = true` 必須)。path リテラル `../../...` だと Nix store コピーになり Lua 編集が即時反映されない                                          | hm `programs/sketchybar.nix:286-317` (`xdg.configFile` 配置)、`:241-244` (`cfg.config != null && cfg.config.source != null` で LUA_PATH に config dir 追加)           |
| `services.aerospace` × `programs.aerospace` 併用 | **両方有効化すると launchd agent が二重に作られて競合**                                                                                                                                                                                                                        | nix-darwin `services/aerospace/default.nix:249-256` と HM `programs/aerospace.nix` がそれぞれ `launchd.user.agents.aerospace` / `launchd.agents.aerospace` を生成     |
| HM platform assertion                            | **`config = lib.mkIf cfg.enable { assertions = [...] }` の内側にあり、`enable = false` なら発火しない**                                                                                                                                                                        | `programs/aerospace.nix:152` / `programs/sketchybar.nix:179`                                                                                                          |
| Pattern C の Linux ビルド安全性                  | **`flake.nix:146,168` で同じ `./nix/home` を import する両 OS 構成。`mkIf pkgs.stdenv.isDarwin` で Linux ビルド時は `enable = false` 相当**                                                                                                                                    | 既存 `nix/home/darwin.nix` と同パターン                                                                                                                               |
| Moralerspace の NF 対応                          | **v2.0.0 (2025-07-28) で全バリエーションに Nerd Fonts 標準搭載**。`Moralerspace*NF-*.ttf` は廃止                                                                                                                                                                               | `https://github.com/yuru7/moralerspace/releases/tag/v2.0.0` リリースノート                                                                                            |
| Moralerspace Xenon HW の Ghostty 一貫性          | **既存 `nix/home/programs/ghostty.nix` で `font-family = "Moralerspace Xenon HW"` 使用済**。SketchyBar も同 face で統一可能                                                                                                                                                    | `nix/home/programs/ghostty.nix`                                                                                                                                       |
| nix-darwin services.jankyborders の attribute 名 | **underscore 区切（`active_color` 等）**、CLI 引数化される                                                                                                                                                                                                                     | `nix-darwin/modules/services/jankyborders/default.nix:39〜`                                                                                                           |
| AeroSpace コマンド名・構文                       | プラン記載のコマンド (`focus`, `move`, `workspace`, `move-node-to-workspace`, `workspace-back-and-forth`, `layout`, `balance-sizes`, `resize`, `mode`, `reload-config`, `flatten-workspace-tree`, `close-all-windows-but-current`, `exec-and-forget`) **全て公式 docs に存在** | [AeroSpace commands](https://nikitabobko.github.io/AeroSpace/commands)                                                                                                |
| nixpkgs の追従ラグ                               | 0〜13 日                                                                                                                                                                                                                                                                       | `gh release list` × `git log -- pkgs/by-name/...` 実測                                                                                                                |
| Karabiner と AeroSpace `alt-` の衝突             | **左 Option では衝突なし**。右 Option は Karabiner で `right_shift` に置換されるため AeroSpace 発火しない                                                                                                                                                                      | `config/karabiner/karabiner.json` の rules を直接精査                                                                                                                 |
| Raycast hotkey と AeroSpace `alt-` の衝突        | **衝突なし**（Raycast WM 拡張廃止前提）                                                                                                                                                                                                                                        | `Option+Space` (Raycast 起動) と `alt+shift+space` は modifier 異                                                                                                     |
| alt-tab cask hotkey の衝突                       | **衝突なし**                                                                                                                                                                                                                                                                   | alt-tab cask は `⌘ Tab`、AeroSpace `alt-tab` は `Option+Tab` で modifier が別。alt-tab cask は Phase 3 で投入するため、AeroSpace との過渡期重複ウィンドウは発生しない |
| Tokyo Night の公式 extras 不在                   | tokyonight / catppuccin / rose-pine の各 org 配下に sketchybar 連動の公式リポなし → hex 直書きで対応                                                                                                                                                                           | 各 org の `gh search` 実測                                                                                                                                            |
| Nix attribute 名のハイフン                       | **そのまま記述可**                                                                                                                                                                                                                                                             | HM `programs.aerospace` の example も `alt-h = "focus left";` を使用                                                                                                  |

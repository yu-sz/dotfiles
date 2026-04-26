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
| カラーパレット            | **`tokyonight`**                                                                 | `folke/tokyonight.nvim` 由来 hex 移植                                                                                                                                                                                                                                                                                                                                      |
| Raycast WM 拡張           | **廃止 (hotkey 全 Unbind)**                                                      | Search Menu Bar 等他コマンドは維持                                                                                                                                                                                                                                                                                                                                         |
| メニューバー              | **`_HIHideMenuBar = true` で常時非表示**                                         | `Search Menu Bar` を主動線に                                                                                                                                                                                                                                                                                                                                               |
| symlink 追加              | **不要** (HM 経由で `mkOutOfStoreSymlink` する)                                  | `programs.sketchybar.config = { source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${dotfilesRelPath}/config/sketchybar"; recursive = true; }` で HM が `~/.config/sketchybar/` 配下に **out-of-store な再帰 symlink**。Lua 編集を即時反映できる (`mkLink` 規約と等価)。`programs.aerospace.settings` が TOML を生成。jankyborders は CLI 引数のみ |
| icons モード (SketchyBar) | **`sf-symbols`**（macOS 同梱、追加 font 不要）                                   | 上流テンプレートの `icons.lua` は `sf_symbols` / `nerdfont` 両テーブルを提供しているが、本計画では SF Symbols を採用 (Moralerspace Xenon HW は表示 face 用、icon は SF Symbols)。`settings.lua` の `icons = "sf-symbols"` をそのまま採用する                                                                                                                               |
| マルチ OS 安全性          | **Pattern C (内部 `lib.mkIf pkgs.stdenv.isDarwin`)**                             | 既存 `nix/home/darwin.nix` 規約に揃える。Linux ビルド (`homeConfigurations.ci@linux`) は `enable` が反映されないので無害                                                                                                                                                                                                                                                   |

---

## 設計: `nix/overlays/sketchybar-app-font.nix`

```nix
# nix/overlays/sketchybar-app-font.nix
# 上流テンプレート (SoichiroYamane/dotfiles@fe070a1f) には既に `helpers/icon_map.lua` が
# bundled されているため、overlay からは **font (.ttf) のみ** 取得する。
# `icon_map.lua` の更新が必要な場合は手動で上流から差し替える運用（後述 §運用上の注意）。
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
        outer.top = 52; # SketchyBar 高さ 44 (SoichiroYamane bar.lua) + 余白 8
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
-- folke/tokyonight.nvim style=night より移植 (lua/tokyonight/colors/night.lua)
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

> SketchyBar の他 Lua ファイル（`sketchybarrc` 本体・`init.lua` / `bar.lua` / `icons.lua` / `items/*.lua` / `helpers/icon_map.lua`）は **`SoichiroYamane/dotfiles` の `sketchybar/` 配下 (MIT, HEAD `fe070a1f991834aa14c6e0dcd79e6e7c17071c0d`)** を参照テンプレートとし、以下のみ書き換え:
>
> - 配色: `colors.lua` を上記に差し替え
> - フォント: `helpers/default_font.lua` を `text = "Moralerspace Xenon HW"; numbers = "Moralerspace Xenon HW";` に書き換え（Ghostty と統一）
> - **icons モード**: `settings.lua` の `icons = "sf-symbols"` は **そのまま据置**（上流の `icons.lua` は `sf_symbols` / `nerdfont` 両テーブルを提供しているが、本計画では Moralerspace HW フォントは表示 face 用、icon は SF Symbols とする最小差分方針を採用）
> - **event provider 依存 widget の除外**: `items/widgets/init.lua` から `cpu` / `memory` / `wifi` の `require` を削除（残す: `battery` / `volume`）。
>   理由は `helpers/event_providers/{cpu,memory,network}_load/` が C ソース + makefile であり、`bin/` を `make` しないと widget が `bin/cpu_load: No such file` で動かないため。
>   `pkgs.sketchybar` には event provider バイナリが同梱されないので、必要時は別 ADR で overlay 化を検討
>
> 上流テンプレは **完全 Lua 化** されており `plugins/*.sh` は存在しない。
>
> Phase 2 着手時に `config/sketchybar/LICENSE.upstream` を作成し、上流 LICENSE の **著作権表示行 + MIT 許諾文全文** を保持する。`icon_map.lua` は **テンプレート bundled の `helpers/icon_map.lua` をそのまま利用**するため、`config/sketchybar/icons.lua` 等の `require` パスは上流のままで変更不要（overlay 経由の参照は不要）。

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
> 最終的に nix-darwin `services.aerospace` へ切替（takeokunn 氏のブログ記事と同じ標準アプローチ）。
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
- [ ] 1-12: `outer.top = 52` の **実機妥当性確認**（Phase 2 投入後に bar と上端ウィンドウの重なり/隙間を視認、HiDPI/Retina 環境ではズレやすいので ±4 px の調整余地を残す）。Phase 1 単独時点では SketchyBar はデフォルト設定で動くため正確な調整は Phase 2-13 で再確認

### Phase 2: SketchyBar の Lua/plugins ファイル作成 & HM 接続

- [ ] 2-0: 上流テンプレートのライセンステキストを保持
  - `gh api repos/SoichiroYamane/dotfiles/contents/LICENSE --jq .content | base64 -d > config/sketchybar/LICENSE.upstream`
  - 取得した LICENSE 全文（**著作権表示行 `Copyright (c) ...` + MIT 許諾文全文** の両方）が `config/sketchybar/LICENSE.upstream` に保存されていることを `cat` で確認
- [ ] 2-0a: 上流テンプレートを一時 clone してコピー
  - `mkdir -p /tmp/sy-dotfiles && git clone https://github.com/SoichiroYamane/dotfiles /tmp/sy-dotfiles && (cd /tmp/sy-dotfiles && git checkout fe070a1f991834aa14c6e0dcd79e6e7c17071c0d)`
  - `cp -R /tmp/sy-dotfiles/sketchybar/. config/sketchybar/`
  - `gomi /tmp/sy-dotfiles`
- [ ] 2-0b: 上流テンプレート由来の **不要ファイルを除去**（dotfiles に取り込むべきでない個人ログ・ビルド残骸 / 未使用 widget の依存物）
  - `gomi config/sketchybar/noice.log config/sketchybar/cmap_cal`（個人ログ・用途不明バイナリ）
  - `gomi config/sketchybar/helpers/install.sh config/sketchybar/helpers/makefile`（sbarlua の自前ビルド手順 — Nix 環境では不要）
  - `gomi config/sketchybar/helpers/event_providers`（C ソース + makefile。`make` しないと `bin/{cpu,memory,network}_load` が生成されない。本計画では event provider 依存 widget を採用しないため除去）
  - `helpers/icon_map.lua` は **残す**（bundled 版を正本として運用、§設計参照）
  - `helpers/.gitignore` は不要なら除去（上流由来、Nix リポでは未使用）
  - **保持** (コア依存): `default.lua`, `helpers/init.lua`, `helpers/menus/`, `items/init.lua`, `items/widgets/init.lua`
  - **任意保持**: `icon_map.sh` / `icon_updater.sh`（新規アイコン追加スクリプト、無くても起動可）
- [ ] 2-1: `config/sketchybar/colors.lua` を上記設計の内容に **Edit で書き換え**（冒頭コメントに `-- folke/tokyonight.nvim style=night より移植 (lua/tokyonight/colors/night.lua)` を含める）
- [ ] 2-2: `config/sketchybar/icons.lua` を確認（sketchybar-app-font リガチャマッピング — 上流が既に対応している場合は require 経路だけ調整）
- [ ] 2-3: `config/sketchybar/init.lua`（require 順序）を確認
- [ ] 2-4: `config/sketchybar/bar.lua` の `height = 44` を維持
- [ ] 2-5: `config/sketchybar/helpers/default_font.lua` を Edit で `text = "Moralerspace Xenon HW"; numbers = "Moralerspace Xenon HW";` に書き換え（Ghostty と統一）
- [ ] 2-6: `config/sketchybar/settings.lua` の `icons = "sf-symbols"` は **編集しない**（上流の `icons.lua` は `sf_symbols` / `nerdfont` 両テーブルを提供しているが、本計画では SF Symbols を採用）
- [ ] 2-7: `config/sketchybar/items/widgets/init.lua` を Edit し、event provider 依存の widget を除外する:

  ```lua
  require("items.widgets.battery")
  require("items.widgets.volume")
  -- 以下 3 行を削除（event_providers バイナリのビルドが前提のため）
  -- require("items.widgets.wifi")
  -- require("items.widgets.memory")
  -- require("items.widgets.cpu")
  ```

  併せて `gomi config/sketchybar/items/widgets/{cpu,memory,wifi}.lua` で本体ファイルも除去（require していなくても残しておくと将来の混乱の元）

- [ ] 2-8: `config/sketchybar/plugins/` が **存在しないこと** を `ls config/sketchybar/plugins 2>/dev/null` で確認（上流は完全 Lua 化のため `plugins/` を持たない）
- [ ] 2-9: `config/sketchybar/sketchybarrc` の shebang を確認（Lua 経路）
- [ ] 2-10: `nix/home/programs/sketchybar.nix` を新規作成（上記設計の完成形）
- [ ] 2-11: `nix/home/programs/default.nix` の `imports` に `./sketchybar.nix` を追加
- [ ] 2-12: `git add .` し `! nrs`
- [ ] 2-13: `launchctl list | rg sketchybar` で起動確認、bar アイテムの表示と AeroSpace ワークスペース切替の同期を検証。`tail -f /tmp/sketchybar*.log` 等で Lua エラーが出ていないか確認
- [ ] 2-14: bar と上端ウィンドウの **重なり/隙間を実機で視認**し、必要なら `nix/home/programs/aerospace.nix` の `gaps.outer.top` を ±4 px 範囲で調整（HiDPI/Retina やマルチディスプレイ環境でズレやすい）

### Phase 3: alt-tab 投入 + Raycast 連動 + メニューバー動線確認

- [ ] 3-1: `nix/hosts/darwin-shared.nix` の `homebrew.casks` に `"alt-tab"` を追加
- [ ] 3-2: `git add .` し `! nrs`（alt-tab.app がインストールされる）
- [ ] 3-3: alt-tab を起動 → アクセシビリティ許可 → 再起動して設定画面を開く
- [ ] 3-4: **最優先で hotkey を変更**：alt-tab の **コントロール** タブ > **ショートカット 1** > **起動ショートカット** を **`⌘ Tab` に即時変更**してから設定画面を閉じる（既定値の `Option+Tab` は AeroSpace `alt-tab = "workspace-back-and-forth"` と衝突するため、他の項目より先に潰す）
- [ ] 3-5: alt-tab の **コントロール** タブ > **ショートカット 1** の残り項目を設定（GUI 操作）
  - キーを離したときの動作: 選択されたウィンドウを表示
  - アプリケーションからウィンドウを表示する: 全てのアプリケーション
  - スペースからウィンドウを表示する: **現在のスペース**
  - スクリーンからウィンドウを表示する: 全てのスクリーン
  - 最小化されたウィンドウを表示する: アプリを表示
  - 非表示のウィンドウを表示する: アプリを表示
  - フルスクリーンのウィンドウを表示する: アプリを表示
  - ウィンドウの順序: フォーカスした順
- [ ] 3-6: alt-tab の **外観** タブを以下に設定（GUI 操作）
  - 選択スタイル: サムネイル
  - サイズ: 大きい
  - テーマ: システム
  - 可視性: 最高
  - 複数スクリーン > 表示場所: 稼働スクリーン
- [ ] 3-7: AeroSpace `alt-tab`（Option+Tab、workspace-back-and-forth）と alt-tab cask（Cmd+Tab）が独立に動作することを実機確認
- [ ] 3-8: Raycast Settings → Extensions → Window Management の hotkey をすべて Unbind（GUI 操作）
- [ ] 3-9: Raycast `Search Menu Bar` で代表アプリのメニュー操作確認
- [ ] 3-10: 不具合がなければ commit

---

## 変更対象ファイル一覧

| ファイル                               | Phase 1                                                                 | Phase 2                                                                                                                                            | Phase 3                              |
| -------------------------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| `nix/overlays/sketchybar-app-font.nix` | 新規作成                                                                | -                                                                                                                                                  | -                                    |
| `nix/overlays/default.nix`             | 1 行追加（既存 `final: prev: { ... }` 内）                              | -                                                                                                                                                  | -                                    |
| `nix/hosts/darwin-shared.nix`          | `fonts.packages` 1 行追加 / `services.jankyborders` / `system.defaults` | -                                                                                                                                                  | `homebrew.casks` に `"alt-tab"` 追加 |
| `nix/home/programs/aerospace.nix`      | **新規作成**（Pattern C、`mkIf isDarwin`）                              | -                                                                                                                                                  | -                                    |
| `nix/home/programs/sketchybar.nix`     | -                                                                       | **新規作成**（Pattern C、`mkIf isDarwin`）                                                                                                         | -                                    |
| `nix/home/programs/default.nix`        | imports に `./aerospace.nix` 追加                                       | imports に `./sketchybar.nix` 追加                                                                                                                 | -                                    |
| `config/sketchybar/*`                  | -                                                                       | 新規作成（複数ファイル）                                                                                                                           | -                                    |
| `nix/home/symlinks.nix`                | -                                                                       | **変更なし**（HM `programs.sketchybar.config.source = config.lib.file.mkOutOfStoreSymlink ...; recursive = true;` が out-of-store symlink を担う） | -                                    |
| Raycast 設定 (GUI)                     | -                                                                       | -                                                                                                                                                  | hotkey unbind                        |
| alt-tab 設定 (GUI)                     | -                                                                       | -                                                                                                                                                  | コントロール / 外観                  |

> `config/aerospace/` と `config/borders/` は **作成しない**（`programs.aerospace.settings` / `services.jankyborders.*` で完結）。

---

## 運用上の注意

- **sketchybar-app-font の `icon_map.lua` 更新は手動運用**: 上流テンプレート bundled 版を正本として採用した結果、overlay の `version` bump で連動更新できなくなった。
  新規アプリのアイコン追加に追従する場合は <https://github.com/kvndrsslr/sketchybar-app-font/releases> から `icon_map.lua` を取得し、`config/sketchybar/helpers/icon_map.lua` を差し替える。
  font (`.ttf`) 側は overlay の `version` + `hash` bump で更新可能（CC0 ライセンス）
- **Phase 2 で SF Symbols を維持する**ため、CPU/メモリ等の glyph は macOS 標準（バージョンによって表示が変動する可能性あり）。Tokyo Night の見た目との一貫性は font (Moralerspace Xenon HW) と配色 (`colors.lua`) で担保
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
| Tokyo Night の公式 extras 不在                   | folke/tokyonight, catppuccin (org 直下), rose-pine (org 直下) いずれも対応リポなし → hex 直書きで対応                                                                                                                                                                          | 各 org の `gh search` 実測                                                                                                                                            |
| Nix attribute 名のハイフン                       | **そのまま記述可**                                                                                                                                                                                                                                                             | HM `programs.aerospace` の example も `alt-h = "focus left";` を使用                                                                                                  |

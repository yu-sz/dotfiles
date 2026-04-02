# macOS システム設定 + Stylix テーマ統一 + programs 追加移行 実装計画

## 概要

macOS システム設定の宣言的管理、Stylix によるテーマ統一、lazygit/ghostty/yazi の `programs.*` 移行を行う:

- **macOS 設定**: `system.defaults` で Dock, Finder, キーボード等を管理
- **Stylix**: tokyo-night-dark で bat, fzf, lazygit, ghostty, yazi のカラースキームを統一
- **programs 移行**: lazygit, ghostty, yazi を `config/` シンボリンクから `programs.*` に移行

**出典**:

- [ADR: macOS システム設定の宣言的管理](../adr/2026-04-01-macos-defaults-stylix-programs-migration.md)
- [ADR: Stylix テーマ統一 + programs 移行](../adr/2026-04-01-stylix-programs-migration.md)

---

## 決定事項

| 項目            | 決定                                    | 備考                                                                                                             |
| --------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| XDG 前提設定    | **`xdg.enable = true`**                 | macOS で HM モジュールが `~/Library/Application Support/` に書くのを防止。全フェーズの前提条件                   |
| macOS 設定      | **`system.defaults`** で宣言的管理      | `activateSettings -u` で即時反映                                                                                 |
| Stylix          | **`autoEnable = false`** で個別有効化   | bat, fzf, lazygit, ghostty, yazi のみ                                                                            |
| カラースキーム  | **tokyo-night-dark**                    | Base16 スキーム                                                                                                  |
| lazygit         | **`programs.lazygit`** に移行           | YAML → Nix 変換。`pagers` はリスト構造を維持。`selectedLineBgColor` は `lib.mkForce` 必須                        |
| ghostty 本体    | **Homebrew cask → nixpkgs**             | macOS: `ghostty-bin`, Linux: `ghostty`                                                                           |
| ghostty 設定    | **`programs.ghostty`** に移行           | key-value → Nix 変換                                                                                             |
| yazi            | **`programs.yazi`** に移行              | 非デフォルト値は `sort_by`, `show_hidden`, `title_format` の 3 項目のみ。依存パッケージは `extraPackages` で管理 |
| yazi プラグイン | **`programs.yazi.plugins`** で Nix 管理 | `ya pack` は使えなくなる                                                                                         |
| yazi テーマ     | **Stylix が管理**                       | `theme.toml` + `flavors/` 不要。BennyOe flavor と色の細部が異なる可能性あり                                      |

---

## 設計: ファイル構成

```
nix/
├── hosts/
│   └── darwin-shared.nix  ← system.defaults 追加、Stylix core 設定追加、homebrew.casks から ghostty 削除
└── home/
    ├── default.nix        ← xdg.enable = true 追加、imports に ./stylix.nix 追加、home.packages から lazygit・yazi・yazi 依存パッケージ削除
    ├── stylix.nix         ← 新規: Stylix targets 設定（HM レベル）
    ├── symlinks.nix       ← lazygit, ghostty, yazi エントリ削除
    └── programs/
        ├── default.nix    ← imports に lazygit, ghostty, yazi 追加
        ├── lazygit.nix    ← 新規
        ├── ghostty.nix    ← 新規
        ├── yazi.nix       ← 新規
        └── yazi-init.lua  ← config/yazi/init.lua から移動

flake.nix                  ← stylix input 追加、modules に stylix.darwinModules.stylix 追加
```

Stylix 設定のスコープ:

- **system レベル** (`darwin-shared.nix`): `stylix.enable = true`, `stylix.base16Scheme`, `stylix.fonts.monospace`, `stylix.autoEnable = false`
  - `followSystem = true`（デフォルト）により HM に `mkDefault` で自動伝播
- **HM レベル** (`stylix.nix`): `stylix.targets.<name>.enable = true` のみ

削除対象:

- `config/lazygit/` ディレクトリ
- `config/ghostty/` ディレクトリ
- `config/yazi/` ディレクトリ

---

## 設計: 各ツールの Nix 定義

### `nix/home/stylix.nix`

```nix
_: {
  stylix.targets = {
    bat.enable = true;
    fzf.enable = true;
    lazygit.enable = true;
    ghostty = {
      enable = true;
      fonts.enable = false;
      opacity.enable = false;
    };
    yazi.enable = true;
  };
}
```

> `fonts.enable = false` でフォント名・サイズの上書きを防止。`opacity.enable = false` で `background-opacity = 0.85` を維持。

### `nix/home/programs/lazygit.nix`

```nix
{ lib, ... }:
{
  programs.lazygit = {
    enable = true;
    settings = {
      git.pagers = [
        { colorArg = "always"; pager = "delta --dark --paging=never"; }
      ];
      gui = {
        language = "ja";
        nerdFontsVersion = "3";
        sidePanelWidth = 0.15;
        showIcons = true;
        theme = {
          selectedLineBgColor = lib.mkForce [ "underline" ];
        };
      };
      refresher.refreshInterval = 3;
      os.editPreset = "nvim-remote";
    };
  };
}
```

> `git.pagers` は Go ソースで `[]PagingConfig` (スライス) として定義されているため、Nix でもリスト構造を維持すること。
> `selectedLineBgColor` は Stylix が通常優先度で設定するため `lib.mkForce` が必須。なしだと conflicting definition values エラー。

### `nix/home/programs/ghostty.nix`

```nix
{ lib, pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    settings = {
      font-family = "Moralerspace Xenon HW";
      window-title-font-family = "Moralerspace Xenon HW";
      font-size = 18;
      font-thicken = false;
      background-opacity = 0.85;
      background-blur-radius = 20;
      unfocused-split-opacity = 0.7;
      cursor-opacity = 0.8;
      cursor-color = lib.mkForce "#ffffff";
      cursor-style = "block";
      window-theme = "auto";
      window-padding-color = "background";
      window-padding-x = 2;
      window-padding-y = 2;
      window-padding-balance = true;
      window-step-resize = false;
      window-save-state = "always";
      window-inherit-working-directory = true;
      macos-icon = "xray";
      macos-titlebar-style = "hidden";
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-trim-trailing-spaces = true;
      shell-integration = "detect";
      command = "/bin/zsh -lic 'ghostty +boo; tmux attach || tmux new-session -s default'";
      keybind = [ "shift+enter=text:\\n" ];
    };
  };
}
```

> `theme` は Stylix 管理のため含めない。`package` は macOS で `ghostty-bin` を明示指定すること（デフォルトの `pkgs.ghostty` は Linux 専用）。
> `cursor-color` は Stylix が `colors.base05` を通常優先度で設定するため `lib.mkForce` が必須。

### `nix/home/programs/yazi.nix`

```nix
{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    initLua = ./yazi-init.lua;
    plugins = {
      inherit (pkgs.yaziPlugins) smart-enter starship full-border;
    };
    settings = {
      mgr = {
        sort_by = "natural";
        show_hidden = true;
        title_format = "";
      };
    };
    extraPackages = with pkgs; [
      ffmpeg
      poppler-utils
      imagemagick
      resvg
      _7zz
    ];
  };
}
```

> yazi デフォルト設定と diff した結果、非デフォルト値は 3 項目のみ。現在の `yazi.toml` の `[tasks]`, `[spotters]`, `[open].rules` 等は古いデフォルトのコピーなので、書かない方が最新デフォルトが適用されて改善される。

### `nix/home/programs/yazi-init.lua`

```lua
require("starship"):setup()
require("full-border"):setup()
require("smart-enter"):setup({
	open_multi = true,
})
```

---

## 実装チェックリスト

### フェーズ 0: XDG Base Directory 前提設定

- [ ] 0-1: `nix/home/default.nix` に `xdg.enable = true` を追加
- [ ] 0-2: `drs` を実行し正常完了を確認
- [ ] 0-3: 既存ツールの動作に影響がないことを確認（nvim, tmux, zsh 等）
- [ ] 0-4: コミット

> macOS では `xdg.enable = false`（デフォルト）の場合、home-manager の一部モジュール（lazygit, lazydocker 等 10 モジュール）が `~/Library/Application Support/` に設定ファイルを書き出す。
> `.zshenv` で `XDG_CONFIG_HOME=$HOME/.config` を設定しているため、ツール本体は `~/.config/` を読む。
> このパスのずれを防ぐため、`xdg.enable = true` を全フェーズの前提条件として設定する。

### フェーズ 1: macOS システム設定

- [ ] 1-1: `nix/hosts/darwin-shared.nix` に `system.defaults` を追加（Dock, Finder, NSGlobalDomain, menuExtraClock, CustomUserPreferences）
- [ ] 1-2: `nix/hosts/darwin-shared.nix` に `system.activationScripts.postUserActivation` を追加
- [ ] 1-3: `drs` を実行し正常完了を確認
- [ ] 1-4: Dock が右配置・自動非表示・遅延なしになっていることを確認
- [ ] 1-5: Finder でパスバー・拡張子・カラム表示を確認
- [ ] 1-6: メニューバー時計が 24h・秒表示になっていることを確認
- [ ] 1-7: コミット

### フェーズ 2: Stylix 基盤導入

- [ ] 2-1: `flake.nix` の inputs に `stylix` を追加
- [ ] 2-2: `flake.nix` の `mkDarwinConfig` modules に `stylix.darwinModules.stylix` を追加
- [ ] 2-3: `nix/hosts/darwin-shared.nix` に Stylix core 設定を追加（`stylix.enable = true`, `stylix.base16Scheme`, `stylix.fonts.monospace`, `stylix.autoEnable = false`）
- [ ] 2-4: `nix/home/stylix.nix` を作成（targets は空の状態で開始）
- [ ] 2-5: `nix/home/default.nix` の imports に `./stylix.nix` を追加
- [ ] 2-6: `drs` を実行し正常完了を確認
- [ ] 2-7: neovim, wezterm, starship, tmux → 既存設定のまま変化なしを確認（`autoEnable = false` の検証）
- [ ] 2-8: コミット

### フェーズ 3: lazygit 移行 + Stylix target 有効化

- [ ] 3-1: `nix/home/programs/lazygit.nix` を作成（設計セクション参照）
- [ ] 3-2: `nix/home/programs/default.nix` の imports に `./lazygit.nix` を追加
- [ ] 3-3: `nix/home/default.nix` の `home.packages` から `lazygit` を削除
- [ ] 3-4: `nix/home/symlinks.nix` から `"lazygit"` エントリを削除
- [ ] 3-5: `nix/home/stylix.nix` に `stylix.targets.lazygit.enable = true` を追加
- [ ] 3-6: `~/.config/lazygit` シンボリンクを手動削除
- [ ] 3-7: `drs` を実行し正常完了を確認
- [ ] 3-8: `lazygit` 起動 → 日本語 UI、Nerd Font アイコン表示を確認
- [ ] 3-9: lazygit 内で diff → delta の side-by-side 表示を確認
- [ ] 3-10: lazygit 内で `e` → nvim-remote でエディタ起動を確認
- [ ] 3-11: lazygit → tokyo-night の色を確認
- [ ] 3-12: `config/lazygit/` ディレクトリを削除
- [ ] 3-13: コミット

### フェーズ 4: ghostty 移行 + Stylix target 有効化

- [ ] 4-1: `nix/home/programs/ghostty.nix` を作成（設計セクション参照）
- [ ] 4-2: `nix/home/programs/default.nix` の imports に `./ghostty.nix` を追加
- [ ] 4-3: `nix/hosts/darwin-shared.nix` の `homebrew.casks` から `"ghostty"` を削除
- [ ] 4-4: `nix/home/symlinks.nix` から `"ghostty"` エントリを削除
- [ ] 4-5: `nix/home/stylix.nix` に ghostty targets を追加（設計セクション参照）
- [ ] 4-6: `~/.config/ghostty` シンボリンクを手動削除
- [ ] 4-7: Homebrew の ghostty がまだ残っている場合は手動アンインストール（`drs` の `cleanup = "uninstall"` で自動処理される可能性あり）
- [ ] 4-8: `drs` を実行し正常完了を確認
- [ ] 4-9: ghostty 起動 → tmux セッションに接続を確認
- [ ] 4-10: フォント・透明度・カーソル設定が反映されていることを確認
- [ ] 4-11: `shift+enter` キーバインドが動作することを確認
- [ ] 4-12: ghostty → tokyo-night の色を確認（ビルトイン `tokyonight` との差異に注意）
- [ ] 4-13: `config/ghostty/` ディレクトリを削除
- [ ] 4-14: コミット

### フェーズ 5: yazi 移行 + Stylix target 有効化

- [ ] 5-1: `config/yazi/init.lua` を `nix/home/programs/yazi-init.lua` にコピー
- [ ] 5-2: `nix/home/programs/yazi.nix` を作成（設計セクション参照）
- [ ] 5-3: `nix/home/programs/default.nix` の imports に `./yazi.nix` を追加
- [ ] 5-4: `nix/home/default.nix` の `home.packages` から `yazi` と yazi 依存パッケージ（`ffmpeg`, `poppler-utils`, `imagemagick`, `resvg`, `_7zz`）を削除（`programs.yazi.extraPackages` に移動済み）
- [ ] 5-5: `nix/home/symlinks.nix` から `"yazi"` エントリを削除
- [ ] 5-6: `nix/home/stylix.nix` に `stylix.targets.yazi.enable = true` を追加
- [ ] 5-7: `~/.config/yazi` シンボリンクを手動削除
- [ ] 5-8: `drs` を実行し正常完了を確認
- [ ] 5-9: `yazi` 起動 → 隠しファイル表示、full-border, smart-enter, starship プラグイン動作を確認
- [ ] 5-10: プレビュー機能（画像、PDF 等）が正常動作することを確認
- [ ] 5-11: yazi → tokyo-night の色を確認（BennyOe flavor との差異に注意）
- [ ] 5-12: `config/yazi/` ディレクトリを削除
- [ ] 5-13: コミット

### フェーズ 6: bat, fzf の Stylix target 有効化

- [ ] 6-1: `nix/home/stylix.nix` に `stylix.targets.bat.enable = true`, `stylix.targets.fzf.enable = true` を追加
- [ ] 6-2: `nix/home/programs/bat.nix` の `config.style` が Stylix と競合しないか確認（`style` と `theme` は独立オプションのため競合しない想定）
- [ ] 6-3: `drs` を実行し正常完了を確認
- [ ] 6-4: `bat` でファイル表示 → tokyo-night の色になっていることを確認
- [ ] 6-5: `fzf` 起動 → tokyo-night の色を確認
- [ ] 6-6: コミット

### フェーズ 7: クリーンアップ

- [ ] 7-1: 空になった `config/` ディレクトリの確認・削除
- [ ] 7-2: `nix flake check` がローカルで成功することを確認
- [ ] 7-3: push して CI が緑になることを確認

---

## 変更対象ファイル一覧

| ファイル                          | 操作                                                                                                     | フェーズ      |
| --------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------- |
| `flake.nix`                       | stylix input + module 追加                                                                               | 2             |
| `nix/hosts/darwin-shared.nix`     | `system.defaults` 追加, Stylix core 設定, casks から ghostty 削除                                        | 1, 2, 4       |
| `nix/home/stylix.nix`             | 新規: HM レベル targets 設定                                                                             | 2, 3, 4, 5, 6 |
| `nix/home/default.nix`            | xdg.enable = true 追加, imports に stylix.nix 追加, packages から lazygit・yazi・yazi 依存パッケージ削除 | 0, 2, 3, 5    |
| `nix/home/symlinks.nix`           | lazygit, ghostty, yazi エントリ削除                                                                      | 3, 4, 5       |
| `nix/home/programs/default.nix`   | imports に lazygit, ghostty, yazi 追加                                                                   | 3, 4, 5       |
| `nix/home/programs/lazygit.nix`   | 新規作成                                                                                                 | 3             |
| `nix/home/programs/ghostty.nix`   | 新規作成                                                                                                 | 4             |
| `nix/home/programs/yazi.nix`      | 新規作成                                                                                                 | 5             |
| `nix/home/programs/yazi-init.lua` | config/yazi/init.lua から移動                                                                            | 5             |
| `nix/home/programs/bat.nix`       | Stylix 競合確認（変更不要の想定）                                                                        | 6             |
| `config/lazygit/`                 | 削除                                                                                                     | 3             |
| `config/ghostty/`                 | 削除                                                                                                     | 4             |
| `config/yazi/`                    | 削除                                                                                                     | 5             |

---

## 実現可能性レビュー

| 懸念                                                               | 検証結果                                                                                                                             | 根拠                                                                                                |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| Stylix モジュール名は `stylix.darwinModules.stylix` か             | 正しい                                                                                                                               | [Stylix Installation](https://nix-community.github.io/stylix/installation.html)                     |
| `autoEnable = false` で既存設定に影響しないか                      | 影響しない。個別 target の `enable = true` が必要                                                                                    | [Stylix Configuration](https://nix-community.github.io/stylix/configuration.html)                   |
| Stylix targets（ghostty, lazygit, yazi, bat, fzf）は存在するか     | すべて存在                                                                                                                           | [Stylix HM Options](https://nix-community.github.io/stylix/options/platforms/home_manager.html)     |
| `pkgs.ghostty-bin` は macOS で使えるか                             | 使える。`pkgs.ghostty` は Linux 専用でビルド失敗する                                                                                 | [ghostty discussions #10496](https://github.com/ghostty-org/ghostty/discussions/10496)              |
| `pkgs.yaziPlugins` に smart-enter, starship, full-border はあるか  | 3 つとも存在                                                                                                                         | [MyNixOS yaziPlugins](https://mynixos.com/nixpkgs/packages/yaziPlugins)                             |
| `base16Scheme` の `tokyo-night-dark` は正しいか                    | `${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml` で正しい                                                                 | base16-schemes リポジトリ                                                                           |
| ghostty keybind `[ "shift+enter=text:\\n" ]` は正しい形式か        | 正しい。`listsAsDuplicateKeys` で複数 keybind にも対応                                                                               | home-manager ghostty module                                                                         |
| ghostty `command` のシングルクォートは正しく処理されるか           | keyValue generator がクォートなしで出力するため問題なし                                                                              | home-manager ghostty module                                                                         |
| bat の `config.style` と Stylix は競合するか                       | 競合しない。`style`（UI要素）と `theme`（配色）は独立オプション                                                                      | —                                                                                                   |
| delta に Stylix が干渉するか                                       | しない。Stylix に delta モジュールはない                                                                                             | —                                                                                                   |
| fzf に Stylix が干渉するか                                         | しない。現在の `fzf.nix` は `enable = true` のみ                                                                                     | —                                                                                                   |
| Stylix `followSystem` は HM に自動伝播するか                       | する。`stylix.darwinModules.stylix` が system + HM 統合を含む                                                                        | [Stylix Installation](https://nix-community.github.io/stylix/installation.html)                     |
| Stylix lazygit の `selectedLineBgColor` を上書きできるか           | `lib.mkForce` が必須。Stylix が通常優先度で設定するため                                                                              | [Stylix lazygit module](https://github.com/nix-community/stylix/blob/master/modules/lazygit/hm.nix) |
| lazygit の `pagers` を Nix リストで表現できるか                    | `programs.lazygit.settings` は `pkgs.formats.yaml` 型。リスト構造を維持する必要あり                                                  | home-manager lazygit module                                                                         |
| yazi の非デフォルト設定はどれか                                    | `sort_by = "natural"`, `show_hidden = true`, `title_format = ""` の 3 項目のみ。`ratio` やカスタム opener はデフォルトと同じ         | yazi v26.1.22 `yazi-default.toml` との diff                                                         |
| yazi 依存パッケージの配置先                                        | `programs.yazi.extraPackages` を使用                                                                                                 | home-manager yazi module                                                                            |
| yazi の `initLua` でプラグイン名は一致するか                       | `pkgs.yaziPlugins` のディレクトリ命名は nixpkgs 規約に従う。`drs` 後に `~/.config/yazi/plugins/` を確認すること                      | —                                                                                                   |
| Homebrew ghostty の削除タイミング                                  | `cleanup = "uninstall"` で `drs` 時に自動削除。一時的に不在になるが GUI アプリのため問題なし                                         | —                                                                                                   |
| Stylix yazi テーマと BennyOe/tokyo-night flavor の差異             | 同じパレット由来だがファイルタイプ別の色割り当て等が異なる可能性あり。許容可能なトレードオフ。`programs.yazi.theme` で個別上書き可能 | —                                                                                                   |
| ghostty ビルトイン `tokyonight` と Stylix base16 テーマの差異      | ANSI カラー 0-15 のマッピングが微妙に異なる可能性あり。背景・前景色は一致                                                            | —                                                                                                   |
| macOS で `xdg.enable = false` のとき HM モジュールのパスがずれるか | ずれる。lazygit 等 10 モジュールが `~/Library/Application Support/` に書く。`.zshenv` の `XDG_CONFIG_HOME` と不整合                  | home-manager lazygit.nix L12-17 の `isDarwin && !config.xdg.enable` パターン                        |
| `xdg.enable = true` で既存設定に影響するか                         | 影響しない。`home.sessionVariables` に XDG 変数を追加するが、`.zshenv` で既に同じ値を設定済み                                        | home-manager xdg.nix                                                                                |
| Stylix ghostty の `cursor-color` が競合するか                      | 競合する。Stylix が `cursor-color = colors.base05` を通常優先度で設定。`lib.mkForce` で上書き必須                                    | Stylix `modules/ghostty/hm.nix`                                                                     |
| `selectedRangeBgColor` は有効なオプションか                        | 無効。lazygit の最新版で削除済み。`selectedLineBgColor` が両方をカバー                                                               | lazygit `pkg/config/user_config.go` の ThemeConfig struct                                           |

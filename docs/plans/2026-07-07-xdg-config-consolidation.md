# 設定ファイルの XDG ベース config/ 集約 実装計画

## 概要

- 設定生成のみを担う `programs.*`(bat / delta / eza / fzf / gh / git / ghostty / lazygit / starship / zoxide)を廃止し、設定を `config/` + symlink へ、パッケージを `home.packages` へ移す
- yazi は設定 3 ファイルのみ外出しし、plugins / flavors / extraPackages は `programs.yazi` に残す
- nh / direnv / sketchybar は機構提供(flake 連携・nix-direnv・launchd)のため現状維持

**出典**:

- [ADR: 設定ファイルの XDG ベース config/ 集約](../adr/2026-07-07-xdg-config-consolidation.md)

---

## 決定事項

| 項目             | 決定                                                        | 備考                                                                     |
| ---------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------ |
| 線引き基準       | **設定生成のみの programs.\* は廃止、機構提供は残留**       | 残留: nh / direnv / sketchybar / yazi(plugins・flavors)                  |
| enable のみ組    | **programs 削除 + packages/shell.nix へ追加**               | bat のみ `config/bat/config` 新設。eza の git/icons は死に設定のため削除 |
| git + delta      | **config/git/config に統合**                                | delta は `[delta]` セクション + `core.pager`。include は `~` 絶対パス    |
| gh               | **config.yml のみ個別 symlink**                             | `hosts.yml`(認証トークン)があるため dir 全体は symlink しない            |
| lazygit          | **config.yml のみ個別 symlink**                             | lazygit が config dir に state を書くバージョン差異への保険              |
| ghostty          | **config/ghostty へ全移行、command は PATH 解決**           | package は darwin.nix(ghostty-bin)/ linux.nix(ghostty)へ                 |
| yazi             | **yazi.toml / theme.toml / init.lua を個別 symlink**        | HM が `yazi/plugins`・`yazi/flavors` を書くため dir 全体 symlink は不可  |
| パッケージ移設先 | **CLI 汎用 → shell.nix、git 系 → dev.nix、GUI → OS 別**     | git / delta / gh / lazygit は dev.nix                                    |
| 検証方法         | **現行 HM 生成物と diff → `just check` → `nrs` → 動作確認** | 生成物は `~/.config/` 配下の store symlink なので直接 diff 可能          |
| 適用単位         | **Phase ごとに `nrs` 適用・検証**                           | 一括切り替えせず段階的にロールバック可能性を残す                         |

---

## 実現可能性レビュー

| 懸念                                     | 検証結果            | 根拠                                                                                        |
| ---------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------- |
| lazygit が macOS で `~/.config` を読むか | 読む(条件付き)      | `XDG_CONFIG_HOME` を `.zshenv` で設定済み。Phase 3 で `lazygit --print-config-dir` を確認   |
| ghostty `command` の PATH 解決           | /bin/zsh が使われる | GUI 起動時 PATH は `/usr/bin:/bin:...`。macOS 標準 zsh も 5.9 系で `.zshenv`/ZDOTDIR は共通 |
| yazi の dir 全体 symlink                 | 不可                | `programs.yazi` が `~/.config/yazi/plugins`・`flavors` を書き込むため個別 symlink が必須    |
| gh の config.yml 自己書き換え            | 許容                | symlink 経由で repo に diff が現れ追跡可能(AskUserQuestion で確認済み)                      |
| eza オプションの削除影響                 | なし                | エイリアス生成専用オプションで、シェル統合無効のため現状も未使用                            |

---

## 設計: config/bat/config

```text
--style=header,grid
```

---

## 設計: config/git/config

delta の設定(旧 `programs.delta`)を統合する。

```ini
[user]
  useConfigOnly = true
[init]
  defaultBranch = main
[merge]
  conflictstyle = diff3
[diff]
  colorMoved = default
[fetch]
  prune = true
[ghq]
  root = ~/Projects
[core]
  pager = delta
[interactive]
  diffFilter = delta --color-only
[delta]
  side-by-side = true
  line-numbers = true
  navigate = true
  plus-style = "syntax #043103"
  minus-style = "syntax #8D3043"
  syntax-theme = "Monokai Extended"
[include]
  path = ~/.config/git/config.local
```

## 設計: config/git/ignore

```text
.DS_Store
._*
node_modules/
*.log
.bundle/
*.local
*.local.*
```

---

## 設計: config/gh/config.yml

```yaml
git_protocol: https
prompt: enabled
prefer_editor_prompt: disabled
spinner: enabled
aliases:
  co: pr checkout
version: 1
```

---

## 設計: config/lazygit/config.yml

```yaml
git:
  pagers:
    - colorArg: always
      pager: delta --dark --paging=never
gui:
  language: ja
  nerdFontsVersion: "3"
  sidePanelWidth: 0.15
  showIcons: true
  theme:
    selectedLineBgColor:
      - underline
refresher:
  refreshInterval: 3
os:
  editPreset: nvim-remote
```

---

## 設計: config/ghostty/config

`command` の Nix store パス(`${zshPath}`)を PATH 解決の `zsh` に置き換える以外は現行生成物と同一。

```text
font-family = "Moralerspace Xenon HW"
window-title-font-family = "Moralerspace Xenon HW"
font-size = 18
font-thicken = false
theme = tokyonight
background-opacity = 0.85
background-blur-radius = 20
unfocused-split-opacity = 0.7
cursor-opacity = 0.8
cursor-color = #ffffff
cursor-style = block
window-theme = auto
window-padding-color = background
window-padding-x = 2
window-padding-y = 2
window-padding-balance = true
window-step-resize = false
window-save-state = default
window-inherit-working-directory = true
clipboard-read = allow
clipboard-write = allow
clipboard-trim-trailing-spaces = true
shell-integration = detect
quick-terminal-position = top
quick-terminal-size = 60%,80%
command = zsh -lic 'if [[ -n $GHOSTTY_QUICK_TERMINAL ]]; then exec zsh -li; fi; ghostty +boo; herdr'
keybind = shift+enter=text:\n
keybind = global:f13=toggle_quick_terminal

# macOS 以外では無視される
macos-icon = xray
macos-titlebar-style = hidden
```

---

## 設計: config/yazi/

```toml
# config/yazi/yazi.toml
[mgr]
sort_by = "natural"
show_hidden = true
title_format = ""
```

```toml
# config/yazi/theme.toml
[flavor]
use = "tokyo-night"
dark = "tokyo-night"
```

```lua
-- config/yazi/init.lua
require("starship"):setup()
require("full-border"):setup()
require("smart-enter"):setup({
  open_multi = true,
})
```

---

## 設計: nix/home/programs/yazi.nix(縮小後)

```nix
{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    plugins = {
      inherit (pkgs.yaziPlugins) smart-enter starship full-border;
    };
    flavors = {
      tokyo-night = pkgs.fetchFromGitHub {
        owner = "BennyOe";
        repo = "tokyo-night.yazi";
        rev = "8e6296f";
        hash = "sha256-LArhRteD7OQRBguV1n13gb5jkl90sOxShkDzgEf3PA0=";
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

## 設計: nix/home/programs/default.nix(縮小後)

```nix
{
  imports = [
    ./nh.nix
    ./sketchybar.nix
    ./yazi.nix
  ];
}
```

---

## 設計: nix/home/symlinks.nix(xdg.configFile 最終形)

既存エントリの末尾に追記する。`home.file`(claude / .zshenv)は変更なし。

```nix
  xdg.configFile = {
    "btop".source = mkLink "config/btop";
    "nvim".source = mkLink "config/nvim";
    "herdr".source = mkLink "config/herdr";
    "gomi".source = mkLink "config/gomi";
    "lazydocker".source = mkLink "config/lazydocker";
    "zabrze".source = mkLink "config/zabrze";
    "vim".source = mkLink "config/vim";
    "mise".source = mkLink "config/mise";
    "zsh".source = mkLink "config/zsh";
    "wezterm".source = mkLink "config/wezterm";
    "starship.toml".source = mkLink "config/starship/starship.toml";
    "bat".source = mkLink "config/bat";
    "ghostty".source = mkLink "config/ghostty";
    "git/config".source = mkLink "config/git/config";
    "git/ignore".source = mkLink "config/git/ignore";
    "gh/config.yml".source = mkLink "config/gh/config.yml";
    "lazygit/config.yml".source = mkLink "config/lazygit/config.yml";
    "yazi/yazi.toml".source = mkLink "config/yazi/yazi.toml";
    "yazi/theme.toml".source = mkLink "config/yazi/theme.toml";
    "yazi/init.lua".source = mkLink "config/yazi/init.lua";
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "karabiner".source = mkLink "config/karabiner";
    "aerospace".source = mkLink "config/aerospace";
  };
```

---

## 設計: パッケージ移設

```nix
# nix/home/packages/shell.nix(アルファベット順で挿入)
home.packages = with pkgs; [
  bat
  btop
  cmatrix
  cowsay
  eza
  fd
  fzf
  gomi
  hyperfine
  jq
  lolcat
  oha
  ripgrep
  sheldon
  starship
  termdown
  zabrze
  zoxide
  zsh
];
```

```nix
# nix/home/packages/dev.nix(アルファベット順で挿入)
home.packages = with pkgs; [
  awscli2
  delta
  gh
  ghq
  git
  google-cloud-sdk
  hadolint
  lazydocker
  lazygit
  mkcert
  pgcli
  postgresql
  rustup
  sqldiff
  ssm-session-manager-plugin
  tenv
];
```

```nix
# nix/home/darwin.nix
home.packages = with pkgs; [
  ghostty-bin
  terminal-notifier
  macism
];
```

```nix
# nix/home/linux.nix(home.packages 先頭部のみ)
home.packages = with pkgs; [
  ghostty
  wezterm
  # (Fonts は変更なし)
];
```

---

## 実装手順

各 Phase 共通の流れ: config 作成 → 現行生成物と diff で一致確認(store パス・キー順の差は許容)→ Nix 側切り替え → `git add` → `just check` → ユーザーが `! nrs` → 動作確認。

### Phase 1: enable のみ組(bat / eza / fzf / zoxide / starship)

- [x] 1-1: `config/bat/config` を作成し、`diff ~/.config/bat/config config/bat/config` で一致確認(差分は programs.ghostty 由来の map-syntax 行のみ。予実差異参照)
- [x] 1-2: `symlinks.nix` に `"bat"` を追加
- [x] 1-3: `packages/shell.nix` に bat / eza / fzf / starship / zoxide を追加
- [x] 1-4: `programs/{bat,eza,fzf,starship,zoxide}.nix` を `git rm` し、`programs/default.nix` の imports を更新
- [x] 1-5: `git add` → `just check`(all checks passed。programs.bat.enable=false も nix eval で確認済み)
- [x] 1-6: `! nrs` 適用後、`command -v bat eza fzf zoxide starship`・`bat` のスタイル・`ei` エイリアス・`z` ジャンプ・プロンプト表示を確認(全項目 OK。~/.config/bat は repo に解決)

> **予実差異**: 現行生成物の `bat/config` には `programs.ghostty` の `installBatSyntax`(デフォルト有効)由来の `--map-syntax` 行と `syntaxes/` ディレクトリが含まれており、`--style` のみの新ファイルとは完全一致しない。`programs.bat` 無効化により installBatSyntax は不活性となり、bat の Ghostty 設定ハイライトは本 Phase 適用時点で消失(Phase 3 の想定が前倒し)。実害は bat で ghostty config を開いた際の色付けのみのため許容。

### Phase 2: git 系(git / delta / gh)

- [x] 2-1: `config/git/config`・`config/git/ignore` を作成し、現行 `~/.config/git/*` と diff 確認(差分は delta の store パス→PATH 置換のみ。ignore は完全一致)
- [x] 2-2: `config/gh/config.yml` を作成し、現行 `~/.config/gh/config.yml` と diff 確認(完全一致。`editor: ''` を含めて踏襲)
- [x] 2-3: `symlinks.nix` に `git/config`・`git/ignore`・`gh/config.yml` を追加
- [x] 2-4: `packages/dev.nix` に git / delta / gh を追加
- [x] 2-5: `programs/{git,delta,gh}.nix` を `git rm` し、imports を更新
- [x] 2-6: `git add` → `just check`(all checks passed)
- [x] 2-7: `! nrs` 適用後、`git config --get ghq.root`・`git config --get user.name`(config.local 経由)・`git diff` の delta 表示・`gh config get git_protocol` を確認(全項目 OK。gh 認証・hosts.yml も無傷)

> **予実差異**: delta の git 統合は計画の `[core] pager` ではなく、HM 生成物と同じ `[pager]`(blame/diff/log/show)+ `[interactive] diffFilter` で再現した(実生成形に合わせ挙動差を排除)。
> また gh の生成物には計画になかった `editor: ''` があり、そのまま踏襲した(pre-commit の prettier により `""` に正規化)。
> 生成物を `cp` すると Nix store の読み取り専用パーミッション(444)を引き継ぎ pre-commit hook の書き込みが失敗するため、`chmod 644` が必要だった。

### Phase 3: lazygit / ghostty

- [ ] 3-1: `config/lazygit/config.yml` を作成し、現行生成物と diff 確認
- [ ] 3-2: `config/ghostty/config` を作成し、現行生成物と diff 確認(差分が command 行の zsh パスのみであること)
- [ ] 3-3: `symlinks.nix` に `lazygit/config.yml`・`ghostty` を追加
- [ ] 3-4: `packages/dev.nix` に lazygit、`darwin.nix` に ghostty-bin、`linux.nix` に ghostty を追加
- [ ] 3-5: `programs/{lazygit,ghostty}.nix` を `git rm` し、imports を更新
- [ ] 3-6: `git add` → `just check`
- [ ] 3-7: `! nrs` 適用後、`lazygit --print-config-dir` が `~/.config/lazygit` を指すこと・delta ページャ・日本語 UI を確認
- [ ] 3-8: ghostty を再起動し、通常起動(herdr 立ち上がり)・quick terminal(F13)・フォント/テーマ適用を確認

### Phase 4: yazi 分割

- [ ] 4-1: `config/yazi/{yazi.toml,theme.toml,init.lua}` を作成し、現行生成物と diff 確認
- [ ] 4-2: `just lint-lua` で init.lua の lint 通過を確認
- [ ] 4-3: `programs/yazi.nix` から `settings`・`initLua`・`theme` を削除(縮小後の設計を適用)
- [ ] 4-4: `symlinks.nix` に yazi の個別 3 エントリを追加
- [ ] 4-5: `git add` → `just check`
- [ ] 4-6: `! nrs` 適用後、yazi 起動で tokyo-night flavor・full-border・隠しファイル表示・smart-enter 動作を確認

### Phase 5: ドキュメント更新

- [ ] 5-1: `.claude/skills/nix-guide/SKILL.md` の Conventions(「HM モジュールがある場合は programs を優先」)を線引き基準に沿って書き換え、Module Structure の記述を更新
- [ ] 5-2: 本 Plans のチェックリストと予実差異を最終確認

---

## 変更対象ファイル一覧

| ファイル                                      | Phase 1        | Phase 2        | Phase 3                | Phase 4       | Phase 5 |
| --------------------------------------------- | -------------- | -------------- | ---------------------- | ------------- | ------- |
| `config/bat/config`                           | 新規           | -              | -                      | -             | -       |
| `config/git/{config,ignore}`                  | -              | 新規           | -                      | -             | -       |
| `config/gh/config.yml`                        | -              | 新規           | -                      | -             | -       |
| `config/lazygit/config.yml`                   | -              | -              | 新規                   | -             | -       |
| `config/ghostty/config`                       | -              | -              | 新規                   | -             | -       |
| `config/yazi/{yazi.toml,theme.toml,init.lua}` | -              | -              | -                      | 新規          | -       |
| `nix/home/symlinks.nix`                       | bat 追加       | git / gh 追加  | lazygit / ghostty 追加 | yazi 追加     | -       |
| `nix/home/packages/shell.nix`                 | 5 ツール追加   | -              | -                      | -             | -       |
| `nix/home/packages/dev.nix`                   | -              | git/delta/gh   | lazygit 追加           | -             | -       |
| `nix/home/darwin.nix`                         | -              | -              | ghostty-bin 追加       | -             | -       |
| `nix/home/linux.nix`                          | -              | -              | ghostty 追加           | -             | -       |
| `nix/home/programs/default.nix`               | imports 削減   | imports 削減   | imports 削減           | -             | -       |
| `nix/home/programs/*.nix`                     | 5 ファイル削除 | 3 ファイル削除 | 2 ファイル削除         | yazi.nix 縮小 | -       |
| `.claude/skills/nix-guide/SKILL.md`           | -              | -              | -                      | -             | 更新    |

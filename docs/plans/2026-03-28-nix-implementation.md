# Nix導入実装計画

## 概要

このdotfilesにNixを導入し、以下を実現する:

- **ランタイム**: mise維持（Node.js, Python等）※miseはNix経由でインストール
- **CLIツール**: Nixで管理（home-manager）
- **GUIアプリ**: nix-darwin経由でHomebrew caskを宣言的管理
- **Neovim LSP**: Mason維持
- **Zshプラグイン**: Sheldon維持（Nix経由でインストール）
- **dotfilesシンボリックリンク**: home-managerの `mkOutOfStoreSymlink` で管理（mutableワークフロー維持）

---

## ディレクトリ構成

`flake.nix`はリポジトリルートに配置し、モジュール群は`nix/`サブディレクトリに整理する。
共通設定を厚く、OS/ホスト固有設定を薄く保つ。

```text
dotfiles/
├── flake.nix                 # エントリーポイント（ルート）
├── flake.lock                # git管理必須
├── nix/
│   ├── home/
│   │   ├── default.nix       # 共通home-manager設定（imports束ねる + 共通パッケージ）
│   │   ├── shell.nix         # direnv等shell関連programs
│   │   ├── symlinks.nix      # xdg.configFile / home.file（dotfilesリンク管理）
│   │   └── darwin.nix        # macOS専用パッケージ (macism, terminal-notifier等)
│   ├── hosts/
│   │   └── darwin-shared.nix # nix-darwin共通設定（homebrew, fonts, nix設定）
│   └── overlays/
│       ├── default.nix
│       └── zabrze.nix
├── config/                   # 既存の設定ファイル群
└── scripts/
    └── install.sh            # Nixインストール処理追加
```

**実行方法**:

```bash
darwin-rebuild switch --flake .#<hostname>
```

---

## 決定事項

| 項目                      | 決定                                  | 備考                                                                                              |
| ------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Nixディストリビューション | **upstream Nix（本家）**              | ベンダーロックインなし、Linux展開もシームレス                                                     |
| Nixインストーラー         | **NixOS公式** (`NixOS/nix-installer`) | 実装時にURLの有効性を確認すること                                                                 |
| flakes有効化              | `nix.settings.experimental-features`  | darwin-shared.nixで1行設定                                                                        |
| IME切り替え               | macismのみ                            | im-select削除。macismはnixpkgs既存 (v3.0.10)                                                      |
| tenv                      | Nix経由で維持                         | nixpkgsに存在                                                                                     |
| フォント                  | MoralerspaceⅡに統一                   | 既存フォント（PlemolJP, HackGen等）は維持                                                         |
| 移行戦略                  | Homebrew併存                          | `cleanup = "none"` で安全に段階移行                                                               |
| terminal-notifier         | nixpkgsで管理                         | 実装時に存在確認                                                                                  |
| 設定セット識別子          | **GitHub ユーザー名 `suta-ro`**       | OS のホスト名には依存しない。`darwinConfigurations` のキーは設定セットの識別子（正誤表 5-7 参照） |
| ユーザー名                | `suta-ro`                             | `specialArgs` で一元管理、ハードコードしない                                                      |
| direnv                    | フェーズ1で導入                       | nix-direnv付き                                                                                    |
| Homebrew cask             | nix-darwinで宣言的管理                | upgrade=false                                                                                     |
| nix-homebrew              | 導入する                              | Homebrew自体の宣言的管理、autoMigrate                                                             |
| stateVersion              | `"25.11"`                             | `release-25.11` が最新安定版（2026-03時点）。`version.nix` の enum で確認済み                     |
| WezTerm                   | cask維持                              | Spotlight対応のため                                                                               |
| mac-app-util              | 不要（検証後判断）                    | HM 25.05+ copyAppsデフォルト化                                                                    |
| home-manager統合方式      | nix-darwin moduleとして一体構築       | standalone → module移行の二度手間を排除                                                           |
| dotfilesリンク管理        | home-managerの `mkOutOfStoreSymlink`  | install.shの手動symlink管理を置き換え。mutableワークフロー維持                                    |
| Gitアカウント             | `config.local` でマシン別管理を維持   | `useConfigOnly = true` で未設定マシンをブロック                                                   |
| Homebrew廃止時のcleanup   | `"uninstall"`                         | `"zap"` は設定データも消すため危険                                                                |
| Claude Code               | nixpkgs `claude-code`                 | npm由来パッケージ。更新ラグ3〜7日。最新追従が必要なら `ryoppippi/claude-code-overlay` に切替可    |
| mise install              | install.shまたは手動で実行            | miseバイナリはNix管理、ランタイム(Node.js等)はmise管理                                            |
| mise config.toml          | マシン固有、git管理外                 | `config.local` と同パターン。各マシンで手動作成                                                   |

---

## 設計方針

### 複数Mac対応

```nix
flake.nix
  darwinConfigurations."hostname-a" = mkDarwinConfig { hostname = "hostname-a"; };
  darwinConfigurations."hostname-b" = mkDarwinConfig { hostname = "hostname-b"; };
```

- `mkDarwinConfig` ヘルパーで共通modulesを束ね、ホスト固有の差分だけ渡す
- 現時点でホスト固有設定が不要でも、**ホストごとにエントリを分けておく**（後からcask差分等を入れやすい）
- ホスト固有設定が必要になったら `nix/hosts/<hostname>.nix` を追加

### 複数Gitアカウント

既存の `config/git/config` の設計がすでに正しい:

```gitconfig
[include]
  path = ~/.config/git/config.local    # マシン別。gitignoreで *.local 除外済み

[user]
  useConfigOnly = true                 # config.local未配置ならcommitをブロック
```

Nix側でやることは:

- `config/git/config` を `xdg.configFile` でリンクするだけ
- `config.local` はNix管理**しない**（マシン固有、手動配置を維持）
- 新しいマシンのセットアップ手順に `config.local` の作成を含める

### Linux展開（実装済み）

`mkHomeConfig` ヘルパーと `nix/home/linux.nix` で standalone home-manager をサポート。
詳細は [Linux support Plans](2026-04-11-linux-support.md) を参照。

---

## ユースケース

- 複数のApple Silicon Macで環境統一（初日から複数台適用）
- 将来的にLinuxへも展開（upstream Nixなのでそのまま動く）
- 徹底したライブラリとバージョン管理
- Nix学習

## 最終目標

- **Homebrewを完全廃止**し、Nixに一本化（cask除く）
- GUIアプリはnix-darwinで宣言的管理
- mise, sheldonはNix経由でインストールし維持

---

## フェーズ1: Nix基盤 + nix-darwin + home-manager 一体構築

### 1-1. Nixインストール処理の追加

**ファイル**: `scripts/install.sh`

miseセットアップの後に追加:

```bash
# Nix setup
echo "--- Nix Setup ---"
if command -v nix &>/dev/null; then
  echo "Nix is already installed."
else
  echo "Installing Nix (NixOS official installer)..."
  # NOTE: 実装時にURLの有効性を確認すること
  # 代替: https://nixos.org/nix/install
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
  echo "Nix installation complete."
  echo "Please restart your shell and run this script again."
  exit 0
fi
```

**検証**:

```bash
nix --version
```

### 1-2. flake.nixの作成

**ファイル**: `flake.nix`（リポジトリルート）

```nix
{
  description = "suta-ro's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew }:
    let
      username = "suta-ro";
      dotfilesPath = "/Users/${username}/Projects/dotfiles";

      # フェーズ1では空。フェーズ2でoverlay追加時に (import ./nix/overlays) を追加する
      sharedOverlays = [
      ];

      mkDarwinConfig = { hostname, system ? "aarch64-darwin" }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit username hostname; };
          modules = [
            { nixpkgs.overlays = sharedOverlays; }
            ./nix/hosts/darwin-shared.nix
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = import ./nix/home;
                extraSpecialArgs = { inherit username dotfilesPath; };
              };
            }
          ];
        };
    in {
      darwinConfigurations = {
        # 実際のホスト名に置き換えること
        "hostname-a" = mkDarwinConfig { hostname = "hostname-a"; };
        "hostname-b" = mkDarwinConfig { hostname = "hostname-b"; };
      };

      # Linux (standalone home-manager) — 将来用
      # homeConfigurations."${username}@ubuntu" = home-manager.lib.homeManagerConfiguration {
      #   pkgs = import nixpkgs { system = "x86_64-linux"; overlays = sharedOverlays; };
      #   modules = [ ./nix/home ];
      #   extraSpecialArgs = { inherit username dotfilesPath; };
      # };
    };
}
```

**検証**:

```bash
cd ~/Projects/dotfiles
nix flake check
```

### 1-3. home/default.nixの作成

**ファイル**: `nix/home/default.nix`

```nix
{ pkgs, lib, username, ... }:
{
  imports = [
    ./shell.nix
    ./symlinks.nix
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    ./darwin.nix
  ];

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${username}"
    else "/home/${username}";
  # NOTE: 実装時に home-manager --version で正しい値を確認すること
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # base
    git
    neovim
    vim
    tmux

    # shell tools
    ripgrep
    bat
    eza
    fd
    gomi
    zoxide
    fzf

    # views
    starship
    delta
    gitmux

    # tui
    lazygit
    lazydocker
    yazi

    # yazi dependencies
    ffmpeg
    poppler-utils
    imagemagick
    resvg
    _7zz

    # cli
    awscli2
    gh
    ghq
    jq
    pgcli
    google-cloud-sdk
    ssm-session-manager-plugin

    # dev
    hadolint
    shellcheck
    luarocks
    libpq
    sqlite
    sqldiff

    # package managers
    mise
    sheldon
    tenv

    # editor
    claude-code
  ];

  programs.home-manager.enable = true;
}
```

### 1-4. home/shell.nixの作成

**ファイル**: `nix/home/shell.nix`

```nix
{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = false; # zshはsheldon管理のため手動hook（下記1-9参照）
  };
}
```

> **Note**: `enableZshIntegration = true` は `programs.zsh.enable = true` が前提。このdotfilesではzshをsheldon経由で管理するため、hookは `config/zsh/lazy/direnv.zsh` に手動追加する。

### 1-5. home/darwin.nixの作成

**ファイル**: `nix/home/darwin.nix`

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    terminal-notifier
    macism
  ];
}
```

### 1-6. home/symlinks.nixの作成

**ファイル**: `nix/home/symlinks.nix`

install.shの手動シンボリックリンク管理をhome-managerに移管する。

`mkOutOfStoreSymlink` を使用し、Nix store を経由しない直接シンボリックリンクを作成する。
これにより設定ファイルの編集が即座に反映され、`darwin-rebuild switch` なしで変更が有効になる。

> **Note**: `source = ../../config/...` のような相対パスは Flake 環境では Nix store にコピーされ immutable になる。
> `mkOutOfStoreSymlink` + 絶対パス文字列を使うことで mutable なシンボリックリンクを実現する。

```nix
{ config, lib, pkgs, dotfilesPath, ... }:
let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
in {
  xdg.configFile = {
    "nvim".source = mkLink "config/nvim";
    "ghostty".source = mkLink "config/ghostty";
    "tmux".source = mkLink "config/tmux";
    "starship".source = mkLink "config/starship";
    "git".source = mkLink "config/git";
    "gitmux".source = mkLink "config/gitmux";
    "gomi".source = mkLink "config/gomi";
    "lazygit".source = mkLink "config/lazygit";
    "lazydocker".source = mkLink "config/lazydocker";
    "yazi".source = mkLink "config/yazi";
    "zabrze".source = mkLink "config/zabrze";
    "vim".source = mkLink "config/vim";
    "mise".source = mkLink "config/mise";
    "zsh".source = mkLink "config/zsh";
    "gh".source = mkLink "config/gh";
    "wezterm".source = mkLink "config/wezterm";
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    "karabiner".source = mkLink "config/karabiner";
  };

  # Claude CLI はXDG非対応で ~/.claude/ にランタイムファイル（history, sessions, cache, logs等）を
  # 大量に書き込むため、ディレクトリリンクではなく個別ファイルリンクにする。
  # これにより ~/.claude/ は実ディレクトリのまま、管理対象ファイルだけがシンボリックリンクになる。
  home.file = {
    ".claude/CLAUDE.md".source = mkLink "config/claude/CLAUDE.md";
    ".claude/agents".source = mkLink "config/claude/agents";
    ".claude/commands".source = mkLink "config/claude/commands";
    ".claude/file-suggestion.sh".source = mkLink "config/claude/file-suggestion.sh";
    ".claude/hooks".source = mkLink "config/claude/hooks";
    ".claude/mcp".source = mkLink "config/claude/mcp";
    ".claude/rules".source = mkLink "config/claude/rules";
    ".claude/settings.json".source = mkLink "config/claude/settings.json";
    ".claude/skills".source = mkLink "config/claude/skills";
    ".claude/statusline.sh".source = mkLink "config/claude/statusline.sh";
    ".zshenv".source = mkLink "config/zsh/.zshenv";
  };
}
```

> **Note**: `config/claude/` にファイルを追加した場合、`home.file` セクションにもエントリを追加すること。`CLAUDE.md` の Symlink Strategy にも注意書きを記載済み。
> **Note**: `config.local` (Git) は `.gitignore` で除外済み・マシン固有のため、ここには含めない。新マシンセットアップ時に手動作成する。
> **Note**: `~/.claude` を丸ごとリンクしない理由: Claude CLIはXDG非対応で `~/.claude/` 配下にランタイムファイル（history.jsonl, sessions/, cache/, logs/, statsig/, telemetry/ 等）を直接書き込む。ディレクトリリンクだとこれらが `config/claude/` 内に生成されリポジトリが汚れる。参考: [ryoppippi/dotfiles](https://github.com/ryoppippi/dotfiles) も同様に個別ファイルリンク方式を採用。

### 1-7. hosts/darwin-shared.nixの作成

**ファイル**: `nix/hosts/darwin-shared.nix`

```nix
{ pkgs, username, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    interval = { Weekday = 7; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };
    casks = [
      "raycast"
      "ghostty"
      "wezterm"
      "warp"
      "docker"
      "dbeaver-community"
      "karabiner-elements"
      "visual-studio-code"
      "cursor"
      "cursor-cli"
    ];
  };

  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
  };

  fonts.packages = with pkgs; [
    hackgen-font
    hackgen-nf-font
    plemoljp
    plemoljp-nf
    plemoljp-hs
    moralerspace
    moralerspace-hw
  ];

  system.stateVersion = 6;
}
```

> **Note**: ホスト固有のcask差分が必要になった場合、`nix/hosts/<hostname>.nix` を作成し `flake.nix` の `modules` に追加する。

### 1-8. Nix環境の読み込みとPATH設定の修正

**ファイル**: `config/zsh/eager/path.zsh`

`.zshenv`で`unsetopt GLOBAL_RCS`を設定しているため、`/etc/zshrc`のNixフックが読み込まれない。
これによりPATHだけでなく`NIX_SSL_CERT_FILE`・`NIX_PROFILES`等の環境変数も設定されず、`nix`コマンドがflake inputsのfetchに失敗する可能性がある。

`nix-daemon.sh`をsourceすることでPATHと環境変数の両方を設定する。

```zsh
# Nix environment (GLOBAL_RCS=off で /etc/zshrc がスキップされる対策)
# nix-daemon.sh が PATH・NIX_SSL_CERT_FILE・NIX_PROFILES 等を設定する
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

typeset -gU PATH path
typeset -gU FPATH fpath

path=(
    "$HOME/.local/bin"(N-/)
    "/opt/homebrew/bin"(N-/)
    "/opt/homebrew/sbin"(N-/)
    "/opt/homebrew/opt/libpq/bin"(N-/)
    "$XDG_DATA_HOME/mise/shims"
    "/usr/local/bin"(N-/)
    "/usr/local/sbin"(N-/)
    "/usr/bin"(N-/)
    "/usr/sbin"(N-/)
    "/bin"(N-/)
    "/sbin"(N-/)
    "$path[@]"
)

fpath=(
    "$XDG_DATA_HOME/zsh/completions"(N-/)
    "$fpath[@]"
)
```

> **Note**: `nix-daemon.sh`のsourceでNixのPATH（`/run/current-system/sw/bin`、`/etc/profiles/per-user/$USER/bin`等）が自動追加されるため、path配列への手動追加は不要。Homebrewパスより後に追加されるため、Homebrew併存期間中はHomebrewが優先される。

### 1-9. Zshエイリアスの作成

**ファイル**: `config/zsh/lazy/nix.zsh`

```zsh
if command -v nix &>/dev/null; then
  alias nd="nix develop"
  alias ndc="nix develop --command"
  alias nf="nix flake"
  alias nfu="nix flake update"
  alias ngc="nix-collect-garbage -d"

  if [[ "$OSTYPE" == darwin* ]]; then
    alias drs='darwin-rebuild switch --flake ~/Projects/dotfiles#$(scutil --get LocalHostName)'
  fi
fi
```

> **Note**: `drs`がマシンのホスト名を動的に取得するため、flake.nixのエントリ名と`scutil --get LocalHostName`の値を一致させること。

**ファイル**: `config/zsh/lazy/direnv.zsh`

```zsh
eval "$(direnv hook zsh)"
```

> **Note**: home-managerの `programs.direnv.enableZshIntegration` は `programs.zsh.enable` が前提のため、sheldon管理のzshでは手動hookが必要。

### 1-10. .gitignoreの確認

`flake.lock`が除外されていないことを確認。再現性のためgit管理必須。

### 1-11. 適用と検証

> **重要**: `git add flake.nix nix/`を忘れずに。Flakesは未追跡ファイルを無視する。

```bash
# 既存のシンボリックリンクを削除（home-managerと衝突するため）
# ~/.claude/ 内の個別シンボリックリンクを削除（ディレクトリ自体は残す）
find ~/.claude -maxdepth 1 -type l -delete
rm -f ~/.zshenv
# XDG_CONFIG_HOME配下のシンボリックリンクはhome-managerが上書きするため削除不要

git add flake.nix flake.lock nix/
darwin-rebuild switch --flake .#<hostname>
```

**検証**:

```bash
nix --version
nix flake check
which tmux && tmux -V
which gitmux
which macism
which starship
direnv version
```

**新マシンセットアップ手順**:

```bash
# 1. リポジトリをclone
git clone <repo> ~/Projects/dotfiles
# 2. Nixインストール
./scripts/install.sh
# 3. flake.nixに新ホスト名のエントリを追加
# 4. darwin-rebuild switch
darwin-rebuild switch --flake .#<hostname>
# 5. Git config.local を作成（アカウント情報）
cat > ~/.config/git/config.local << 'EOF'
[user]
  name = <name>
  email = <email>
EOF
```

---

## フェーズ2: Overlay作成

必要なoverlayは**zabrzeのみ**。gomiはnixpkgs-unstableに存在する（v1.6.2）ためoverlay不要。

> **Note**: gomiのnixpkgsパッケージ: [pkgs/by-name/go/gomi/package.nix](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/go/gomi/package.nix)

### 2-1. overlays/default.nix

**ファイル**: `nix/overlays/default.nix`

```nix
final: prev: {
  zabrze = prev.callPackage ./zabrze.nix { };
}
```

### 2-2. overlays/zabrze.nix

**ファイル**: `nix/overlays/zabrze.nix`

```nix
{ lib, rustPlatform, fetchFromGitHub }:
rustPlatform.buildRustPackage rec {
  pname = "zabrze";
  version = "0.7.3";
  src = fetchFromGitHub {
    owner = "Ryooooooga";
    repo = "zabrze";
    rev = "v${version}";
    hash = "";
  };
  cargoHash = "";
  meta = with lib; {
    description = "Zsh abbreviation expansion plugin";
    homepage = "https://github.com/Ryooooooga/zabrze";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
```

### 2-4. flake.nixへのoverlay統合

フェーズ1では `sharedOverlays = [];` としていたため、ここで overlay を有効化する。

`flake.nix` の `sharedOverlays` を以下に変更:

```nix
sharedOverlays = [
  (import ./nix/overlays)
];
```

> **Note**: `config.allowUnfree = true` は実際にunfreeパッケージが必要な場合のみ追加すること。

### 2-4. home/default.nixにoverlay製パッケージを追加

```nix
home.packages = with pkgs; [
  # ... 既存パッケージ ...
  zabrze
];
```

> **Note**: gomiはフェーズ1の `home.packages` に既に含まれている（nixpkgsパッケージ）。

### 2-6. 適用と検証

```bash
git add nix/overlays/
darwin-rebuild switch --flake .#<hostname>
which gomi && gomi --version
which zabrze && zabrze --version
```

---

## フェーズ3: Homebrew完全廃止

### 3-1. 全パッケージ動作確認

Brewfileの全formulaeがNix経由で動作することを確認:

```bash
for cmd in git nvim tmux rg bat eza fd gomi zoxide zabrze starship delta gitmux lazygit lazydocker yazi fzf aws pgcli gh ghq mise sheldon tenv luarocks hadolint shellcheck jq macism; do
  echo "$cmd: $(which $cmd)"
done
```

### 3-2. Brewfileの整理

caskのみ残し、formulaeとtapを全削除。

```diff
- tap "daipeihust/tap"
- tap "ryooooooga/tap"
- tap "laishulu/homebrew"
- brew "git"
- brew "neovim"
- brew "tmux"
  ...（全formulae削除）
- brew "im-select"
- cask "font-cica"
```

### 3-3. darwin-shared.nixのcleanupを変更

```nix
homebrew.onActivation.cleanup = "uninstall";
```

> **Note**: `"zap"` ではなく `"uninstall"` を使用。`"zap"` はcaskの設定データまで削除するため危険。
> **重要**: 変更前に `brew bundle dump` でバックアップを推奨。

### 3-4. フォント整理

- font-cica: 削除（MoralerspaceⅡに統一）
- 既存フォント（PlemolJP, HackGen）: 維持
- MoralerspaceⅡ: nixpkgs存在確認後、なければcask

### 3-5. install.shの整理

> **Note**: symlink 処理の削除はフェーズ1（1-6）の symlinks.nix 作成時に実施済みのはず。
> ここでは残りの Homebrew 関連処理（`brew bundle install`）と Claude Code バイナリインストール処理を削除する。

最終的に install.sh に残す処理:

- XDGディレクトリ作成
- Nixインストール
- `mise install`（Node.js, pnpm等のランタイムインストール）

### 3-6. 最終適用

```bash
darwin-rebuild switch --flake .#<hostname>
```

---

## 実装チェックリスト

### フェーズ1: Nix基盤 + nix-darwin + HM

- [x] 1-1: scripts/install.sh にNixインストール処理追加
- [x] 1-2: flake.nix 作成（mkDarwinConfig + 複数ホストエントリ）
- [x] 1-3: nix/home/default.nix 作成（共通パッケージ）
- [x] 1-4: nix/home/shell.nix 作成（direnv）
- [x] 1-5: nix/home/darwin.nix 作成（macOS専用パッケージ）
- [x] 1-6: nix/home/symlinks.nix 作成（dotfilesリンク管理）
- [x] 1-7: nix/hosts/darwin-shared.nix 作成（nix-darwin共通設定）
- [x] 1-8: config/zsh/eager/path.zsh 修正（nix-daemon.sh source + PATH整理）
- [x] 1-9: config/zsh/lazy/nix.zsh 作成（ホスト名動的取得）
- [x] 1-9b: config/zsh/lazy/direnv.zsh 作成（手動direnv hook）
- [x] 1-10: .gitignore 確認（flake.lockが除外されていないこと）
- [x] 1-11: install.sh から手動symlink処理・Claude Codeバイナリインストール処理を削除
- [x] 1-12: darwin-rebuild switch 実行・全ツール動作確認
- [ ] 1-13: 2台目のMacで適用・動作確認

### 実装時の正誤表（フェーズ1）

| #    | 計画書の記載                                                     | 実際に必要だった対応                                 | 原因                                                                                                                                                        |
| ---- | ---------------------------------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1-2  | `flake.nix`: `sharedOverlays = [];`                              | direnv の `overrideAttrs` overlay を追加             | nixpkgs-unstable の direnv ビルドリグレッション (PR #486452)。mise が direnv にビルド依存しているため全体に波及。修正 PR #502769 がチャネル到達後に削除する |
| 1-2  | `flake.nix`: `{ nixpkgs.overlays = sharedOverlays; }`            | `nixpkgs.config.allowUnfreePredicate` を追加         | claude-code が unfree パッケージのため許可が必要                                                                                                            |
| 1-3  | `default.nix`: `imports` で `lib.optionals pkgs.stdenv.isDarwin` | `darwin.nix` を無条件 import + `lib.mkIf` で条件分岐 | `imports` での `pkgs` 参照が infinite recursion を引き起こす                                                                                                |
| 1-3  | `default.nix`: `home.username` / `home.homeDirectory` を設定     | 削除。`darwin-shared.nix` で `users.users` を設定    | `useUserPackages = true` 時に `common.nix` が `users.users.<name>.home` から自動設定するため重複                                                            |
| 1-3  | `default.nix`: `sqlite` を `home.packages` に含む                | 削除                                                 | `sqldiff` は独立バイナリで sqlite に実行時依存しない (nixpkgs `tools.nix` で確認)                                                                           |
| 1-5  | `darwin.nix`: 無条件で `home.packages`                           | `lib.mkIf pkgs.stdenv.isDarwin` でガード             | `imports` から `lib.optionals` を除去したため、darwin.nix 側で条件分岐が必要                                                                                |
| 1-7  | `darwin-shared.nix`: 記載なし                                    | `system.primaryUser = username;` を追加              | nix-darwin 最新版で `homebrew.enable` 等に `system.primaryUser` が必須化                                                                                    |
| 1-7  | `darwin-shared.nix`: 記載なし                                    | `users.users.${username}.home` を追加                | home-manager の `common.nix` が `homeDirectory` をここから取得するため必須                                                                                  |
| 1-7  | `darwin-shared.nix`: `casks` に `"docker"`                       | `"docker-desktop"` に変更                            | Homebrew 側で cask 名が変更された                                                                                                                           |
| 1-9b | `direnv.zsh`: `eval "$(direnv hook zsh)"`                        | `command -v direnv` でガード追加                     | direnv 未インストール時のエラー防止                                                                                                                         |

### フェーズ2: Overlay（zabrzeのみ。gomiはnixpkgsに存在）

- [x] 2-1: nix/overlays/default.nix 作成
- [x] 2-2: nix/overlays/zabrze.nix 作成・ハッシュ取得・ビルド確認
- [x] 2-3: flake.nix の sharedOverlays に `(import ./nix/overlays)` 追加
- [x] 2-4: nix/home/default.nix にzabrze追加
- [x] 2-5: darwin-rebuild switch で再ビルド・動作確認

### 実装時の正誤表（フェーズ2）

| #   | 計画書の記載                           | 実際に必要だった対応                                   | 原因                                                                                                                                |
| --- | -------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| 2-2 | `zabrze.nix`: `hash=""`/`cargoHash=""` | `nix build` でハッシュミスマッチから正しいハッシュ取得 | Nix 標準のハッシュ取得手順。計画書では空文字で記載                                                                                  |
| 2-2 | `zabrze.nix`: テスト記載なし           | `EDITOR = "vim"` を `darwin-shared.nix` に追加         | nix-darwin の `EDITOR=nano` が `set-environment` 経由で伝播し zabrze テスト失敗。macOS は sandbox=false でホスト `/etc/zshenv` 参照 |
| 2-3 | `sharedOverlays` を overlays に変更    | direnv overlay の後に追加する形                        | フェーズ1で direnv overlay が追加済み                                                                                               |
| -   | 記載なし                               | `git add nix/overlays/` が必要                         | Flakes は未追跡ファイルを無視するため                                                                                               |

### フェーズ3: Homebrew廃止

- [x] 3-1: 全CLIツールがNixパスから実行されること確認
- [x] 3-2: Brewfileからformulae・tap削除
- [x] 3-3: `cleanup = "uninstall"` に変更
- [x] 3-4: フォント整理
- [x] 3-5: install.shからHomebrew関連処理を削除
- [x] 3-6: darwin-rebuild switch 最終適用
- [ ] 3-7: 全マシンで最終適用・動作確認

### 実装時の正誤表（フェーズ3）

| #   | 計画書の記載                                     | 実際に必要だった対応                                                                      | 原因                                                                                         |
| --- | ------------------------------------------------ | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| 3-2 | Brewfile から formulae・tap 削除し cask のみ残す | Brewfile を空にし cask も darwin-shared.nix に一元化                                      | cask は既に darwin-shared.nix で宣言的管理済みのため Brewfile に残す意味なし                 |
| 3-3 | `cleanup = "uninstall"` で formulae 削除         | 一部が依存エラーで拒否。`brew uninstall --ignore-dependencies` で手動削除                 | `gcloud-cli`（削除済み）が依存元として残存し cleanup が拒否                                  |
| 3-6 | switch 後に Nix ツールが使われる                 | `path.zsh` で Nix パスが末尾配置され `/usr/bin/git` 等にフォールバック                    | `nix-daemon.sh` のパスは明示指定より後。Nix profile を `/usr/bin` より前に配置する修正が必要 |
| -   | starship がプロンプトに使用                      | Homebrew 強制削除後にシェルが `starship` を見つけられずエラーループ。新規ウィンドウで復旧 | 既存セッションが削除済み `/opt/homebrew/bin/starship` を参照し続けた                         |

### フェーズ4: install.sh 改善

- [x] 4-1: 権限の分離（ユーザー権限処理と root 権限処理を明確に分ける）
- [x] 4-2: `darwin-rebuild switch` の自動実行（sudo の $HOME 問題、PATH 問題を解決）
- [x] 4-3: 冪等性の確保（何度実行しても安全な設計）
- [x] 4-4: エラーハンドリング改善（各ステップの失敗時に適切なメッセージを表示）
- [x] 4-5: OS固有処理のファイル分離（scripts/setup/darwin.sh, linux.sh）
- [x] 4-6: 意図ベースの命名（apply_config, install_runtimes等）
- [x] 4-7: 依存関係の整理（reload_path追加でapply_config後のPATH問題を解決）

### フェーズ5: Nix 言語ツーリング（devShell + Neovim 統合）

- [x] 5-1: flake.nix に devShells 出力を追加（nixfmt, statix, deadnix）
- [x] 5-2: .envrc 作成（use flake）
- [x] 5-3: .gitignore に .direnv 追加
- [x] 5-4: direnv allow で devShell 動作確認
- [x] 5-5: mason.lua から nil を削除（nil は Cargo 必須でビルド失敗のため）
- [x] 5-6: nix/home/default.nix に nixd 追加
- [x] 5-7: lsp/init.lua に nixd 追加
- [x] 5-8: after/lsp/nixd.lua 作成（nil_ls.lua を削除）
- [x] 5-9: conform.lua に nix フォーマッタ追加
- [x] 5-10: nvim-lint.lua に nix リンター追加
- [x] 5-11: nvim-treesitter.lua に nix grammar 追加
- [x] 5-12: drs で nixd をインストール
- [x] 5-13: Neovim で .nix ファイルを開いて全機能動作確認
- [x] 5-14: darwinConfigurations のキーを GitHub ユーザー名 `suta-ro` に変更
- [x] 5-15: darwin-shared.nix から networking.localHostName を削除
- [x] 5-16: drs・install.sh・nixd.lua から scutil 依存を排除
- [x] 5-17: CLAUDE.md・nix-guide.md のドキュメント更新

### 実装時の正誤表（フェーズ5）

| #   | 計画書の記載                                        | 実際に必要だった対応                                                                                     | 原因                                                                                                                                                                                                                |
| --- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5-5 | Mason で nil を管理                                 | nil は Cargo 必須でビルド失敗。nixd を home.packages で管理に変更                                        | Mason の nil パッケージは Rust ツールチェーンからのソースビルドが必要。環境に Rust がなかった                                                                                                                       |
| 5-7 | `darwinConfigurations` のキーに OS のホスト名を使用 | GitHub ユーザー名 `suta-ro` を設定セット識別子として使用。`drs` と `install.sh` から `scutil` 依存を排除 | `darwinConfigurations` のキーは設定セットの識別子であり、OS のホスト名と一致させる必然性はない（nix-darwin 公式テンプレートも `"simple"` という任意名を使用）。OS のホスト名に依存すると仕事 Mac 展開時に制約になる |
| 5-7 | `networking.localHostName = hostname;` を追加       | 削除。OS のホスト名を nix-darwin で管理しない                                                            | 仕事 Mac で OS のホスト名を変えたくないケースに対応するため                                                                                                                                                         |
| 5-8 | nixd.lua で `scutil --get LocalHostName` を使用     | キー名を直書きに変更                                                                                     | OS のホスト名への依存を排除                                                                                                                                                                                         |

---

## 実装時に要確認事項

| 項目                              | 確認方法                                            | 影響                                                                                              |
| --------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Nixインストーラー URL             | `curl -I https://artifacts.nixos.org/nix-installer` | 無効なら `https://nixos.org/nix/install` に変更                                                   |
| stateVersion                      | ✅ `"25.11"` 確認済み                               | `release-25.11` が最新安定版。`modules/misc/version.nix` の enum で有効値確認済み                 |
| terminal-notifier                 | ✅ nixpkgs存在確認済み (v2.0.0)                     | overlay不要                                                                                       |
| moralerspace                      | ✅ nixpkgs存在確認済み (v2.0.0)                     | overlay不要                                                                                       |
| moralerspace-hw                   | ✅ nixpkgs存在確認済み                              | 別パッケージとして存在                                                                            |
| plemoljp-hs                       | ✅ nixpkgs存在確認済み                              | 別パッケージとして存在                                                                            |
| google-cloud-sdk (aarch64-darwin) | `gcloud version` で動作確認                         | M1で既知issue (#135045)。問題あればcaskにフォールバック                                           |
| gomi                              | ✅ nixpkgs存在確認済み (v1.6.2)                     | overlay不要                                                                                       |
| zabrze                            | ❌ nixpkgs不在確認済み                              | overlay必要                                                                                       |
| poppler                           | ✅ `poppler-utils` を使用                           | `poppler` はライブラリのみ(`utils=false`)。Yaziが必要な `pdftoppm` は `poppler-utils` に含まれる  |
| mac-app-util必要性                | stateVersionでSpotlight動作テスト                   | copyAppsで十分なら不要                                                                            |
| libpqバイナリ                     | `which pg_dump`                                     | psql等含むか確認                                                                                  |
| ~~scutil --get LocalHostName~~    | ~~各マシンで実行~~                                  | ~~flake.nixのエントリ名と一致させる~~（廃止: OS ホスト名に依存しない設計に変更。正誤表 5-7 参照） |

---

## 移行対象パッケージ一覧

### nixpkgsに存在（フェーズ1で移行）

| カテゴリ           | Homebrew名                                    | nixpkgs名                                        | OS         |
| ------------------ | --------------------------------------------- | ------------------------------------------------ | ---------- |
| base               | git, neovim, tmux                             | git, neovim, tmux                                | 共通       |
| shell              | ripgrep, bat, eza, fd, gomi, zoxide           | ripgrep, bat, eza, fd, gomi, zoxide              | 共通       |
| views              | starship, git-delta, gitmux                   | starship, delta, gitmux                          | 共通       |
| tui                | lazygit, lazydocker, yazi                     | lazygit, lazydocker, yazi                        | 共通       |
| cli                | fzf, awscli, gh, ghq, jq, pgcli               | fzf, awscli2, gh, ghq, jq, pgcli                 | 共通       |
| cli (caskから移行) | google-cloud-sdk, session-manager-plugin      | google-cloud-sdk, ssm-session-manager-plugin     | 共通       |
| dev                | hadolint, shellcheck, luarocks                | hadolint, shellcheck, luarocks                   | 共通       |
| yazi deps          | ffmpeg, poppler, imagemagick, resvg, sevenzip | ffmpeg, poppler-utils, imagemagick, resvg, \_7zz | 共通       |
| managers           | mise, sheldon, tenv                           | mise, sheldon, tenv                              | 共通       |
| notification       | terminal-notifier                             | terminal-notifier                                | **darwin** |
| ime                | macism                                        | macism                                           | **darwin** |
| db                 | libpq, sqldiff                                | libpq, sqlite, sqldiff                           | 共通       |
| editor             | claude-code                                   | claude-code                                      | 共通       |

### overlay経由（フェーズ2で移行）

| パッケージ | ビルド方式       | リスク |
| ---------- | ---------------- | ------ |
| zabrze     | buildRustPackage | 低     |

> **Note**: gomiはnixpkgs-unstableに存在（v1.6.2）するため、フェーズ1で `home.packages` に直接追加。

### Brewfile修正（Nix移行時に削除）

```diff
- tap "daipeihust/tap"
- tap "ryooooooga/tap"
- tap "laishulu/homebrew"
- brew "im-select"
- brew "rg"
- brew "fd"               # 重複
- cask "font-cica"        # MoralerspaceⅡに統一
- cask "google-cloud-sdk" # nixpkgsに移行（CLIツール）
- cask "session-manager-plugin" # nixpkgsに移行（CLIツール）
```

---

## ロールバック手順

### フェーズ1-2（cleanup="none"の間）

```bash
# Homebrewパッケージは残存しているので即座に復旧可能
# 1. path.zshからNixパスを削除
# 2. brew bundle install --file config/homebrew/Brewfile
```

### フェーズ3（cleanup="uninstall"後）

```bash
# uninstall実行前に `brew bundle dump` でバックアップ推奨
# uninstall後は `brew bundle install` で再インストール可能
```

---

## 学習ガイド

実装前に以下を読んでおくと、この計画で何をやっているか理解できる。優先度順。

### Step 1: Nixの概念を掴む

- [Zero to Nix](https://zero-to-nix.com/) — Determinate Systems製の入門ガイド（非公式だが質が高い）。ストア、derivation、flakeの概念がわかる
- [Homebrewユーザーのための Nix入門](https://zenn.dev/iota/articles/nix-intro-for-homebrew-users) — 日本語。今回やることの背景を掴める

### Step 2: 実例から逆引き

- [ryoppippi/dotfiles](https://github.com/ryoppippi/dotfiles) — 本計画の参考構成。flake.nix + nix-darwin + home-manager の実装がそのまま読める

### Step 3: 必要に応じてリファレンス参照

- [NixOS Wiki - Flakes](https://wiki.nixos.org/wiki/Flakes) — inputs/outputs/flake.lockの構造
- [Home Manager Manual](https://nix-community.github.io/home-manager/) — 特に「3. Using Home Manager」と `xdg.configFile`、`home.file`、`home.packages` のリファレンス
- [nix-darwin README](https://github.com/nix-darwin/nix-darwin) — セットアップ手順と基本構造
- [nix-darwin options search](https://searchix.alanpearce.eu/options/darwin/) — `homebrew.*`、`fonts.*`、`nix.gc.*` 等の設定リファレンス

### Step 4: より深く理解したくなったら

- [Nix Pills](https://nixos.org/guides/nix-pills/) — 1〜10章あたりまでで十分。Nixの内部動作の理解が深まる

---

## 参考資料

- [NixOS/nix-installer](https://github.com/NixOS/nix-installer) - NixOS公式インストーラー
- [nix-darwin](https://github.com/nix-darwin/nix-darwin) - macOS向けNix設定管理
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) - Homebrew宣言的管理
- [nix-darwin homebrew module](https://github.com/nix-darwin/nix-darwin/blob/master/modules/homebrew.nix)
- [ryoppippi/dotfiles](https://github.com/ryoppippi/dotfiles) - 参考構成
- [ryoppippi/claude-code-overlay](https://github.com/ryoppippi/claude-code-overlay) - Claude Code Nix overlay（最新追従が必要な場合の代替）
- [mkOutOfStoreSymlink 解説](https://jeancharles.quillet.org/posts/2023-02-07-The-home-manager-function-that-changes-everything.html) - mutable symlink の仕組み
- [Nix/Determinate/Lix比較](https://zenn.dev/trifolium/articles/da11a428c53f65)
- [2026年にnixを始める方法](https://zenn.dev/koba_e964/articles/32a7e0c345affe)
- [Homebrewユーザーのための Nix入門](https://zenn.dev/iota/articles/nix-intro-for-homebrew-users)

---

## Nixエコシステム検証ルール

### nixpkgsパッケージ検証

nixpkgsのパッケージ名・存在確認を行う際は、**必ず一次ソース（nixpkgsリポジトリのソースコード）を直接確認すること**。

#### 確認すべきファイル

| 確認対象                | ファイルパス                                                 |
| ----------------------- | ------------------------------------------------------------ |
| トップレベル属性の定義  | `pkgs/top-level/all-packages.nix`                            |
| by-name方式のパッケージ | `pkgs/by-name/<prefix>/<name>/package.nix`                   |
| 個別パッケージの定義    | 各パッケージディレクトリ内の `default.nix` や `tools.nix` 等 |

### nix-darwin / home-manager オプション検証

オプションの型・有効値を確認する際は、**デフォルト値ではなく型定義 (`type = ...`) を確認すること**。

| 確認対象               | 確認すべきファイル                                                               |
| ---------------------- | -------------------------------------------------------------------------------- |
| nix-darwinオプション   | 該当モジュールの `mkOption { type = ...; }` 定義                                 |
| home-managerオプション | 該当モジュールの `mkOption { type = ...; }` 定義                                 |
| launchd型              | `modules/launchd/types.nix`（`types.either` 等の複合型に注意）                   |
| stateVersion有効値     | **使用するブランチの** `modules/misc/version.nix`（masterではなくrelease-XX.XX） |

#### 注意: デフォルト値から型を推測しない

`default = [{...}]` がリスト形式でも、型が `types.either A (listOf A)` なら単一値も受け付ける。
必ず `type = ...` の定義まで辿ること。

### 信頼できないソース

以下はインデックスの遅延・表記揺れがあり、正確性が保証されない:

- MyNixOS (mynixos.com)
- search.nixos.org
- LLMの学習データに基づく回答

### 過去の誤検証事例

| 対象              | 誤った指摘                                      | 実際（ソースコード確認結果）                                                                                                                                                                                                                       |
| ----------------- | ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `poppler-utils`   | 「`poppler_utils`（アンダースコア）が正しい」   | `all-packages.nix` に `poppler-utils = poppler.override { suffix = "utils"; utils = true; };` と定義。ハイフンが正しい                                                                                                                             |
| `sqldiff`         | 「nixpkgsに独立パッケージとして存在しない」     | `all-packages.nix` で `inherit (callPackage ../development/libraries/sqlite/tools.nix {}) sqldiff;` として公開。`sqlite/tools.nix` に独立derivationとして定義                                                                                      |
| `nix.gc.interval` | 「型がリストなので `[{...}]` で囲む必要がある」 | 型は `types.either CalendarIntervalEntry (uniqueList (nonEmptyListOf CalendarIntervalEntry))`。単一attrsetでもリストでも受け付ける。デフォルト値が `[{...}]` であることから型をリスト必須と誤推測した。実際はコミュニティでも単一attrset形式が主流 |

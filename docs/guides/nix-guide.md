# Nix パーソナル入門ガイド

このドキュメントは、自分自身のための Nix リファレンスガイドである。
このリポジトリの Nix 環境を理解し、自信を持ってメンテナンスできるようになることを目的とする。

前提: Nix がインストール済みで、`drs`（`darwin-rebuild switch`）が正常に動作する状態。

---

## 1. Nix の基礎概念

### 1.1 Nix の三面性

「Nix」は 3 つの異なるものを指す:

| 名前 | 説明 |
|---|---|
| **Nix パッケージマネージャー** | Homebrew のような CLI ツール。パッケージのインストール・管理を行う |
| **Nix 言語** | パッケージやシステム設定を記述するための純粋関数型言語 |
| **NixOS** | Nix で OS 全体を宣言的に管理する Linux ディストリビューション |

このリポジトリでは **パッケージマネージャー** と **Nix 言語** を使っている。NixOS は使っていない（macOS なので代わりに nix-darwin を使う）。

### 1.2 Nix Store

すべての Nix パッケージは `/nix/store/` に格納される:

```
/nix/store/abc123...-ripgrep-14.1.1/
/nix/store/def456...-bat-0.24.0/
```

**コンテンツアドレス方式**: ハッシュ部分（`abc123...`）はパッケージのソースコード、依存関係、ビルドオプションなど **すべての入力** から計算される。同じ入力なら必ず同じハッシュになるため、異なるマシンでも完全に同じ環境を再現できる。

Homebrew が `/opt/homebrew/bin/ripgrep` のように 1 箇所に上書きインストールするのに対し、Nix はバージョンごとに別のパスに格納する。だから複数バージョンの共存や、壊れたときのロールバックが可能になる。

```bash
# Nix Store の中身を確認
ls /nix/store/ | head -20

# 特定パッケージの Store パスを確認
nix path-info nixpkgs#ripgrep
```

### 1.3 Derivation（ビルドの設計図）

Derivation は「何を、どうやってビルドするか」を記述した設計図である。

このリポジトリの `nix/overlays/zabrze.nix` が具体例:

```nix
# nix/overlays/zabrze.nix
rustPlatform.buildRustPackage rec {
  pname = "zabrze";          # パッケージ名
  version = "0.7.3";         # バージョン
  src = fetchFromGitHub {    # ソースコードの取得元
    owner = "Ryooooooga";
    repo = "zabrze";
    rev = "v${version}";
    hash = "sha256-OmwU7/...";  # ソースのハッシュ（改ざん検知）
  };
  cargoHash = "sha256-9UZS...";  # Rust 依存関係のハッシュ
}
```

`buildRustPackage` は Rust 用の derivation ヘルパー。他にも `buildGoModule`（Go）、`buildPythonPackage`（Python）、汎用の `stdenv.mkDerivation` などがある。

Nix はこの設計図を受け取り、隔離されたサンドボックス内でビルドを実行し、結果を `/nix/store/<hash>-zabrze-0.7.3/` に格納する。

### 1.4 Profile と Generation

Nix は環境の状態を **Generation**（世代）として管理する。`drs` を実行するたびに新しい世代が作られ、過去の世代にいつでもロールバックできる。

```bash
# 現在のシステム世代を確認
darwin-rebuild --list-generations

# 1 つ前の世代に戻す
darwin-rebuild switch --rollback
```

---

## 2. Nix 言語の基本

Nix 言語は JSON に関数を足したようなものだと思えばよい。このリポジトリのコードを読むのに必要な構文を解説する。

### 2.1 Attribute Set（属性セット）

Nix の基本データ構造。JSON のオブジェクトに相当する:

```nix
{
  name = "zabrze";
  version = "0.7.3";
}
```

**注意**: 各エントリの末尾は `,` ではなく `;`（セミコロン）。

### 2.2 `let...in`

ローカル変数を定義する。`flake.nix` の冒頭がこのパターン:

```nix
# flake.nix
let
  mkDarwinConfig = { username, system ? "aarch64-darwin" }:
    # ...
in {
  darwinConfigurations = {
    "<hostname>" = mkDarwinConfig { username = "<username>"; };
  };
}
```

`let` と `in` の間で変数を定義し、`in` の後のスコープで使う。

### 2.3 `with`

属性セットの中身をスコープに展開する。`nix/home/default.nix` で使っている:

```nix
# nix/home/default.nix
home.packages = with pkgs; [
  ripgrep
  bat
  eza
];
```

`with pkgs;` がなければ `pkgs.ripgrep`、`pkgs.bat` と書く必要がある。

**注意**: `with` はトップレベル（ファイル全体）で使わないこと。どの変数がどこから来たのか分からなくなり、デバッグが困難になる。`home.packages` のようなリストの中だけで使うのがベストプラクティス。

### 2.4 `inherit`

現在のスコープから同名の変数を引き継ぐ糖衣構文:

```nix
# これは...
{ inherit username hostname; }
# これと同じ
{ username = username; hostname = hostname; }
```

`flake.nix` の `specialArgs = { inherit username hostname; };` がこのパターン。

### 2.5 関数

Nix の関数は `引数: 本体` の形式。このリポジトリでは属性セットを引数に取るパターンが頻出する:

```nix
# nix/home/default.nix
{ pkgs, lib, username, ... }:
{
  # ...
}
```

- `{ pkgs, lib, username, ... }:` は「`pkgs`、`lib`、`username` を含む属性セットを受け取る関数」
- `...` は「他の属性も受け取るが無視する」
- この引数は Nix のモジュールシステムが自動で渡してくれる

**`specialArgs` との関係**: `flake.nix` で `extraSpecialArgs = { inherit username dotfilesPath; };` と書くと、`username` と `dotfilesPath` が各モジュールの関数引数として利用可能になる。

### 2.6 `//`（マージ演算子）

2 つの属性セットを結合する。右側が優先:

```nix
# nix/home/symlinks.nix
xdg.configFile = {
  "nvim".source = mkLink "config/nvim";
  "ghostty".source = mkLink "config/ghostty";
  # ...
} // lib.optionalAttrs pkgs.stdenv.isDarwin {
  "karabiner".source = mkLink "config/karabiner";
};
```

共通の設定に macOS 限定の設定をマージしている。`lib.optionalAttrs` は条件が `false` のとき空の属性セット `{}` を返すので、Linux では karabiner が含まれない。

### 2.7 遅延評価

Nix は**遅延評価**（lazy evaluation）を行う。値は実際に必要になるまで計算されない。

```nix
let
  x = builtins.throw "この文はエラーになる";
  y = 42;
in y  # x は使われないのでエラーにならない。結果は 42
```

これにより、大量のパッケージ定義を含む nixpkgs 全体を import しても、実際に使うパッケージだけが評価・ビルドされる。

### 2.8 避けるべきパターン

| パターン | 理由 | 代替 |
|---|---|---|
| `rec { ... }` | 無限再帰を引き起こしやすい | `let...in` |
| ファイル全体を `with pkgs;` で囲む | 名前の出所が不明になる | リストの中だけで使う |
| `<nixpkgs>` | 環境変数 `NIX_PATH` に依存し再現性がない | Flakes の inputs で固定 |
| 裸の URL `https://...` | Nix 言語の旧構文。非推奨 | 文字列 `"https://..."` |

---

## 3. Flakes — このリポジトリのエントリーポイント

### 3.1 Flakes とは

Flakes は Nix プロジェクトの標準的な構造。2 つのファイルで構成される:

| ファイル | 役割 | 例え |
|---|---|---|
| `flake.nix` | 依存関係と出力を定義 | `package.json` |
| `flake.lock` | 依存のバージョンを固定 | `package-lock.json` |

**重要**: Flakes は **git で追跡されているファイルのみ** を認識する。新しい `.nix` ファイルを作ったら、`darwin-rebuild switch` の前に必ず `git add` すること。

### 3.2 inputs — 依存関係

```nix
# flake.nix
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
```

| input | 役割 |
|---|---|
| `nixpkgs` | パッケージの巨大なリポジトリ（10 万以上のパッケージ） |
| `nix-darwin` | macOS のシステム設定を宣言的に管理するフレームワーク |
| `home-manager` | ユーザーのホームディレクトリを宣言的に管理 |
| `nix-homebrew` | Homebrew 自体の宣言的管理（cask 用） |

### 3.3 `follows` — バージョン統一

```nix
nix-darwin = {
  url = "github:nix-darwin/nix-darwin";
  inputs.nixpkgs.follows = "nixpkgs";  # <- これ
};
```

nix-darwin も内部で nixpkgs を使っている。`follows = "nixpkgs"` は「nix-darwin が使う nixpkgs を、このリポジトリの nixpkgs と同じバージョンにする」という意味。これがないと、nix-darwin が独自のバージョンの nixpkgs を持ち込み、ビルド時間とストア容量が増える。

### 3.4 outputs — 何を提供するか

```nix
# flake.nix
outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew }:
  let
    # ...
    mkDarwinConfig = { username, system ? "aarch64-darwin" }:
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username; };
        modules = [
          # ... 設定モジュール群
        ];
      };
  in {
    darwinConfigurations = {
      "<hostname>" = mkDarwinConfig { username = "<username>"; };
    };
  };
```

- `outputs` 関数は inputs を受け取り、設定を返す
- `mkDarwinConfig` はヘルパー関数。複数の Mac で同じ構成を使い回せる
- `system ? "aarch64-darwin"` はデフォルト引数（Apple Silicon）
- 新しい Mac を追加するときは `darwinConfigurations` にエントリを追加するだけ

### 3.5 modules リスト — 設定の合成

```nix
modules = [
  { nixpkgs.overlays = sharedOverlays; ... }   # インライン設定
  ./nix/hosts/darwin-shared.nix                  # ファイルから読み込み
  nix-homebrew.darwinModules.nix-homebrew        # 外部モジュール
  home-manager.darwinModules.home-manager         # 外部モジュール
  { home-manager = { ... }; }                    # インライン設定
];
```

Nix のモジュールシステムは、これらの設定を **自動的に深くマージ** する。複数のファイルで `home.packages` を定義しても衝突せず、すべてのパッケージが結合される。

### 3.6 flake.lock の管理

```bash
# 特定の input だけ更新（推奨）
nix flake update nixpkgs
nix flake update home-manager

# 全 input を一括更新（問題が起きたとき切り分けが難しい）
nix flake update

# 更新後は適用して動作確認
drs
```

`flake.lock` は必ず git にコミットすること。これが再現性の要。

---

## 4. nix-darwin — macOS のシステム設定

### 4.1 役割

nix-darwin は macOS を NixOS のように宣言的に管理するフレームワーク。`darwin-rebuild switch` を実行すると、`.nix` ファイルに書いた状態にシステムを同期する。

このリポジトリでは `nix/hosts/darwin-shared.nix` がメインの設定ファイル。

### 4.2 設定の解説

```nix
# nix/hosts/darwin-shared.nix
{ pkgs, username, ... }:
{
  # (A) Flakes を有効化
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # (B) ガベージコレクション: 毎週日曜 AM3:00 に 30 日以上古いパッケージを自動削除
  nix.gc = {
    automatic = true;
    interval = { Weekday = 7; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };

  # (C) Homebrew cask の宣言的管理
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;     # drs 時に brew update しない（速度優先）
      cleanup = "uninstall";  # casks リストにないものは削除
      upgrade = false;        # drs 時にバージョンアップしない
    };
    casks = [
      "raycast"
      "ghostty"
      # ...
    ];
  };

  # (D) nix-homebrew（Homebrew 自体を Nix で管理）
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
  };

  # (E) nix-darwin のデフォルト EDITOR=nano を上書き
  environment.variables.EDITOR = "vim";

  # (F) macOS 必須設定
  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";

  # (G) フォントを Nix 経由でインストール
  fonts.packages = with pkgs; [
    hackgen-font
    hackgen-nf-font
    plemoljp
    plemoljp-nf
    plemoljp-hs
    moralerspace
    moralerspace-hw
  ];

  # (H) 変更禁止！マイグレーション基準点
  system.stateVersion = 6;
}
```

### 4.3 `stateVersion` は変更禁止

`system.stateVersion` は「この設定が最初に作られたときの nix-darwin バージョン」を示す。nix-darwin はこの値を見て、古い設定からの移行処理を判断する。

**バージョンアップではない。更新してはいけない。** `nix flake update` で nix-darwin 自体は更新される。`stateVersion` はあくまで移行の基準点。

### 4.4 余談: nix-darwin の権限と適用範囲

#### なぜ `sudo` が必要なのか

`darwin-rebuild` はシステム全体の設定（`/etc/shells`, `/etc/nix/nix.conf`, LaunchDaemons など）を書き換える。書き込み先が `/nix/var/nix/profiles/system`（root 所有）なので `sudo` が必須になる。

```bash
# これは Permission denied になる
darwin-rebuild switch --flake .#MyMac
darwin-rebuild --list-generations

# sudo が必要
sudo darwin-rebuild switch --flake .#MyMac
sudo darwin-rebuild --list-generations
```

一方、Home Manager はユーザーのホームディレクトリ（`~/.nix-profile`, `~/.config/`）だけを操作するので `sudo` は不要。

#### Homebrew との比較

Homebrew は `/opt/homebrew/` がユーザー所有で `sudo` なしで動作する。nix-darwin はシステム全体に影響するためリスクが大きいように見えるが、世代管理によるロールバックがあるため、壊れたときの復旧はむしろ Nix の方が強い。

```bash
# 直前の世代に即座に戻せる
sudo darwin-rebuild switch --rollback
```

#### 会社の PC で使う場合

会社の Mac が MDM（Jamf など）で管理されている場合、`/etc/` 配下のファイルを MDM と nix-darwin が互いに上書きし合い、競合する可能性がある。

安全に行くなら **Home Manager 単体** で運用すればユーザースコープに収まるため、MDM との干渉を避けられる。

#### 環境別のおすすめ構成

| 環境 | 構成 | sudo | 備考 |
|---|---|---|---|
| 個人 Mac | nix-darwin + Home Manager | 必要 | このリポジトリの現在の構成 |
| 会社 Mac | Home Manager 単体 | 不要 | MDM との競合を回避 |
| Linux (NixOS) | NixOS + Home Manager | 必要 | OS 全体を Nix で管理 |
| Linux (Ubuntu 等) | Home Manager 単体 | 不要 | 既存ディストロに載せる |

このリポジトリは `nix/hosts/`（マシン全体）と `nix/home/`（ユーザースコープ）が分離されているので、会社 PC では `home-manager` 部分だけを使う運用に切り替えやすい。

---

## 5. Home Manager — ユーザー環境の宣言的管理

### 5.1 flake.nix との接続

```nix
# flake.nix
home-manager.darwinModules.home-manager
{
  home-manager = {
    useGlobalPkgs = true;       # nix-darwin と同じ nixpkgs を使う
    useUserPackages = true;     # パッケージをユーザーの PATH に配置
    users.${username} = import ./nix/home;  # home/default.nix を読み込む
    extraSpecialArgs = { inherit username dotfilesPath; };
  };
}
```

- `useGlobalPkgs = true`: Home Manager が独自に nixpkgs を import しない。ビルド時間とストア容量を節約
- `useUserPackages = true`: パッケージを `/etc/profiles/per-user/<username>/bin` に配置
- `import ./nix/home`: `nix/home/default.nix` を読み込む（ディレクトリを import すると `default.nix` が選ばれる）

### 5.2 パッケージ管理

```nix
# nix/home/default.nix
home.packages = with pkgs; [
  # base
  git
  neovim
  tmux

  # shell tools
  ripgrep
  bat
  eza
  # ...
];
```

**パッケージの追加手順**:

```bash
# 1. パッケージを検索
nix search nixpkgs ripgrep

# 2. nix/home/default.nix の home.packages にパッケージ名を追加

# 3. 適用
drs
```

**パッケージ名の確認**: [search.nixos.org](https://search.nixos.org/packages) で検索するか、`nix search nixpkgs <name>` を使う。ただし検索サイトはインデックスの遅延があるため、確実に調べるには [nixpkgs リポジトリ](https://github.com/NixOS/nixpkgs)のソースコードを直接確認する。

### 5.3 programs モジュール

一部のパッケージは `programs.<name>` でオプション付きの設定ができる:

```nix
# nix/home/shell.nix
{ ... }:
{
  programs.direnv = {
    enable = true;                    # direnv をインストール + 設定
    nix-direnv.enable = true;         # nix-direnv も有効化
    enableZshIntegration = false;     # zsh hook を自動登録しない
  };
}
```

`enableZshIntegration = false` の理由: Home Manager の zsh 統合は `programs.zsh.enable = true` が前提だが、このリポジトリでは zsh を Sheldon で管理しているため、hook は `config/zsh/lazy/direnv.zsh` で手動登録している。

### 5.4 条件分岐

macOS 専用パッケージの管理方法:

```nix
# nix/home/darwin.nix
{ pkgs, lib, ... }:
{
  home.packages = lib.mkIf pkgs.stdenv.isDarwin (with pkgs; [
    terminal-notifier
    macism
  ]);
}
```

- `lib.mkIf`: Nix モジュールシステムの条件分岐。`false` のときこの属性自体が無効になる
- `lib.optionalAttrs`: 通常の属性セット用の条件分岐（`symlinks.nix` で使用）

**使い分け**:
- モジュールオプション（`home.packages` など）→ `lib.mkIf`
- 普通の属性セット → `lib.optionalAttrs`

### 5.5 シンボリックリンク管理

```nix
# nix/home/symlinks.nix
{ config, lib, pkgs, dotfilesPath, ... }:
let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
in {
  xdg.configFile = {
    "nvim".source = mkLink "config/nvim";
    # ...
  };

  home.file = {
    ".claude/CLAUDE.md".source = mkLink "config/claude/CLAUDE.md";
    ".zshenv".source = mkLink "config/zsh/.zshenv";
    # ...
  };
}
```

**なぜ `mkOutOfStoreSymlink` を使うのか**:

通常の `source = ./config/nvim` だと、ファイルが Nix Store にコピーされ **read-only** になる。設定ファイルを編集するたびに `drs` を実行しなければ反映されない。

`mkOutOfStoreSymlink` は Nix Store を経由せず、直接シンボリックリンクを作る:

```
~/.config/nvim -> ~/Projects/dotfiles/config/nvim
```

これにより設定ファイルの編集が **即座に** 反映される。

**`xdg.configFile` vs `home.file`**:

| 属性 | リンク先 | 用途 |
|---|---|---|
| `xdg.configFile` | `~/.config/<name>` | XDG 準拠のアプリ |
| `home.file` | `~/<name>` | XDG 非対応のアプリ（Claude CLI、`.zshenv`） |

**`~/.claude/` を個別リンクにする理由**: Claude CLI は `~/.claude/` にランタイムファイル（history, sessions, cache 等）を書き込む。ディレクトリごとリンクすると、これらのファイルがリポジトリ内に生成されて汚れる。だから管理対象のファイルだけを個別にリンクする。

### 5.6 `home.stateVersion` は変更禁止

```nix
# nix/home/default.nix
home.stateVersion = "25.11";
```

`system.stateVersion` と同様、Home Manager のマイグレーション基準点。変更しないこと。

---

## 6. Overlays — nixpkgs の拡張

### 6.1 Overlay とは

nixpkgs に含まれないパッケージを追加したり、既存パッケージを修正するための仕組み。

```nix
# nix/overlays/default.nix
final: prev: {
  zabrze = prev.callPackage ./zabrze.nix { };
}
```

- `prev`: overlay 適用前の nixpkgs（元のパッケージを参照するときに使う）
- `final`: overlay 適用後の nixpkgs（他の overlay で追加されたパッケージを参照するときに使う）
- `prev.callPackage`: zabrze.nix を呼び出し、必要な引数（`lib`、`rustPlatform` 等）を自動で渡す

### 6.2 カスタムパッケージの作り方

```nix
# nix/overlays/zabrze.nix
{ lib, rustPlatform, fetchFromGitHub }:
rustPlatform.buildRustPackage rec {
  pname = "zabrze";
  version = "0.7.3";
  src = fetchFromGitHub {
    owner = "Ryooooooga";
    repo = "zabrze";
    rev = "v${version}";
    hash = "sha256-OmwU7/SQqEAzZo7/Eix3yc+VLEU6+/NIiALvpU3PlKA=";
  };
  cargoHash = "sha256-9UZSOXTWvX9jPE0crGb/hUpemuVhEGgyzs+HL3QwIgg=";
  meta = with lib; {
    description = "Zsh abbreviation expansion plugin";
    homepage = "https://github.com/Ryooooooga/zabrze";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
```

- `rec`: この属性セット内で自分自身を参照可能にする（`version` を `rev` で使うため）。overlay の `final`/`prev` とは別の話で、ここでは安全に使える
- `hash`: ソースコードの SHA-256 ハッシュ。改ざん検知と再現性のため
- `cargoHash`: `Cargo.lock` から計算される依存関係のハッシュ

**バージョン更新の手順**:

```bash
# 1. zabrze.nix の version を変更
# 2. hash と cargoHash を空文字列 "" に変更
# 3. ビルドを試みる（ハッシュミスマッチでエラーになる）
nix build .#zabrze
# 4. エラーメッセージに表示される正しいハッシュを hash にコピー
# 5. もう一度ビルド（cargoHash でもエラーになる）
# 6. 正しい cargoHash をコピー
# 7. 再ビルドして成功を確認
```

### 6.3 一時的なパッチ（overrideAttrs）

```nix
# flake.nix の sharedOverlays 内
# TODO: nixpkgs-unstable に direnv 修正 (PR #502769) が到達したら削除
(final: prev: {
  direnv = prev.direnv.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace GNUmakefile --replace-fail " -linkmode=external" ""
    '';
  });
})
```

`overrideAttrs` は既存パッケージの derivation の一部だけを変更する。ここでは nixpkgs の direnv にバグがあるため、ビルド時のリンクオプションを修正している。

**重要**: `TODO` コメントで一時的であることを明示し、上流の修正がチャネルに到達したら削除する。

### 6.4 Unfree パッケージの許可

```nix
# flake.nix
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
  "claude-code"
];
```

nixpkgs はデフォルトでオープンソースライセンスのパッケージのみ許可する。`claude-code` のような非フリーパッケージを使うには、明示的に許可リストに追加する必要がある。

---

## 7. Shell 統合 — Nix と zsh の橋渡し

### 7.1 nix-daemon.sh

```zsh
# config/zsh/eager/path.zsh
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
```

通常、Nix の環境変数は `/etc/zshrc` 経由で設定される。しかし `.zshenv` で `GLOBAL_RCS=off` を設定しているため `/etc/zshrc` が読み込まれない。そのため `nix-daemon.sh` を明示的に source して `NIX_SSL_CERT_FILE`、`NIX_PROFILES` などの環境変数を設定する。

### 7.2 PATH の優先順位

```zsh
# config/zsh/eager/path.zsh
path=(
    "$HOME/.local/bin"(N-/)
    "/etc/profiles/per-user/$USER/bin"(N-/)    # <- Nix (Home Manager)
    "/run/current-system/sw/bin"(N-/)          # <- Nix (nix-darwin)
    "${GHOSTTY_BIN_DIR}"(N-/)
    "/opt/homebrew/bin"(N-/)                   # <- Homebrew
    # ...
)
```

Nix のパスが Homebrew より前にあるため、同じツールが両方にある場合は Nix 版が優先される。

- `/etc/profiles/per-user/$USER/bin`: Home Manager でインストールしたパッケージ
- `/run/current-system/sw/bin`: nix-darwin でインストールしたパッケージ

### 7.3 便利エイリアス

```zsh
# config/zsh/lazy/nix.zsh
alias drs='sudo darwin-rebuild switch --flake ~/Projects/dotfiles'
alias nfu="nix flake update"
alias ngc="nix-collect-garbage -d"
```

| エイリアス | 用途 |
|---|---|
| `drs` | 設定を適用（darwin-rebuild switch） |
| `nfu` | flake の依存を全更新 |
| `ngc` | ガベージコレクション（古い世代を全削除） |
| `nd` | `nix develop`（開発シェルに入る） |
| `nf` | `nix flake`（flake 操作） |

### 7.4 direnv フック

```zsh
# config/zsh/lazy/direnv.zsh
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi
```

Home Manager の `enableZshIntegration = false` にしているため、手動で hook を登録している。Sheldon の `zsh-defer` で遅延ロードされるので、シェルの起動速度に影響しない。

### 7.5 devShell — プロジェクトローカルの開発環境

#### direnv とは

direnv はディレクトリごとに環境変数を自動で切り替えるシェル拡張ツール。`cd` するとそのディレクトリの `.envrc` を読み込み、抜けると元に戻す。

```
~/Projects/dotfiles/  → nixfmt, statix が PATH に
~/Projects/webapp/    → node, pnpm が PATH に
~/                    → 素の環境
```

元々は `DATABASE_URL` や `AWS_PROFILE` などの環境変数をプロジェクトごとに切り替えるためのツールで、Nix とは独立して存在する。nix-direnv プラグインが `use flake` コマンドを追加したことで、Nix の devShell と組み合わせて「ディレクトリごとに開発ツールを切り替える」用途でも使われるようになった。

| ファイル | 役割 |
|---|---|
| `.envrc` | direnv の設定ファイル（コミットする） |
| `.direnv/` | 環境のキャッシュ（`.gitignore` で除外する） |

#### パッケージのインストール方式の比較

Nix 環境では、ツールのインストール先が 3 つある:

| 方式 | スコープ | 用途 | Node.js で例えると |
|---|---|---|---|
| `home.packages` | 全プロジェクト共通 | git, ripgrep 等の汎用ツール | `npm install -g` |
| `devShell` | プロジェクト単位 | そのリポジトリの開発ツール | `npm install --save-dev` |
| Mason | Neovim 内のみ | LSP サーバー等 | エディタ拡張 |

#### devShell の仕組み

`flake.nix` の `devShells` に「このプロジェクトで使う開発ツール」を宣言する:

```nix
# flake.nix
devShells."aarch64-darwin".default = pkgs.mkShell {
  packages = with pkgs; [
    nixfmt       # フォーマッター
    statix       # リンター
    deadnix      # デッドコード検出
  ];
};
```

有効化の方法は 2 つ:

```bash
# 方法1: 手動で開発シェルに入る
nix develop

# 方法2: direnv で自動化（推奨）
# .envrc に "use flake" と書いておけば、cd するだけで有効化される
```

このリポジトリでは方法 2 を採用している。`home.packages` と違い、ツールの実体はプロジェクトディレクトリ内には生成されない（`/nix/store/` にある）。PATH を通すだけなので `node_modules/` のようなディスク消費はない。

#### .envrc と direnv allow

`.envrc` は任意のシェルコマンドを実行できるファイルである。そのため direnv は**明示的に許可されるまで実行しない**セキュリティ機構を持つ:

```bash
# 未許可の状態で cd すると
$ cd ~/Projects/dotfiles
direnv: error .envrc is blocked. Run `direnv allow` to approve its content

# 許可すると、以降は cd するだけで自動実行される
$ direnv allow
```

`direnv allow` を実行すると、`.envrc` の内容の SHA256 ハッシュが `~/.local/share/direnv/allow/` に記録される。以降は cd のたびにハッシュを比較し、**内容が 1 文字でも変わると再度ブロックされる**:

| 状態 | cd したとき |
|---|---|
| 未許可 | ブロック |
| 許可済み + `.envrc` 未変更 | 自動実行 |
| 許可済み + `.envrc` 変更あり | ハッシュ不一致でブロック |

これにより、git pull で `.envrc` が書き換えられていた場合に中身を確認してから許可するかどうかを判断できる。

---

## 8. 日常メンテナンス

### 8.1 パッケージの追加・削除

```bash
# 1. パッケージを検索
nix search nixpkgs <name>

# 2. nix/home/default.nix の home.packages に追加（または削除）
#    macOS 専用なら nix/home/darwin.nix

# 3. 適用
drs
```

### 8.2 Homebrew cask の追加・削除

```bash
# 1. nix/hosts/darwin-shared.nix の casks リストを編集

# 2. 適用（cleanup = "uninstall" なので、リストから消せば自動削除される）
drs
```

### 8.3 設定ファイルの追加

```bash
# 1. config/ にファイルを配置

# 2. nix/home/symlinks.nix にリンクを追加:
#    XDG 準拠 → xdg.configFile に追加
#    それ以外 → home.file に追加

# 3. 適用
drs
```

### 8.4 依存の更新

```bash
# 個別更新（推奨。問題の切り分けが容易）
nix flake update nixpkgs
nix flake update home-manager
nix flake update nix-darwin

# 全更新
nix flake update

# 更新後は必ず適用して動作確認
drs

# 問題があればロールバック
darwin-rebuild switch --rollback
```

**更新の頻度**: 月に 1 回程度が目安。頻繁すぎると不安定、稀すぎると一度の変更が大きくなる。

### 8.5 ガベージコレクション

Nix Store は過去の世代やビルドキャッシュで肥大化する。

```bash
# 自動 GC: darwin-shared.nix で設定済み
# -> 毎週日曜 AM3:00 に 30 日以上古いパッケージを削除

# 手動 GC（全世代を削除してからガベージコレクション）
ngc   # = nix-collect-garbage -d

# ストア容量の確認
du -sh /nix/store
```

### 8.6 Overlay の更新

zabrze のバージョンを上げる場合:

```bash
# 1. nix/overlays/zabrze.nix の version を変更
# 2. hash = ""; と cargoHash = ""; に変更
# 3. ビルド → エラーから正しいハッシュを取得 → 貼り付け → 再ビルド
nix build .#zabrze
# 4. 適用
drs
```

### 8.7 devShell のツール追加・削除

```bash
# 1. flake.nix の devShells.packages に追加（または削除）

# 2. direnv が自動で再読み込みする（.envrc の変更がない場合）
#    手動で再読み込みする場合:
direnv reload
```

---

## 9. トラブルシューティング

### 9.1 よくあるエラー

| エラー | 原因 | 対処 |
|---|---|---|
| `error: getting status of '/nix/store/.../flake.nix': No such file or directory` | 新しい `.nix` ファイルを `git add` していない | `git add <file>` |
| `error: attribute '...' not found` | パッケージ名が間違っている | `nix search nixpkgs <name>` で確認 |
| `hash mismatch` | hash または cargoHash が古い | エラーメッセージの正しいハッシュに置換 |
| `error: infinite recursion encountered` | `imports` で `pkgs` を参照する条件分岐など | `lib.mkIf` で本体側で条件分岐する |
| `error: unfree package '...' is not allowed` | unfree パッケージの許可漏れ | `allowUnfreePredicate` のリストに追加 |

### 9.2 デバッグツール

```bash
# Nix 式をインタラクティブに試す
nix repl
# repl 内で flake をロード
nix-repl> :lf .
# パッケージの属性を調べる
nix-repl> pkgs.ripgrep.meta

# ビルドログを確認
nix log nixpkgs#<package>

# 依存関係を追跡（なぜこのパッケージが入っているのか）
nix why-depends nixpkgs#neovim nixpkgs#lua

# エラーの詳細表示
darwin-rebuild switch --flake .#<hostname> --show-trace

# 特定パッケージだけビルドして確認
nix build .#zabrze
```

### 9.3 ロールバック

```bash
# 1 つ前の世代に戻す
darwin-rebuild switch --rollback

# 世代一覧を確認
darwin-rebuild --list-generations

# Home Manager の世代一覧
home-manager generations
```

---

## 10. やってはいけないこと

| 禁止事項 | 理由 |
|---|---|
| `stateVersion` を変更する | マイグレーション基準点であり、バージョンアップの意味ではない |
| `nix flake update` を頻繁に全更新する | 問題の切り分けが困難になる。個別更新を推奨 |
| すべてを一気に Nix 化する | 段階的に移行し、各ステップで動作確認する |
| `rec { ... }` を多用する | 無限再帰のリスク。`let...in` で代替 |
| トップレベルの `with` を使う | 変数の出所が不明になりデバッグ困難 |
| Flake 内で `builtins.fetchTarball` 等を使う | impure（再現性がない）。inputs で依存を管理する |
| Overlay を無秩序に増やす | 適用順序が重要。必要最小限に |
| `homebrew.onActivation.cleanup = "zap"` にする | cask の設定データまで削除されて危険。`"uninstall"` を使う |

---

## 11. 参考リンク

### 公式ドキュメント

- [Nix Reference Manual](https://nix.dev/manual/nix/) — Nix コマンドと言語のリファレンス
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/) — パッケージ定義のリファレンス
- [NixOS Wiki - Flakes](https://wiki.nixos.org/wiki/Flakes) — Flakes の構造と使い方
- [Home Manager Manual](https://nix-community.github.io/home-manager/) — Home Manager のオプション一覧
- [nix-darwin](https://github.com/nix-darwin/nix-darwin) — macOS 向け Nix 設定管理
- [nix-darwin options search](https://searchix.alanpearce.eu/options/darwin/) — nix-darwin オプション検索

### 入門リソース

- [Zero to Nix](https://zero-to-nix.com/) — Nix の概念を図解で学べる入門ガイド
- [Nix Pills](https://nixos.org/guides/nix-pills/) — Nix の内部動作を深く理解する（1〜10 章推奨）
- [nix.dev](https://nix.dev/) — 公式チュートリアル・ベストプラクティス集

### 日本語リソース

- [Homebrew ユーザーのための Nix 入門](https://zenn.dev/iota/articles/nix-intro-for-homebrew-users) — Homebrew との比較で Nix を理解
- [2026 年に nix を始める方法](https://zenn.dev/koba_e964/articles/32a7e0c345affe) — 最新のセットアップ手順

### パッケージ検索

- [search.nixos.org](https://search.nixos.org/packages) — nixpkgs パッケージ検索（インデックスに遅延あり）
- [nixpkgs リポジトリ](https://github.com/NixOS/nixpkgs) — 一次ソース（正確な情報が必要なときはこちら）

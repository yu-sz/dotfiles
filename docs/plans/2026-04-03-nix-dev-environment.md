# Nix 開発環境改善 実装計画

## 概要

Nix 開発環境を4施策で改善する:

- **Stylix 削除**: 実質無効化されている Stylix を完全除去し、flake.lock をスリム化
- **flake-parts 移行**: 手書き `forEachSystem` をコミュニティ標準の `perSystem` に置き換え
- **nix.settings 強化**: `warn-dirty` 抑制 + ストア最適化
- **nh 導入**: switch 時の差分表示、ビルドログ整形、世代数ベース GC

**出典**:

- [ADR: flake-parts 移行](../adr/2026-04-03-flake-parts-migration.md)
- [ADR: nh 導入](../adr/2026-04-03-nh-adoption.md)
- [ADR: Stylix テーマ統一 + programs 移行](../adr/2026-04-01-stylix-programs-migration.md) — Stylix 見送りの経緯

---

## 決定事項

| 項目           | 決定                                                       | 備考                                                                                           |
| -------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Stylix         | **完全削除**                                               | `autoEnable = false` + targets 空 → 機能的影響ゼロ                                             |
| flake-parts    | **`perSystem` + `flake` 構造に移行**                       | Stylix 削除と同時に flake.nix を整理                                                           |
| nix.settings   | **`warn-dirty = false` + `nix.optimise.automatic = true`** | `auto-optimise-store` も利用可能だが定期バッチの方がビルド時オーバーヘッドなし                 |
| nh             | **`programs.nh` モジュールで導入**                         | HM モジュールで導入。`NH_DARWIN_FLAKE` は `unsetopt GLOBAL_RCS` により未設定のため明示パス指定 |
| nix.gc         | **維持**（元の計画から変更）                               | `nh clean all` でシステム + ユーザー両方を GC                                                  |
| drs エイリアス | **中身を nh に置き換え、残す**                             | `nh darwin switch ~/Projects/dotfiles`（明示パス指定）                                         |
| ngc エイリアス | **中身を nh clean all に置き換え**                         | `--keep 5 --nogcroots`（世代数ベース管理 + devShell GC root 保護）                             |

---

## 設計: flake.nix 移行後の構造

```nix
{
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
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.git-hooks.flakeModule ];

      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { config, pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;

          pre-commit.settings.hooks = {
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            shellcheck = {
              enable = true;
              types_or = [ "sh" "bash" ];
              excludes = [ "^\\.envrc$" ];
              args = [ "-x" "-e" "SC1091" ];
            };
          };

          devShells.default = pkgs.mkShell {
            inherit (config.pre-commit) shellHook;
            packages = config.pre-commit.settings.enabledPackages ++ [ pkgs.just ];
          };
        };

      flake =
        let
          sharedOverlays = [ (import ./nix/overlays) ];

          mkDarwinConfig =
            { username, system ? "aarch64-darwin" }:
            inputs.nix-darwin.lib.darwinSystem {
              inherit system;
              specialArgs = { inherit username; };
              modules = [
                {
                  nixpkgs.overlays = sharedOverlays;
                  nixpkgs.config.allowUnfreePredicate =
                    pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude-code" ];
                }
                ./nix/hosts/darwin-shared.nix
                inputs.nix-homebrew.darwinModules.nix-homebrew
                inputs.home-manager.darwinModules.home-manager
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "hm-backup";
                    users.${username} = import ./nix/home;
                    extraSpecialArgs = { inherit username; };
                  };
                }
              ];
            };
        in
        {
          darwinConfigurations = {
            "suta-ro" = mkDarwinConfig { username = "suta-ro"; };
          };

          # Linux (standalone home-manager) — 将来用
          # homeConfigurations."<user>@ubuntu" = home-manager.lib.homeManagerConfiguration {
          #   pkgs = import inputs.nixpkgs { system = "x86_64-linux"; overlays = sharedOverlays; };
          #   modules = [ ./nix/home ];
          #   extraSpecialArgs = { username = "<user>"; };
          # };
        };
    };
}
```

---

## 設計: nix.settings

```nix
# nix/hosts/darwin-shared.nix
nix.settings = {
  experimental-features = [
    "nix-command"
    "flakes"
  ];
  warn-dirty = false;
};

nix.optimise.automatic = true;
```

---

## 設計: programs.nh（home-manager モジュール）

```nix
# nix/home/programs/nh.nix
{ username, ... }:
{
  programs.nh = {
    enable = true;
    darwinFlake = "/Users/${username}/Projects/dotfiles";
  };
}
```

`programs.nh.enable` により nh パッケージが自動インストールされ、`NH_DARWIN_FLAKE` 環境変数が `hm-session-vars.sh` 経由で設定される。
ただし `.zshenv` の `unsetopt GLOBAL_RCS` により `hm-session-vars.sh` が読み込まれないため、エイリアス・Justfile では明示的にパスを指定する。

> **注意**: `programs.nh.clean.enable` は使用しない。
> `programs.nh.clean` は systemd ユーザーサービスで実装されており、macOS (launchd) には非対応のため。
> GC は手動コマンド (`just clean` / `ngc` alias) + 既存の `nix.gc` で運用する。
>
> nix-darwin 用 `programs.nh` の PR（[nix-darwin#942](https://github.com/nix-darwin/nix-darwin/pull/942)）は未マージだが、
> 本計画では home-manager の `programs.nh` を使用するため影響なし。
>
> `nh darwin switch` は activation 時に内部で sudo を呼ぶため、明示的な `sudo` は不要。

---

## 設計: zsh エイリアス

```zsh
# config/zsh/lazy/nix.zsh
if command -v nix &>/dev/null; then
  alias nd="nix develop"
  alias ndc="nix develop --command"
  alias nf="nix flake"
  alias nfu="nix flake update"
  alias ngc="nh clean all --keep 5 --nogcroots"

  if [[ "$OSTYPE" == darwin* ]]; then
    # unsetopt GLOBAL_RCS により hm-session-vars.sh が読み込まれず NH_DARWIN_FLAKE が未設定のため、明示的にパスを指定
    alias drs='nh darwin switch ~/Projects/dotfiles'
  fi
fi
```

---

## 設計: Justfile

```just
default:
    @just --list

# nh darwin switch を実行
switch:
    nh darwin switch .

# flake.lock を更新して switch
update:
    nix flake update
    just switch

# Nix ファイルをフォーマット
fmt:
    nix fmt

# フォーマットチェック（差分があればエラー）
fmt-check:
    nix fmt -- --ci

# フォーマットチェック + statix
lint: fmt-check
    statix check .
    deadnix --no-lambda-pattern-names .

# nix flake check を実行
check:
    nix flake check

# Nix store のガベージコレクション（直近5世代を保持）
clean:
    nh clean all --keep 5 --nogcroots
```

---

## 実装手順

### Phase 1: Stylix 削除 + flake-parts 移行

flake.nix を大きく変更するため同時に実施。

- [x] 1-1: `flake.nix` から `stylix` input を削除
- [x] 1-2: `flake.nix` の outputs 引数から `stylix` を削除
- [x] 1-3: `flake.nix` の modules から `stylix.darwinModules.stylix` を削除
- [x] 1-4: `nix/hosts/darwin-shared.nix` から `stylix = { ... }` ブロックを削除
- [x] 1-5: `nix/home/stylix.nix` を削除
- [x] 1-6: `nix/home/default.nix` の imports から `./stylix.nix` を削除
- [x] 1-7: `flake.nix` に `flake-parts` input を追加
- [x] 1-8: `flake.nix` の outputs を `flake-parts.lib.mkFlake` 構造に書き換え（設計セクション参照）
- [x] 1-9: `nix flake lock` で flake.lock を更新（Stylix 20 依存削除 + flake-parts 追加）
- [x] 1-10: `nix flake check` で検証
- [x] 1-11: `drs` で適用確認（base16 テーマファイルが REMOVED、-4.77 KiB）

### Phase 2: nix.settings 強化

- [x] 2-1: `nix/hosts/darwin-shared.nix` の `nix.settings` に `warn-dirty = false` を追加し、`nix.optimise.automatic = true` をトップレベルに追加
- [x] 2-2: `drs` で適用（nix-optimise launchd サービスが追加、+2.01 KiB）
- [x] 2-3: dirty tree で `nix flake check` を実行し、警告が出ないことを確認

### Phase 3: nh 導入

- [x] 3-1: `nix/home/programs/nh.nix` を新設（設計セクション参照。`clean.enable` は使わない）
- [x] 3-2: `nix/home/programs/default.nix` の imports に `./nh.nix` を追加
- [x] 3-3: `drs`（旧コマンド）で nh をインストール
- [x] 3-4: `Justfile` を nh ベースに更新（設計セクション参照）
- [x] 3-5: `config/zsh/lazy/nix.zsh` のエイリアスを nh ベースに更新（設計セクション参照）
- [x] 3-6: `CLAUDE.md` のコマンド説明を更新
- [x] 3-7: `drs`（nh darwin switch）で差分表示を確認
- [x] 3-8: `just clean` で世代数ベース GC を確認（2060 paths deleted, 2.1GiB freed。直近5世代を保持）

#### 予実差異

| 項目                 | 計画                         | 実際                                                 | 理由                                                                                                                       |
| -------------------- | ---------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `NH_DARWIN_FLAKE`    | パス指定不要                 | `drs` で明示パス指定が必要                           | `.zshenv` の `unsetopt GLOBAL_RCS` により `hm-session-vars.sh` が読み込まれず環境変数が未設定                              |
| `drs` エイリアス     | `nh darwin switch`           | `nh darwin switch ~/Projects/dotfiles`               | 上記の理由で明示パス指定に変更                                                                                             |
| `just switch`        | `nh darwin switch`           | `nh darwin switch .`                                 | Justfile は dotfiles 内で実行するため `.` で解決可能                                                                       |
| `ngc`                | `nh clean user --keep 5`     | `nh clean all --keep 5 --nogcroots`                  | ADR に従い `all` を採用。`--nogcroots` は nh がデフォルトで `.direnv` GC root を削除し devShell が壊れるため追加           |
| ブートストラップ手順 | 3-3 で Justfile → 3-4 で切替 | 先に Justfile/エイリアスを nh に変更してしまい手戻り | nh 未インストール状態で nh コマンドを参照する設定に変更してしまった。`drs`（旧コマンド）でブートストラップ後に切替が正しい |

---

## 変更対象ファイル一覧

| ファイル                        | Phase 1                      | Phase 2       | Phase 3          |
| ------------------------------- | ---------------------------- | ------------- | ---------------- |
| `flake.nix`                     | stylix 削除 + flake-parts 化 | -             | -                |
| `nix/hosts/darwin-shared.nix`   | stylix ブロック削除          | settings 追加 | -                |
| `nix/home/default.nix`          | import 削除                  | -             | -                |
| `nix/home/programs/nh.nix`      | -                            | -             | **新設**         |
| `nix/home/programs/default.nix` | -                            | -             | import 追加      |
| `nix/home/stylix.nix`           | ファイル削除                 | -             | -                |
| `Justfile`                      | -                            | -             | nh コマンド化    |
| `config/zsh/lazy/nix.zsh`       | -                            | -             | エイリアス更新   |
| `CLAUDE.md`                     | -                            | -             | コマンド説明更新 |

# Linux 対応 実装計画

## 概要

standalone home-manager による Linux 対応を追加する:

- **flake.nix**: `mkHomeConfig` ヘルパーと空の `homeConfigurations` を追加
- **nix/home/linux.nix**: Linux 専用設定（`targets.genericLinux`、フォント管理）
- **クロスプラットフォームIF**: Justfile ハイブリッド化 + zabrze abbr の OS 条件分岐

**出典**:

- [ADR: Linux 対応方式の選定](../adr/2026-04-11-linux-support-strategy.md)
- [ADR: ホスト名ベースのマルチマシン対応](../adr/2026-03-29-multi-machine-strategy.md)

---

## 決定事項

| 項目              | 決定                                                                       | 備考                                                                                |
| ----------------- | -------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Linux対応方式     | **standalone home-manager**                                                | NixOS不使用。ターゲットはUbuntu                                                     |
| flake属性キー     | **`"${username}@${hostname}"`**                                            | HM CLI自動解決に従う                                                                |
| mkHomeConfig IF   | **`{ username, system? }`**                                                | mkDarwinConfigと同一                                                                |
| allowUnfree       | **共通変数 `allowedUnfree` を `flake` スコープに定義し両ヘルパーから参照** | mkDarwinConfigとの重複防止。HM推奨パターン（Issues #2942, #2954）                   |
| genericLinux      | **`targets.genericLinux.enable = lib.mkDefault true`**                     | 非NixOS統合（XDG, Zsh fpath, systemd）                                              |
| フォント管理      | **`home.packages` + `fonts.fontconfig.enable`**                            | Darwin側はシステムレベル(`fonts.packages`)                                          |
| nh設定            | **`darwinFlake` → `flake` に統一**                                         | `hm-session-vars.sh`未ソースのため環境変数は効かないが、汎用的な`flake`で意図を明示 |
| Justfile構成      | **ハイブリッド（`switch` + `switch-darwin`/`switch-linux`）**              | justの`os()`関数でシェル不要                                                        |
| drs abbr          | **zabrze `if` フィールドでOS分岐**                                         | 同一トリガーで多態展開                                                              |
| ghostty           | **`command`のzshパスを動的解決 + `isDarwin`ガード**                        | `lib.getExe pkgs.zsh`で両OSで同じ振る舞い。`macos-*`は`optionalAttrs`でガード       |
| ghosttyパッケージ | **Linux: HM管理、macOS: 現行cask維持**                                     | Linux側は`package = null`を削除しHMに委任。macOS→HM統一は後続タスク                 |
| pkgs.zsh          | **共通パッケージに追加（両OS）**                                           | macOS副作用は軽微（PATH優先順位変更のみ、ログインシェル不変）。詳細は実現可能性参照 |
| ガードパターン    | **darwin.nix / linux.nix 両方モジュール全体`lib.mkIf`ラップに統一**        | HMコミュニティの一般的パターン。属性追加時の`mkIf`漏れリスクを排除                  |
| GUIアプリ管理     | **nixpkgs `home.packages`で統一管理**                                      | `targets.genericLinux.gpu`で自動的にGPU問題解決                                     |
| LinuxビルドCI     | **nix-lint.ymlに統合（Justfileハイブリッド経由）**                         | `ci@linux`エントリでdry-runビルド。別ワークフロー不要                               |

---

## 設計: mkHomeConfig

```nix
# flake.nix — mkDarwinConfig の直後に追加
mkHomeConfig =
  {
    username,
    system ? "x86_64-linux",
  }:
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = sharedOverlays;
      config.allowUnfreePredicate =
        pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) allowedUnfree;
    };
    modules = [ ./nix/home ];
    extraSpecialArgs = {
      inherit username;
      dotfilesRelPath = "Projects/dotfiles";
    };
  };
```

> **注**: standalone HM では `useGlobalPkgs` / `useUserPackages` オプションが存在しない。
> `pkgs` 引数の `config` は `lib.mkDefault pkgs.config` でモジュールシステムに引き継がれ、
> `overlays` は `inherit (pkgs) overlays` で直接代入される（`mkDefault` なし）。
> `config` はモジュール側で上書き可能だが、`overlays` を上書きすると衝突する点に留意
> （[HM `lib/default.nix`](https://github.com/nix-community/home-manager/blob/master/lib/default.nix)）。
> パッケージは `~/.nix-profile/` にインストールされる（Darwin 側は `/etc/profiles/per-user/$USER/`）。

## 設計: linux.nix

```nix
# nix/home/linux.nix
{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  targets.genericLinux.enable = lib.mkDefault true;

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    hackgen-font
    hackgen-nf-font
    plemoljp
    plemoljp-nf
    plemoljp-hs
    moralerspace
    moralerspace-hw
  ];
}
```

## 設計: nh.nix

```nix
# nix/home/programs/nh.nix
{ config, dotfilesRelPath, ... }:
{
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/${dotfilesRelPath}";
  };
}
```

> **注**: `programs.nh.flake` は `home.sessionVariables` 経由で `NH_FLAKE` を設定するが、
> `.zshenv` の `unsetopt GLOBAL_RCS` により `hm-session-vars.sh` がソースされないため、
> 実質的に `nh clean` 等の引数なしサブコマンドでのみ効く。
> `drs`（zabrze）と `just switch` は引数でフレークパスを渡しており、この環境変数に依存しない。
> nh 内部ではコンテキスト固有の変数（`NH_DARWIN_FLAKE` / `NH_HOME_FLAKE` / `NH_OS_FLAKE`）→
> `NH_FILE` → `NH_FLAKE` の順に解決される
> （[`installable.rs`](https://github.com/viperML/nh/blob/master/crates/nh-core/src/installable.rs)）。
> HM モジュール `programs/nh.nix` は `darwinFlake` → `NH_DARWIN_FLAKE`、
> `flake` → `NH_FLAKE` のマッピングのみ提供する。いずれも未ソースのため実質無効。
> 意図の明示のため汎用的な `flake` に統一する。
> なお、この変更により Darwin コンテキストでの nh 優先順位が
> `NH_DARWIN_FLAKE`（最優先）→ `NH_FLAKE`（フォールバック）に降格するが、
> 現環境では未ソースのため影響なし。将来 `hm-session-vars.sh` をソースする場合は留意。

## 設計: ghostty.nix

`command` の zsh パスを `lib.getExe pkgs.zsh` で動的解決し、macOS/Linux 両方で同じ振る舞い（zsh + tmux）を実現する。`macos-*` キーは `optionalAttrs isDarwin` でガード。前提として `pkgs.zsh` を共通パッケージに追加する。`package` は macOS では `null`（cask管理）を維持し、Linux では削除してHMに委任（デフォルト `pkgs.ghostty`）。`package` の OS 分岐は `lib.mkIf` で実現する。

```nix
# nix/home/programs/ghostty.nix
{ pkgs, lib, ... }:
let
  zshPath = lib.getExe pkgs.zsh;
in
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
    settings = {
      font-family = "\"Moralerspace Xenon HW\"";
      window-title-font-family = "\"Moralerspace Xenon HW\"";
      font-size = 18;
      font-thicken = false;
      theme = "tokyonight";
      background-opacity = 0.85;
      background-blur-radius = 20;
      unfocused-split-opacity = 0.7;
      cursor-opacity = 0.8;
      cursor-color = "#ffffff";
      cursor-style = "block";
      window-theme = "auto";
      window-padding-color = "background";
      window-padding-x = 2;
      window-padding-y = 2;
      window-padding-balance = true;
      window-step-resize = false;
      window-save-state = "always";
      window-inherit-working-directory = true;
      clipboard-read = "allow";
      clipboard-write = "allow";
      clipboard-trim-trailing-spaces = true;
      shell-integration = "detect";
      command = "${zshPath} -lic 'ghostty +boo; tmux attach || tmux new-session -s default'";
      keybind = [ "shift+enter=text:\\n" ];
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      macos-icon = "xray";
      macos-titlebar-style = "hidden";
    };
  };
}
```

## 設計: Justfile ハイブリッド

```just
# OS判定で switch-darwin / switch-linux を呼び分け
switch:
    just switch-{{ if os() == "macos" { "darwin" } else { "linux" } }}

# nh darwin switch を実行
switch-darwin:
    nh darwin switch .

# nh home switch を実行
switch-linux:
    nh home switch .

# CI 用チェック（Nix 評価 + lint + dry-run build）
ci:
    nix flake check
    just lint
    shellcheck -x -e SC1091 scripts/**/*.sh
    just ci-{{ if os() == "macos" { "darwin" } else { "linux" } }}

ci-darwin:
    nix build .#darwinConfigurations.yu-sz.system --dry-run

ci-linux:
    nix build .#homeConfigurations.ci@linux.activationPackage --dry-run
```

## 設計: zabrze OS 条件分岐

```toml
# config/zabrze/config.toml — 既存の drs スニペットを置き換え
[[snippets]]
name = "darwin rebuild switch"
trigger = "drs"
snippet = "nh darwin switch $DOTFILES_DIR"
if = '[[ "$OSTYPE" =~ darwin ]]'

[[snippets]]
name = "home-manager rebuild switch"
trigger = "drs"
snippet = "nh home switch $DOTFILES_DIR"
if = '[[ "$OSTYPE" =~ linux ]]'
```

## 設計: bootstrap.sh Linux ブロック

```bash
# scripts/bootstrap.sh — Darwin ブロック（L33-46）の直後に追加
if [[ "$(uname -s)" == "Linux" ]]; then
  HOSTNAME="$(hostname -s)"
  USERNAME="$(whoami)"
  if ! grep -q "\"${USERNAME}@${HOSTNAME}\"" "${DOTFILES_DIR}/flake.nix"; then
    info "Adding homeConfiguration for ${USERNAME}@${HOSTNAME}..."
    FLAKE="${DOTFILES_DIR}/flake.nix"
    TMP="$(mktemp)"
    sed "/homeConfigurations = {/a\\
\\        \"${USERNAME}@${HOSTNAME}\" = mkHomeConfig { username = \"${USERNAME}\"; };" \
      "${FLAKE}" > "${TMP}"
    if mv "${TMP}" "${FLAKE}"; then :; else rm -f "${TMP}"; fi
    git -C "${DOTFILES_DIR}" add flake.nix
  fi
fi
```

---

## 実装手順

### Phase 0: Linux ビルド CI

Phase 1 で `mkHomeConfig` + `homeConfigurations` を作成した直後に、CI で Linux HM 設定の実ビルドを検証できるようにする。nix-lint.yml は既に ubuntu-latest で `just ci` を実行しており、Justfile ハイブリッド化（Phase 2）で `ci-linux` が自動的に呼ばれるため、ワークフロー側の変更は不要。

- [x] 0-1: `flake.nix` の `homeConfigurations` に CI 用エントリを追加（Phase 1-5 に統合）

  ```nix
  homeConfigurations = {
    "ci@linux" = mkHomeConfig { username = "ci"; };
  };
  ```

- [x] 0-2: Justfile の `ci-linux` レシピを HM config の dry-run ビルドに設定（Phase 2-1 に統合）

  ```just
  ci-linux:
      nix build .#homeConfigurations.ci@linux.activationPackage --dry-run
  ```

- [x] 0-3: nix-lint.yml は `**/*.nix` トリガーで既にカバー済みのため変更不要であることを確認

> **注**: Phase 0 の実装は Phase 1・2 の該当ステップに組み込む形で実施する。独立した作業ステップではなく、検証観点の追加。

### Phase 1: コア（flake + HM モジュール）

- [x] 1-0: `flake.nix` の `flake` スコープに `allowedUnfree` 共通変数を定義し、`mkDarwinConfig` からも参照するようリファクタ
- [x] 1-1: `nix/home/darwin.nix` をモジュール全体 `lib.mkIf pkgs.stdenv.isDarwin` ラップにリファクタ（linux.nix とガードパターン統一）
- [x] 1-2: `nix/home/linux.nix` を新規作成（`targets.genericLinux` + フォント）
- [x] 1-3: `nix/home/default.nix` の imports に `./linux.nix` を追加
- [x] 1-4: `flake.nix` に `mkHomeConfig` ヘルパーを追加
- [x] 1-5: `flake.nix` の `homeConfigurations` コメントアウトを解除し、CI 用エントリ `"ci@linux"` を追加（Phase 0-1）
- [x] 1-6: `nix/home/programs/nh.nix` を `darwinFlake` → `flake` に変更
- [x] 1-7: 共通パッケージに `pkgs.zsh` を追加（macOS副作用: PATH上でNix版が優先されるがログインシェル不変、実影響なし）
- [x] 1-8: `git add nix/home/linux.nix` + `nix flake check`（dry-run build は x86_64-linux 環境が必要のため CI で検証）

### Phase 2: クロスプラットフォームIF

- [x] 2-1: `Justfile` の `switch`/`ci` をハイブリッド構成に変更
- [x] 2-2: `config/zabrze/config.toml` の `drs` を OS 条件分岐に変更
- [x] 2-3: `nix/home/programs/ghostty.nix` の `command` zshパス動的解決 + `optionalAttrs isDarwin` でmacOS固有設定ガード + `package` をOS分岐（macOS: `null`、Linux: HM管理）

### Phase 3: bootstrap スクリプト

- [x] 3-1: `scripts/bootstrap.sh` に Linux 用 homeConfiguration 自動注入ブロックを追加
- [x] 3-2: `nix flake check` で macOS リグレッションがないことを確認

---

## 予実差異

| Phase              | 差異                                                                                                                                                                                                            |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0                  | 計画では独立 Phase だったが実際は Phase 1・2 に統合して実施（計画通り）。追加で `nix-build-linux.yml` を新規作成し Linux 実ビルド CI を整備                                                                     |
| 1                  | 1-5: `mkHomeConfig` に `home.username` / `home.homeDirectory` の設定が必要だった（standalone HM は darwinModules と異なり自動設定されない）。1-8: dry-run build はローカル aarch64-darwin で実行不可、CI で検証 |
| 2                  | 予実差異なし                                                                                                                                                                                                    |
| 3                  | 3-2: `drs` の実行確認は `nix flake check` + `nh darwin switch` で代替                                                                                                                                           |
| 計画外             | zabrze overlay の `doCheck = false` 追加。テストが `env_clear()` で PATH を消した上で zsh を呼ぶため Linux sandbox で失敗する問題に対処                                                                         |
| 計画外             | Docker daemon は standalone HM で管理不可のため、`config/apt/packages.txt` + `scripts/apt-sync.sh` による apt 管理を導入（ADR に Addendum 追記）                                                                |
| チェックリスト漏れ | 決定事項「GUIアプリ管理: `home.packages` で統一管理」のうち wezterm, code-cursor を `linux.nix` に追加。実装済みだがチェックリストへの落とし込みが漏れていた                                                    |

---

## 実現可能性レビュー

| 懸念                                                             | 検証結果                                                                                                                                                                                                                                                                                         | 根拠                                                                                                                                        |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `targets.genericLinux.enable` は Darwin で評価エラーにならないか | **`enable = true` を Darwin で設定するとエラーになる**。`assertPlatform` は `config = lib.mkIf cfg.enable` の内側にあり、`enable` がデフォルト (`false`) なら Darwin でも安全。`linux.nix` を `lib.mkIf pkgs.stdenv.isLinux` でラップすることで `enable = true` が Darwin で発火しないようにする | HMソース [`modules/targets/generic-linux.nix`](https://github.com/nix-community/home-manager/blob/master/modules/targets/generic-linux.nix) |
| `fonts.fontconfig.enable` は Darwin で副作用があるか             | **軽微**。Darwin でも fontconfig 設定ファイルが生成される（エラーにはならない）。`isLinux` 全体ラップで回避                                                                                                                                                                                      | HMソース `modules/misc/fontconfig.nix`                                                                                                      |
| `programs.nh.flake` は `darwinFlake` と競合しないか              | **しない**。nh内部で`NH_DARWIN_FLAKE` → `NH_FILE` → `NH_FLAKE`の順に解決。`flake`のみ設定時は全サブコマンドのフォールバックとして利用                                                                                                                                                            | HMソース `modules/programs/nh.nix`、[nhソース `installable.rs`](https://github.com/viperML/nh)                                              |
| 空の `homeConfigurations = { }` は `nix flake check` を通るか    | **通る**。空 attrset は有効な Nix 式                                                                                                                                                                                                                                                             | Nix言語仕様                                                                                                                                 |
| zabrze の `if` フィールドで同一トリガー2件は動くか               | **動く**。定義順に `if/elif/else` チェーンとしてシェルコードに変換される。両方に `if` 条件を付けることで明示的に分岐させる                                                                                                                                                                       | zabrze ソース [`src/expand/mod.rs`](https://github.com/Ryooooooga/zabrze/blob/main/src/expand/mod.rs)                                       |
| ghostty の `command` は Linux で動作するか                       | **`/bin/zsh` ハードコードでは動作しない**。`command` 設定時はフォールバックなし（`ExecFailedInChild`）。`lib.getExe pkgs.zsh` で動的解決する                                                                                                                                                     | [Ghosttyソース `Exec.zig`](https://github.com/ghostty-org/ghostty) L752-757, `Config.zig` L1132-1162                                        |
| darwin.nix / linux.nix の全体 `lib.mkIf` ラップは安全か          | **安全**。Nix モジュールシステムは `lib.mkIf` が返す値を attrset としてマージ可能。HM コミュニティで一般的なパターン                                                                                                                                                                             | NixOS/nixpkgs モジュールシステム仕様                                                                                                        |

---

## 変更対象ファイル一覧

| ファイル                        | Phase 1                                     | Phase 2                                        | Phase 3       |
| ------------------------------- | ------------------------------------------- | ---------------------------------------------- | ------------- |
| `nix/home/darwin.nix`           | ガードパターン統一（全体mkIfラップ）        | -                                              | -             |
| `nix/home/linux.nix`            | **新規作成**                                | -                                              | -             |
| `nix/home/default.nix`          | imports追加                                 | -                                              | -             |
| `flake.nix`                     | mkHomeConfig + homeConfigurations(ci@linux) | -                                              | -             |
| `nix/home/programs/nh.nix`      | flake統一                                   | -                                              | -             |
| `nix/home/programs/ghostty.nix` | -                                           | zshパス動的解決 + isDarwinガード + package分岐 | -             |
| `nix/home/packages/` (共通)     | `pkgs.zsh` 追加                             | -                                              | -             |
| `Justfile`                      | -                                           | ハイブリッド化 + ci-linux実ビルド              | -             |
| `config/zabrze/config.toml`     | -                                           | OS条件分岐                                     | -             |
| `scripts/bootstrap.sh`          | -                                           | -                                              | Linux注入追加 |

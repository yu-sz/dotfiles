# Linux 対応方式の選定

Date: 2026-04-11
Status: Accepted

## Context

このdotfilesは現在macOS（nix-darwin + home-manager）のみ対応している。Ubuntu環境でも同じツールセット・設定を利用したい。

既存のコードベースは設計段階からLinux対応を見据えている:

- `nix/home/darwin.nix` が `lib.mkIf pkgs.stdenv.isDarwin` でガード済み
- `nix/home/symlinks.nix` がXDG Base Directory準拠
- `scripts/setup/linux.sh` が実装済み
- `flake.nix` に `homeConfigurations` のスキャフォールドがコメントアウトで存在

対応方式として3つの選択肢がある。

## Decision

### standalone home-manager を採用する

| 観点               | A. NixOS                       | B. standalone HM                    | C. 両対応           |
| ------------------ | ------------------------------ | ----------------------------------- | ------------------- |
| ディストロ非依存   | ❌ NixOS限定                   | **✅ Ubuntu/Fedora等どれでも**      | ✅                  |
| システム管理       | ✅ 宣言的                      | ❌ ディストロ側                     | ✅                  |
| 導入の容易さ       | ❌ OS入替が必要                | **✅ Nixインストールのみ**          | ⚠️                  |
| 既存設計との整合   | ⚠️ nixosConfigurations追加     | **✅ コメント解除+ヘルパー追加**    | ❌ 両方の設計が必要 |
| 変更量             | 大（hosts/nixos-shared.nix等） | **小（linux.nix + flake.nix修正）** | 大                  |
| nix/home/ の再利用 | ✅                             | **✅**                              | ✅                  |

**B. standalone home-manager を採用。** 根拠:

- 既存Plan（[Nix導入実装計画](../plans/2026-03-28-nix-implementation.md)）で「upstream Nix + standalone HM」方針を決定済み。今回これを正式にADR化
- ターゲットはUbuntu。NixOSへのOS入替は不要で、Nixインストールのみで導入できる
- `nix/home/` の既存モジュール群がそのまま再利用可能（[HMソース `lib/default.nix`](https://github.com/nix-community/home-manager/blob/master/lib/default.nix) で `homeManagerConfiguration` の `modules` に同じパスを渡せることを確認）
- `targets.genericLinux.enable` で非NixOS環境のXDG・Zsh fpath・systemd統合が得られる（[HMソース `modules/targets/generic-linux.nix`](https://github.com/nix-community/home-manager/blob/master/modules/targets/generic-linux.nix)）

### homeConfigurations のキー命名

home-manager CLIの自動解決ロジック（[HMソース `setFlakeAttribute()`](https://github.com/nix-community/home-manager/blob/master/home-manager/home-manager)）:

1. 初期値 `$USER`、次に `$USER@$(hostname -f)` → `$USER@$(hostname)` → `$USER@$(hostname -s)` の順にチェックし、マッチするたびに上書き（`break` なし）。最終的に最後にマッチしたキーが採用される
2. darwin-rebuildの `scutil --get LocalHostName` とは異なるルール

`"${username}@${hostname}"` 形式を採用し、`home-manager switch --flake .` で自動解決させる。

### mkHomeConfig のインターフェース

| 観点                     | hostname引数あり           | hostname引数なし                    |
| ------------------------ | -------------------------- | ----------------------------------- |
| mkDarwinConfigとの一貫性 | ❌ 不一致                  | **✅ 同じ `{ username, system? }`** |
| 関数内部での利用         | 未使用（キー名にのみ使用） | **不要な引数がない**                |
| 将来のホスト固有設定     | 引数が既にある             | 必要時に追加すればよい              |

hostname引数なし（`{ username, system? }`）を採用。

### クロスプラットフォームのコマンドインターフェース

Linux対応に伴い、`just switch` と `drs` abbr のコマンドインターフェースをOS間で統一する必要がある。

#### Justfile 構成

| 観点                   | A. 統一（OS分岐）  | B. 分離                                        | C. ハイブリッド               |
| ---------------------- | ------------------ | ---------------------------------------------- | ----------------------------- |
| `just switch` で動く   | ✅                 | ❌（`switch-darwin`/`switch-linux`を使い分け） | **✅**                        |
| `just --list` の明確さ | ❌ 中身が不透明    | **✅** 各レシピが明示的                        | **✅** OS別レシピも見える     |
| シェルスクリプト混入   | ❌ bash if文が必要 | **✅ なし**                                    | **✅ just `os()` 関数で不要** |
| レシピ数               | 1                  | 2                                              | 3                             |

**C. ハイブリッドを採用。** `just switch`（`os()`で自動判定）+ `switch-darwin`/`switch-linux`（個別呼び出し可能）。

#### abbr（zabrze）のOS多態化

| 観点               | A. OS別abbr（`drs`/`hrs`） | B. 同一abbr＋`if`条件分岐             |
| ------------------ | -------------------------- | ------------------------------------- |
| 覚えるコマンド数   | 2つ                        | **1つ（`drs`のみ）**                  |
| グローバルで使える | ✅                         | **✅**                                |
| zabrze機能の活用   | ❌                         | **✅ `if`フィールドでフォールバック** |

**B. 同一abbr＋`if`条件分岐を採用。** zabrzeの`if`フィールド（[README](https://github.com/Ryooooooga/zabrze)で`$OSTYPE`による条件分岐が公式サポート）で、同じ`drs`トリガーをDarwin/Linuxで異なるコマンドに展開する。

### GUIアプリの管理方式

非NixOS LinuxでのGUIアプリ管理には3つの選択肢がある。

| 観点            | A. apt（リスト+just） | B. nix-flatpak           | C. nixpkgs `home.packages`              |
| --------------- | --------------------- | ------------------------ | --------------------------------------- |
| 宣言的（追加）  | ✅                    | ✅                       | **✅**                                  |
| 宣言的（削除）  | ❌                    | ✅                       | **✅**                                  |
| GPU問題         | ✅ なし               | ✅ なし                  | **✅ `targets.genericLinux.gpu`で解決** |
| Nix統一管理     | ❌ Nix外              | △ flake input追加        | **✅ 完全にNix内**                      |
| 信頼性          | ✅ apt自体            | △ プレ1.0・メンテナー1人 | **✅ HM公式モジュール**                 |
| macOSとの対称性 | ❌ 仕組みが異なる     | △                        | **△ 方式は異なるが両方Nix**             |

**C. nixpkgs `home.packages` を採用。** 根拠:

- `targets.genericLinux.gpu`が[HM公式にマージ済み](https://github.com/nix-community/home-manager/pull/8057)（2025-11-09）。NixOSと同じ`/run/opengl-driver`方式でGPU問題を根本解決
- マージから5ヶ月間、モジュール本体のロジックバグ報告ゼロ。報告されたIssueは全て設定ミスか外部要因（SELinux, stale flake等）で解決済み
- `targets.genericLinux.enable = true`（linux.nixに設定済み）で自動有効化。追加設定不要
- GitHub上で`targets.genericLinux.enable`を使う公開リポジトリは約1,000件。GPUモジュール明示利用は約70件（5ヶ月で7%採用）
- CLIもGUIも`home.packages`で統一管理でき、aptやFlatpakの併用が不要
- nix-flatpakはプレ1.0・メンテナー1人（バスファクター問題）で、standalone HMでの[未解決issue](https://github.com/gmodena/nix-flatpak/issues/186)あり

## Consequences

- `nix/home/linux.nix`（新規）と `flake.nix` の修正で対応完了。既存Darwin環境への影響ゼロ
- CLIもGUIも`home.packages`で統一管理。apt/Flatpak等のNix外パッケージマネージャーが不要
- `just switch` と `drs` がOS非依存のインターフェースになり、Darwin/Linuxで同じコマンド体験を提供
- 具体的なLinuxマシンがなくても `nix flake check` で評価可能
- NixOSへの拡張が将来必要になった場合、`nixosConfigurations` の追加は独立して行える
- フォント管理がOS間で非対称（Darwin: システムレベル `fonts.packages`、Linux: ユーザーレベル `home.packages` + `fonts.fontconfig.enable`）
- GUIアプリ管理もOS間で非対称（Darwin: `homebrew.casks`、Linux: `home.packages`）だが、両方ともNix管理下
- `targets.genericLinux.gpu`は初回セットアップ時にsudo実行が必要（`sudo non-nixos-gpu-setup`）
- Justfileのレシピ数が増える（`switch` 1 → `switch`/`switch-darwin`/`switch-linux` 3、`ci` 同様）

## Addendum (2026-04-12): システムサービスを必要とするパッケージの apt 管理

Status: **Accepted** — GUI アプリの方針は変更なし、システムサービス管理の補足

### 経緯

Docker daemon のようにシステムサービス（systemd）が必要なパッケージは standalone home-manager の `home.packages` では管理できない。ADR 原文の「apt 不要」は GUI アプリ / CLI ツールに対しては正しいが、システムサービスを考慮していなかった。

### 変更した決定

| 項目                 | 元の決定                               | 変更後                                                                  |
| -------------------- | -------------------------------------- | ----------------------------------------------------------------------- |
| システムサービス管理 | （未考慮）                             | `config/apt/packages.txt` + `scripts/apt-sync.sh` で apt パッケージ管理 |
| drs 適用範囲         | HM switch のみ                         | apt-sync + HM switch（`switch-linux` で両方実行）                       |
| GUI/CLI ツール       | `home.packages` で統一管理（変更なし） | 変更なし                                                                |

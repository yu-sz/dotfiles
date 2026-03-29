# CI/CD 戦略

Date: 2026-03-30
Status: Accepted

## Context

CI がなく、flake の評価エラーや lint 違反を PR マージ前に検出できない。`flake.lock` の更新が手動で、依存の陳腐化リスクがある。

## Decision

**GitHub Actions で CI と週次 flake.lock 自動更新を導入する。**

### CI トリガー

`push` + `pull_request` で実行する。dotfiles は直 push が多いため、両方で CI を回す。ローカルの pre-commit hooks が第一防衛線、CI はセーフティネット。Nix 関連ファイル（`**.nix`, `flake.lock`, `Justfile`, `scripts/**`, CI ワークフロー）の変更時のみ実行し、不要な実行を抑制する。

### CI パイプライン

- `nix flake check` による flake 評価検証
- `nixfmt`（`nixfmt-tree` 経由）/ `statix` / `shellcheck` による lint
- `DeterminateSystems/flake-checker-action` による `flake.lock` 健全性チェック

### Nix インストーラの選定

**cachix/install-nix-action を採用する。**

| 観点 | cachix/install-nix-action | DeterminateSystems/nix-installer-action |
|------|--------------------------|----------------------------------------|
| インストールする Nix | **upstream Nix** | **Determinate Nix**（独自フォーク） |
| GitHub Stars | 666 | 230 |
| upstream Nix 対応 | ネイティブ | 2026-01-01 に廃止済み |
| テレメトリ | なし | デフォルト有効 |
| 速度 (Ubuntu) | ~5s | ~17s |

[ADR: Nix パッケージ管理](2026-03-28-nix-package-management.md) で upstream Nix を明示的に選択済み。DeterminateSystems 版は [2026-01-01 に upstream サポートを廃止](https://determinate.systems/blog/installer-dropping-upstream/)しており、選択不可。

NixOS/nixpkgs 公式リポジトリが cachix 版を使用。[nix.dev 公式 CI ガイド](https://nix.dev/guides/recipes/continuous-integration-github-actions.html)・[NixOS Discourse ベンチマーク](https://discourse.nixos.org/t/which-github-nix-installer-action-is-faster/25878) でも推奨。

### CI runner

**ubuntu-latest（Linux）を使用する。**

- `nix flake check` はデフォルトで実行中のシステムの出力のみ評価する（[Nix マニュアル](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake-check)）。darwin 出力は自動スキップされる
- `checks`, `devShells`, `formatter` は `forEachSystem` で `x86_64-linux` にも対応させることで、Linux runner 上で lint checks が動作する
- macOS runner は GitHub Actions で Linux の10倍コスト。個人 dotfiles にはオーバースペック

### 補助ツール

`DeterminateSystems/flake-checker-action` と `update-flake-lock` は Nix インストーラではなく、upstream Nix 環境で問題なく動作する。`update-flake-lock` は内部で `nix flake update` 相当を実行するだけであり、cachix/install-nix-action との[併用実績](https://github.com/DeterminateSystems/update-flake-lock/pull/62)もある。

### flake.lock 自動更新

- `DeterminateSystems/update-flake-lock@v28` で週次（毎週月曜 UTC）の自動更新 PR を作成
- `GITHUB_TOKEN` で作成した PR は CI をトリガーしない（GitHub の仕様）。初期段階では必須チェック未設定のため問題なし

## Consequences

- PR マージ前に flake の評価エラー・lint 違反を自動検出できる
- `flake.lock` が週次で自動更新され、依存の陳腐化を防止
- CI は Linux runner（コスト $0）で運用。darwin 固有のビルドエラーはローカルでのみ検出可能

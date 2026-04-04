# CI/CD 戦略

Date: 2026-03-30
Status: Accepted

## Context

CI がなく、flake の評価エラーや lint 違反を PR マージ前に検出できない。`flake.lock` の更新が手動で、依存の陳腐化リスクがある。

## Decision

**GitHub Actions で CI と週次 flake.lock 自動更新を導入する。**

### CI トリガー

- `push` イベントのみで実行（ブランチ制限なし）
- `pull_request` との重複なし。ローカル pre-commit hooks が第一防衛線、CI はセーフティネット
- paths フィルタで Nix 関連ファイル（`**.nix`, `flake.lock`, `Justfile`, `scripts/**`, CI ワークフロー）の変更時のみ実行

### CI パイプライン

- `nix flake check` による flake 評価検証
- `nixfmt`（`nixfmt-tree` 経由）/ `statix` / `shellcheck` による lint
- `DeterminateSystems/flake-checker-action` による `flake.lock` 健全性チェック

### Nix インストーラの選定

**cachix/install-nix-action を採用する。**

| 観点                 | cachix/install-nix-action | DeterminateSystems/nix-installer-action |
| -------------------- | ------------------------- | --------------------------------------- |
| インストールする Nix | **upstream Nix**          | **Determinate Nix**（独自フォーク）     |
| GitHub Stars         | 666                       | 230                                     |
| upstream Nix 対応    | ネイティブ                | 2026-01-01 に廃止済み                   |
| テレメトリ           | なし                      | デフォルト有効                          |
| 速度 (Ubuntu)        | ~5s                       | ~17s                                    |

- 前 ADR で [upstream Nix を選択済み](2026-03-28-nix-package-management.md)。DeterminateSystems は [upstream サポート廃止](https://determinate.systems/blog/installer-dropping-upstream/)
- NixOS 公式・[nix.dev ガイド](https://nix.dev/guides/recipes/continuous-integration-github-actions.html)・[Discourse ベンチマーク](https://discourse.nixos.org/t/which-github-nix-installer-action-is-faster/25878)で推奨

### CI runner

**ubuntu-latest（Linux）を使用する。** macOS runner はコスト10倍、個人向けにオーバースペック。

- `checks`, `devShells`, `formatter` を `x86_64-linux` 対応にし、Linux 上で lint 実行

### 補助ツール

`DeterminateSystems/flake-checker-action` と `update-flake-lock` は Nix インストーラではなく、upstream Nix 環境で動作する。`update-flake-lock` は `nix flake update` 相当を実行するだけであり、cachix/install-nix-action との[併用実績](https://github.com/DeterminateSystems/update-flake-lock/pull/62)もある。

### flake.lock 自動更新

- `DeterminateSystems/update-flake-lock@v28` で週次（毎週月曜 UTC）の自動更新 PR を作成
- `GITHUB_TOKEN` で作成した PR は CI をトリガーしない（GitHub の仕様）。初期段階では必須チェック未設定のため問題なし

## Consequences

- PR マージ前に flake の評価エラー・lint 違反を自動検出できる
- `flake.lock` が週次で自動更新され、依存の陳腐化を防止
- CI は Linux runner（コスト $0）で運用。darwin 固有のビルドエラーはローカルでのみ検出可能

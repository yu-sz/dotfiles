# シークレットスキャン導入

Date: 2026-04-04
Status: Accepted

## Context

dotfiles リポジトリには `.gitignore` の `*.local` / `local.*` パターンによるシークレット除外があるが、スキャンツールは未導入。ファイル名パターンに依存するだけでは、命名規則から外れた認証情報の誤コミットを防げない。

既存の pre-commit hook 基盤（[cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix)）に乗る形で、コミット前にシークレットを検出する仕組みを追加する。

## Decision

### gitleaks を pre-commit hook として導入する

| 観点               | gitleaks                                                                | ripsecrets                           | detect-secrets               |
| ------------------ | ----------------------------------------------------------------------- | ------------------------------------ | ---------------------------- |
| 検出パターン       | **150+ ルール**（AWS, GCP, GitHub, Slack 等）                           | 汎用的な高エントロピー検出           | 中程度（プラグイン拡張式）   |
| 偽陽性制御         | **`.gitleaks.toml` で paths/commits/regex 単位の allowlist**            | `.secretsignore` ファイル            | `.secrets.baseline` ファイル |
| git-hooks.nix 統合 | カスタム hook 定義が必要                                                | **`ripsecrets.enable = true` の1行** | カスタム hook 定義が必要     |
| nixpkgs 収録       | **あり**（`pkgs.gitleaks`）                                             | **あり**（`pkgs.ripsecrets`）        | なし（Python 依存）          |
| CI 対応            | **[gitleaks-action](https://github.com/gitleaks/gitleaks-action) あり** | なし                                 | あり                         |
| 言語               | Go                                                                      | Rust                                 | Python                       |

- gitleaks は [GitHub Stars ~18k](https://github.com/gitleaks/gitleaks) でシークレットスキャナのデファクトスタンダード
- ripsecrets は導入が最も簡単だが、検出パターンが汎用的で AWS キー等の具体的なサービス固有パターンがない
- detect-secrets は Python 依存で Nix 環境との統合コストが高い
- 個人 dotfiles でも `.env` ファイルや API トークンの貼り付けミスは起こり得るため、パターン数の多い gitleaks が適切

### スコープは pre-commit のみ

- 個人リポでローカルからのみコミットするため、pre-commit で十分
- CI（gitleaks-action）は必要になった時点で別途追加可能

## Consequences

- コミット前にシークレットが自動検出され、誤って認証情報が Git 履歴に入ることを防止できる
- `nix develop` で devShell に入ると自動で hook が有効化される。追加のセットアップ不要
- カスタム hook 定義のため `ripsecrets.enable = true` よりは設定量が多いが、偽陽性の制御性で上回る
- 必要に応じて CI に [gitleaks-action](https://github.com/gitleaks/gitleaks-action) を追加し、2層防御に拡張可能

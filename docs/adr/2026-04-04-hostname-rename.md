# macOS ホスト名を suta-ro に変更

Date: 2026-04-04
Status: Accepted

## Context

macOS のデフォルトホスト名は「名前の MacBook Pro」形式で冗長でダサい。

また、`flake.nix` の `darwinConfigurations` キーや CI の dry-run ターゲットとして表示される。

## Decision

### ホスト名を GitHub ユーザー名 `suta-ro` に変更する

| 観点       | デフォルトのまま     | 任意の名前（onyx 等） | **GitHub ユーザー名 `suta-ro`** |
| ---------- | -------------------- | --------------------- | ------------------------------- |
| 見栄え     | デフォルト命名が冗長 | 良い                  | **良い**                        |
| 一貫性     | なし                 | なし                  | **GitHub アカウントと統一**     |
| 覚えやすさ | 長い                 | 覚える必要あり        | **既に使い慣れている**          |
| 個人情報   | 本名が露出           | **匿名**              | **匿名**                        |

- ホスト名ベース設計（[ADR: マルチマシン戦略](./2026-03-29-multi-machine-strategy.md)）を維持。`nh darwin switch`、`darwin-rebuild switch --flake .`、`nixd.lua` の自動解決がそのまま動く
- `darwinConfigurations` のキーと `username` が同じ `suta-ro` になるが、nix-darwin の動作に影響なし。仕事 Mac 追加時は仕事側のホスト名がキーになるため衝突しない
- macOS の 3 種のホスト名（ComputerName / LocalHostName / HostName）をすべて変更。AirDrop・iCloud・Homebrew への影響なし

## Consequences

- `flake.nix` と CI の参照先が `suta-ro` に統一され、public リポジトリでの見栄えが改善される
- ネットワーク共有の Bonjour 名が `suta-ro.local` に変わる
- git history にはコード内の旧ホスト名文字列が残るが、変更コミット以降は新名に統一されるため実害なし

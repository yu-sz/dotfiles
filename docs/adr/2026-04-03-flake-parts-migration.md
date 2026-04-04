# flake-parts 移行

Date: 2026-04-03
Status: Accepted

## Context

現在の `flake.nix` は手書きの `forEachSystem`（`nixpkgs.lib.genAttrs`）で per-system outputs を定義している。Nix コミュニティでは [flake-parts](https://github.com/hercules-ci/flake-parts) が事実上の標準になりつつあり、Stylix 削除で `flake.nix` を大きく変更するこのタイミングで移行する。

## Decision

### flake-parts を採用し、outputs 構造を移行する

| 観点                        | 手書き genAttrs（現状） | flake-parts                    | flake-utils         |
| --------------------------- | ----------------------- | ------------------------------ | ------------------- |
| コミュニティ採用            | 少数                    | **事実上の標準**               | メンテ停滞気味      |
| per-system ボイラープレート | 毎回 `forEachSystem`    | **`perSystem` で自動**         | `eachDefaultSystem` |
| モジュールシステム          | なし                    | **Nix module system**          | なし                |
| 将来の拡張性                | 手動で output 追加      | **flake-parts モジュール追加** | 手動                |
| 学習コスト                  | 低（Nix 基本構文）      | 中（module system）            | 低                  |
| GitHub Stars                | N/A                     | ~1,000                         | ~1,200（停滞）      |

- hercules-ci メンテ。[NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system) でも紹介。Stylix が内部で使用していた実績あり
- flake-utils は以前のデファクトだが、新規採用は減少傾向
- [git-hooks.nix](https://github.com/cachix/git-hooks.nix) はスタンドアロンで統合可能（[ADR: 開発ワークフロー](./2026-03-30-dev-workflow.md)参照）

### 移行後の構造

```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
  systems = [ "aarch64-darwin" "x86_64-linux" ];

  perSystem = { system, ... }: {
    # devShells, formatter, checks
  };

  flake = {
    # darwinConfigurations（システム固有ではないので flake ブロック）
  };
};
```

- `perSystem`: `devShells`, `formatter`, `checks` を配置。`forEachSystem` が不要になる
- `flake`: `darwinConfigurations` を配置。`mkDarwinConfig` ヘルパーはそのまま維持
- `sharedOverlays` は `flake` ブロックの `let` に配置

## Consequences

- `forEachSystem` と `supportedSystems` 定義が不要になり、ボイラープレート約 15 行削減
- 新しい output（packages, apps 等）を `perSystem` に追加するだけで全システムに展開
- flake-parts モジュール（treefmt-nix 等）を後から追加しやすい
- `perSystem` / `flake` の 2 分割を理解する学習コストが発生

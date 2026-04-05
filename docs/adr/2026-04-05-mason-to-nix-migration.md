# Mason 全廃と Nix 一本化

Date: 2026-04-05
Status: Accepted

## Context

Mason と Nix で同じツールを二重管理している（shellcheck が両方にある等）。Mason のグローバル prettier が biome プロジェクトでフォールバック適用される問題も発生。加えて Claude Code CLI の LSP プラグインは PATH からバイナリを `spawn()` するため、Mason (Neovim 内 PATH) や extraPackages では Claude Code から利用できない。

ツールの消費者が Neovim・Claude Code・シェル・pre-commit と複数あり、全員からアクセスできる配置が必要。

## Decision

### ツール管理方式

| 観点                | Mason                        | Nix home.packages         | Nix extraPackages |
| ------------------- | ---------------------------- | ------------------------- | ----------------- |
| 再現性              | なし（手動 `:MasonInstall`） | **flake.lock で完全再現** | **同左**          |
| ロールバック        | 不可能                       | **`git revert` + `drs`**  | **同左**          |
| 新マシン構築        | 手動操作が必要               | **`drs` 一発**            | **同左**          |
| Neovim              | ○                            | ○                         | ○                 |
| Claude Code         | ✕                            | **○**                     | ✕                 |
| シェル / pre-commit | ✕                            | **○**                     | ✕                 |
| PATH 汚染           | Neovim 内のみ                | グローバル                | Neovim 内のみ     |

### 決定: Mason を全廃し home.packages に一本化する

- 全消費者（Neovim, Claude Code, シェル, pre-commit）から利用可能な唯一の配置が `home.packages`
- 再現性・ロールバック・新マシン構築で Nix が明確に優位
- PATH 汚染の実害なし（LSP バイナリ名は日常操作と被らない）
- Nix コミュニティの標準: [kickstart-nix.nvim](https://github.com/nix-community/kickstart-nix.nvim), [nixvim](https://github.com/nix-community/nixvim) はいずれも Mason 不使用
- devShell のツールは direnv で PATH 先頭に入り、home.packages より常に優先される

### extraPackages を不採用とした理由

- extraPackages は Neovim ラッパー内でしか PATH に入らない
- Claude Code の LSP プラグインは PATH から `spawn()` でバイナリを実行（[marketplace.json](https://github.com/anthropics/claude-plugins-public) で確認）。PATH にないと `ENOENT` で即失敗
- [folke/sidekick.nvim](https://github.com/folke/sidekick.nvim) で Neovim LSP diagnostics をテキスト経由で Claude Code に渡せるが、Claude Code 自身の LSP 機能（定義ジャンプ、参照検索等）は PATH にバイナリが必要

## Consequences

- `drs` 一発で全ツールが再現される。新マシンセットアップが完全自動化
- Mason 関連プラグイン（mason.nvim, mason-tool-installer.nvim）を削除でき、Neovim 設定がシンプルに
- **PATH 汚染は AI 時代の苦渋の決断。** LSP バイナリ名（`vtsls`, `lua-language-server` 等）がグローバル PATH に現れる。本来 extraPackages で Neovim に閉じ込めるべきだが、Claude Code の LSP プラグインが PATH を要求するため home.packages に置かざるを得な���。将来 [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim) の `getDiagnostics` 実装や IDE 統合が成熟し、Neovim の LSP を直接共有できるようになれば extraPackages への移行を再検討する
- Claude Code の TypeScript LSP は `typescript-language-server` を要求し、Neovim の `vtsls` とは別バイナリ。両方を home.packages に入れる
- 次のステップとして `ENABLE_LSP_TOOL=1` (settings.json) + LSP プラグイン有効化で Claude Code のビルトイン LSP 機能を活用可能。ただしプラグインシステムの安定性を見極めてから

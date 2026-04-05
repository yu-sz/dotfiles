# Claude Code LSP ツールの有効化とプラグイン戦略

Date: 2026-04-05
Status: Accepted

## Context

[ADR: Mason 全廃と Nix 一本化](./2026-04-05-mason-to-nix-migration.md) で LSP サーバーを home.packages に一本化した。次のステップとして、Claude Code の LSP ツールを有効化し、Grep ベースのコード検索から LSP ベースのシンボル検索・参照検索に移行する。

Claude Code は CLAUDE.md で明示的に指示しないと LSP より Grep を優先する（[zenn.dev/ncdc](https://zenn.dev/ncdc/articles/aad5538214237e)）。

### 公式プラグインの構造

公式マーケットプレイス（[`claude-plugins-official`](https://github.com/anthropics/claude-plugins-official)）の LSP プラグイン12個は、すべて以下のパターンで構成されている:

- [`marketplace.json`](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json) に `strict: false` + `lspServers` をインライン定義
- プラグインディレクトリには [LICENSE と README.md のみ](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/typescript-lsp)（`.lsp.json` や `plugin.json` なし）
- 言語ごとに1プラグインに分割（`lua-lsp`, `typescript-lsp`, `gopls-lsp` 等）

## Decision

### プラグイン方式の選択

| 観点             | 公式プラグイン                                                      | コミュニティ (boostvolt)                                                         | カスタムプラグイン                                                           |
| ---------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| LSP 動作         | ❌ [#15148](https://github.com/anthropics/claude-code/issues/15148) | ✅ 動作報告あり                                                                  | **✅ 確実に動作**                                                            |
| メンテナンス     | Anthropic                                                           | 個人 (143★)                                                                      | **自分**                                                                     |
| 言語選択         | 個別有効化                                                          | [一括ロードで応答停止の報告](https://zenn.dev/madebyjun/articles/0dedc8a95f3905) | **必要な言語のみ**                                                           |
| サプライチェーン | 低                                                                  | 中                                                                               | **なし**                                                                     |
| 設定の透明性     | marketplace.json に隠蔽                                             | リポジトリ公開                                                                   | **dotfiles で管理**                                                          |
| 公式サポート     | ✅                                                                  | -                                                                                | [✅ 公式機能](https://code.claude.com/docs/en/plugins-reference#lsp-servers) |

### 決定: dotfiles リポジトリをローカルマーケットプレイスとして構成する

- [ローカルマーケットプレイス](https://code.claude.com/docs/en/plugin-marketplaces)は公式にサポートされた配布機構
- 公式マーケットプレイスと同じパターンを採用: `strict: false` + `marketplace.json` に `lspServers` インライン定義 + 言語ごとにプラグイン分割
- `extraKnownMarketplaces` の `directory` ソースで参照（第一候補）。動かない場合は `github` ソースに切り替え
- Nix で管理済みの LSP サーバーバイナリをそのまま利用。hooks による自動インストールは不要（`nix/home/packages/lsp.nix` で PATH に入っている）
- `enabledPlugins` の公式 LSP プラグイン（`lua-lsp@claude-plugins-official`）は除去し、カスタムプラグインで置き換える
- プラグインの登録は `settings.json` の `extraKnownMarketplaces` で宣言的に管理。シンボリンク不要（プラグインはキャッシュにコピーされる）

### 対象言語と LSP サーバー

| 言語          | プラグイン名    | LSP サーバー         | Nix パッケージ         | 根拠                                        |
| ------------- | --------------- | -------------------- | ---------------------- | ------------------------------------------- |
| TypeScript/JS | `vtsls-lsp`     | **vtsls**            | `vtsls`                | Neovim と統一。公式は tsserver だが独自採用 |
| Lua           | `lua-lsp`       | lua-language-server  | `lua-language-server`  | 公式と同じバイナリ                          |
| Nix           | `nixd-lsp`      | nixd                 | `nixd`                 | 公式プラグインにはない                      |
| Bash          | `bash-lsp`      | bash-language-server | `bash-language-server` | 公式プラグインにはない                      |
| Terraform     | `terraform-lsp` | terraform-ls         | `terraform-ls`         | 公式プラグインにはない                      |

### `ENABLE_LSP_TOOL` 環境変数

- 公式ドキュメント（[settings](https://code.claude.com/docs/en/settings)、[plugins-reference](https://code.claude.com/docs/en/plugins-reference)）に記載なし
- [DevelopersIO](https://dev.classmethod.jp/en/articles/claude-code-lsp-from-local-marketplace/) で設定手順として言及されている
- 設定しても害はないが、公式ドキュメント上は LSP プラグインを設定するだけで有効になる設計。効果は検証で確認する

### `.lsp.json` は使用しない

- 公式マーケットプレイスの LSP プラグイン12個すべてが `.lsp.json` を使わず、marketplace.json にインライン定義している
- 「保険として `.lsp.json` も配置する」案は、`strict: false` との競合リスクがあるため採用しない

### `$schema` URL は使用しない

- 元計画の `"$schema": "https://anthropic.com/claude-code/marketplace.schema.json"` は 404 を返す
- 公式マーケットプレイスの marketplace.json には `$schema` フィールドが存在するが、URL が 404 のため実効性がない
- 省略しても動作に影響しないため、不要な依存を避ける

## Consequences

- TypeScript, Lua, Nix, Bash, Terraform の 5 言語でシンボル検索・参照検索が LSP 経由で利用可能になる
- 言語ごとにプラグインを分割しているため、`enabledPlugins` で個別にオンオフできる
- 公式プラグインのバグ（#15148）に依存せず、dotfiles で完結する確実な方式
- `marketplace.json` のメンテナンスは自分で行う必要がある。LSP サーバーのコマンド名やオプションが変わった場合に追従が必要
- 公式プラグインのバグが修正された場合、カスタムプラグインから公式に戻すことも可能（`enabledPlugins` の切り替えのみ）
- `directory` ソースを使用するため、`git push` なしでローカルで即反映される
- Nix 側の変更（`symlinks.nix` 等）は不要。`drs` なしで適用できる

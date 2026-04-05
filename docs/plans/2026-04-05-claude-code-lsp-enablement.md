# Claude Code LSP ツール有効化 実装計画

## 概要

- dotfiles リポジトリをローカルマーケットプレイスとして構成し、5 言語の LSP を有効化する
- 公式マーケットプレイスと同じパターン: `strict: false` + インライン `lspServers` + 言語ごとにプラグイン分割
- 公式 LSP プラグイン（`lua-lsp`）をカスタムプラグインで置き換える
- CLAUDE.md に LSP 優先利用の指示を追記する

**出典**:

- [ADR: Claude Code LSP ツールの有効化とプラグイン戦略](../adr/2026-04-05-claude-code-lsp-enablement.md)
- [公式ドキュメント: Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [公式ドキュメント: Plugins reference #lsp-servers](https://code.claude.com/docs/en/plugins-reference#lsp-servers)
- [公式マーケットプレイス: marketplace.json](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json)

---

## 元計画からの変更点

| 項目                     | 元計画                                                      | 修正後                                              | 根拠                                                                                 |
| ------------------------ | ----------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------ |
| プラグイン登録           | `symlinks.nix` でシンボリンク配置                           | `extraKnownMarketplaces` の `directory` ソース      | [公式ドキュメント](https://code.claude.com/docs/en/settings#extraknownmarketplaces)  |
| マーケットプレイスソース | `github` ソース（push 必須）                                | `directory` ソース（第一候補）、`github` は第二候補 | push 不要でローカル即反映                                                            |
| プラグイン構成           | 5言語を1プラグインにまとめ                                  | 言語ごとに5プラグインに分割                         | [公式マーケットプレイス][official-mp]の全12 LSP プラグインと同じパターン             |
| `.lsp.json`              | 保険として配置                                              | 作成しない                                          | 公式は `.lsp.json` を使わず marketplace.json インライン定義のみ                      |
| `$schema`                | `https://anthropic.com/claude-code/marketplace.schema.json` | 削除                                                | URL は 404。公式マーケットプレイスには記載があるが、404 を返すため省略しても問題なし |
| `ENABLE_LSP_TOOL`        | 設定する                                                    | 設定するが効果は検証で確認                          | 公式ドキュメントに記載なし。害はない                                                 |
| `directory` ソース       | -                                                           | 「for development only」と認識した上で採用          | [公式ドキュメント](https://code.claude.com/docs/en/settings)に明記。JSON 例なし      |
| JSONC                    | トレイリングカンマあり                                      | 標準 JSON に修正                                    | 公式例はすべて標準 JSON                                                              |
| `symlinks.nix`           | `.claude/plugins/lsp` 追加                                  | 変更不要                                            | プラグインはキャッシュにコピーされる                                                 |

---

## 決定事項

| 項目            | 決定                                                                            | 備考                                              |
| --------------- | ------------------------------------------------------------------------------- | ------------------------------------------------- |
| プラグイン方式  | **ローカルマーケットプレイス（`extraKnownMarketplaces` + `directory` ソース）** | 第一候補。動かなければ `github` ソースに切り替え  |
| プラグイン構成  | **言語ごとに分割（5プラグイン）**                                               | 公式パターン。`enabledPlugins` で個別オンオフ可能 |
| TypeScript LSP  | **vtsls**                                                                       | Neovim と統一                                     |
| 対象言語        | **TS, Lua, Nix, Bash, Terraform**                                               | Nix 管理済みバイナリを利用                        |
| ENABLE_LSP_TOOL | **`"1"` を env に追加**                                                         | 公式未記載だが害はない。効果は検証                |
| 公式 lua-lsp    | **除去**                                                                        | カスタムプラグインで置き換え                      |
| CLAUDE.md       | **Code Navigation セクション追記**                                              | LSP 優先利用の指示                                |

---

## 設計: ディレクトリ構成

```text
dotfiles/                                （リポジトリルート）
├── .claude-plugin/
│   └── marketplace.json                 ← 新規作成
├── plugins/
│   ├── vtsls-lsp/
│   │   └── README.md                   ← 新規作成
│   ├── lua-lsp/
│   │   └── README.md                   ← 新規作成
│   ├── nixd-lsp/
│   │   └── README.md                   ← 新規作成
│   ├── bash-lsp/
│   │   └── README.md                   ← 新規作成
│   └── terraform-lsp/
│       └── README.md                   ← 新規作成
├── config/
│   └── claude/
│       └── settings.json               ← 変更
├── CLAUDE.md                            ← 変更
└── ...
```

## 設計: marketplace.json

公式マーケットプレイスと同じパターン。`strict: false` + `lspServers` インライン定義。

```json
{
  "name": "dotfiles-lsp",
  "owner": {
    "name": "yu-sz"
  },
  "metadata": {
    "description": "LSP plugins for this dotfiles environment"
  },
  "plugins": [
    {
      "name": "vtsls-lsp",
      "source": "./plugins/vtsls-lsp",
      "description": "TypeScript/JavaScript language server (vtsls) for code intelligence",
      "version": "1.0.0",
      "category": "development",
      "strict": false,
      "lspServers": {
        "vtsls": {
          "command": "vtsls",
          "args": ["--stdio"],
          "extensionToLanguage": {
            ".ts": "typescript",
            ".tsx": "typescriptreact",
            ".js": "javascript",
            ".jsx": "javascriptreact",
            ".mjs": "javascript",
            ".cjs": "javascript"
          }
        }
      }
    },
    {
      "name": "lua-lsp",
      "source": "./plugins/lua-lsp",
      "description": "Lua language server for code intelligence",
      "version": "1.0.0",
      "category": "development",
      "strict": false,
      "lspServers": {
        "lua": {
          "command": "lua-language-server",
          "extensionToLanguage": {
            ".lua": "lua"
          }
        }
      }
    },
    {
      "name": "nixd-lsp",
      "source": "./plugins/nixd-lsp",
      "description": "Nix language server (nixd) for code intelligence",
      "version": "1.0.0",
      "category": "development",
      "strict": false,
      "lspServers": {
        "nixd": {
          "command": "nixd",
          "extensionToLanguage": {
            ".nix": "nix"
          }
        }
      }
    },
    {
      "name": "bash-lsp",
      "source": "./plugins/bash-lsp",
      "description": "Bash language server for code intelligence",
      "version": "1.0.0",
      "category": "development",
      "strict": false,
      "lspServers": {
        "bash": {
          "command": "bash-language-server",
          "args": ["start"],
          "extensionToLanguage": {
            ".sh": "shellscript",
            ".bash": "shellscript",
            ".zsh": "shellscript"
          }
        }
      }
    },
    {
      "name": "terraform-lsp",
      "source": "./plugins/terraform-lsp",
      "description": "Terraform language server for code intelligence",
      "version": "1.0.0",
      "category": "development",
      "strict": false,
      "lspServers": {
        "terraform": {
          "command": "terraform-ls",
          "args": ["serve"],
          "extensionToLanguage": {
            ".tf": "terraform"
          }
        }
      }
    }
  ]
}
```

## 設計: settings.json（変更部分のみ）

```json
{
  "env": {
    "ENABLE_LSP_TOOL": "1"
  },
  "extraKnownMarketplaces": {
    "dotfiles-lsp": {
      "source": {
        "source": "directory",
        "path": "."
      }
    }
  },
  "enabledPlugins": {
    "example-skills@anthropic-agent-skills": true,
    "lua-lsp@claude-plugins-official": false,
    "vtsls-lsp@dotfiles-lsp": true,
    "lua-lsp@dotfiles-lsp": true,
    "nixd-lsp@dotfiles-lsp": true,
    "bash-lsp@dotfiles-lsp": true,
    "terraform-lsp@dotfiles-lsp": true
  }
}
```

`lua-lsp@claude-plugins-official` は除去。

## 設計: CLAUDE.md 追記

```markdown
## Code Navigation

- Use LSP tools (goToDefinition, findReferences, documentSymbol, workspaceSymbol) for symbol search and reference lookup
- Before renaming or changing a function signature, use findReferences to find all call sites first
- Use Grep only for plain text search or when LSP is unavailable for the file type
```

---

## 実装手順

### Phase 1: マーケットプレイス + プラグイン作成

- [x] 1-1: `.claude-plugin/marketplace.json` を作成（5言語分のプラグイン定義をインライン記述）
- [x] 1-2: `plugins/vtsls-lsp/README.md` を作成
- [x] 1-3: `plugins/lua-lsp/README.md` を作成
- [x] 1-4: `plugins/nixd-lsp/README.md` を作成
- [x] 1-5: `plugins/bash-lsp/README.md` を作成
- [x] 1-6: `plugins/terraform-lsp/README.md` を作成
- [x] 1-7: `config/claude/settings.json` に `extraKnownMarketplaces` を追加（ネスト形式 + `directory` ソース）
- [x] 1-8: `config/claude/settings.json` の `enabledPlugins` を更新（5プラグイン追加、`lua-lsp@claude-plugins-official` を `false` で明示無効化）
- [x] 1-9: `config/claude/settings.json` の env に `"ENABLE_LSP_TOOL": "1"` を追加
- [x] 1-10: `git add` で新規ファイルを追跡対象にする

### Phase 2: CLAUDE.md 追記

- [x] 2-1: `CLAUDE.md` に Code Navigation セクションを追記（Skills セクションの直前に配置）

### Phase 3: 検証

- [x] 3-0a: 各 LSP バイナリが PATH 上にあるか `which` で確認（全5バイナリ確認OK）
- [x] 3-0b: `claude plugin validate .` で marketplace.json の構文検証（トップレベル `description` → `metadata.description` に移動して通過）
- [x] 3-1: Claude Code を再起動
- [x] 3-1b: `claude plugin marketplace list` でマーケットプレイス認識確認（パス解決の問題を発見・修正: `~/Projects/dotfiles` → `.`）
- [x] 3-2: `/plugin` でカスタム LSP プラグイン5個が認識されているか確認（全5プラグイン enabled）
- [x] 3-3: `/plugin` の Errors タブでエラーがないか確認（dotfiles-lsp 関連のエラーなし。`example-skills@anthropic-agent-skills` は既存の無関係エラー）
- [x] 3-4: TypeScript ファイルに対して `LSP goToDefinition` を実行（一時ファイルで検証。goToDefinition・findReferences・documentSymbol 全て正常動作）
- [x] 3-5: Lua ファイルに対して `LSP documentSymbol` を実行（`nvim-lspconfig.lua` で正常動作確認）
- [x] 3-6: Nix ファイルに対して `LSP documentSymbol` を実行（`nix/home/default.nix` で正常動作確認。nixd サーバー応答OK）
- [ ] ~~3-7: ネスト形式で動かない場合、フラット形式に切り替え~~ → 不要（`path: "."` で解決済み）
- [ ] ~~3-8: フラット形式でも動かない場合、手動コマンドで検証~~ → 不要
- [ ] ~~3-9: いずれも動かない場合、`github` ソースに切り替え~~ → 不要

---

## 変更対象ファイル一覧

| ファイル                          | 操作                                                     |
| --------------------------------- | -------------------------------------------------------- |
| `.claude-plugin/marketplace.json` | 新規作成                                                 |
| `plugins/vtsls-lsp/README.md`     | 新規作成                                                 |
| `plugins/lua-lsp/README.md`       | 新規作成                                                 |
| `plugins/nixd-lsp/README.md`      | 新規作成                                                 |
| `plugins/bash-lsp/README.md`      | 新規作成                                                 |
| `plugins/terraform-lsp/README.md` | 新規作成                                                 |
| `config/claude/settings.json`     | `extraKnownMarketplaces` + `enabledPlugins` + `env` 変更 |
| `CLAUDE.md`                       | Code Navigation 追記                                     |

## 懸念事項

- `directory` ソースは公式ドキュメント（settings ページ）に「for development only」と明記されている。具体的な JSON 例は公式に存在しないため、形式はネスト → フラット → 手動コマンドの順で検証する
- `directory` ソースの `path` から `.claude-plugin/marketplace.json` を自動探索するかはドキュメント上で明確に定義されていない。動かない場合は `github` ソースに切り替え
- `directory` ソースのパスはマルチマシン対応のためユーザー名をハードコードしない。公式ドキュメントの例はすべて絶対パスだが、以下の順で Phase 3 で検証する:
  1. `~/Projects/dotfiles`（チルダ展開）
  2. `$DOTFILES_DIR`（`.zshenv` で既に `export DOTFILES_DIR="$HOME/Projects/dotfiles"` として定義済み）
  3. いずれも動かなければ `home.file` で `${config.home.homeDirectory}` からビルド時に絶対パスを埋め込む（確実）
- `extraKnownMarketplaces` の初回利用時に trust ダイアログが表示される可能性（[#13097](https://github.com/anthropics/claude-code/issues/13097)）
- dotfiles リポジトリのルートに `.claude-plugin/` を置くことで、他の用途でこのリポジトリを `marketplace add` したときに意図せずプラグインが見える
- `ENABLE_LSP_TOOL` は公式ドキュメントに記載なし。効果がない可能性あり

---

## レビュー結果（2026-04-05）

公式ドキュメント・公式マーケットプレイス（`anthropics/claude-plugins-official`）の実構造と照合した結果。

### 実行可能性: 高い

基本設計（ローカルマーケットプレイス + 言語別プラグイン分割 + `extraKnownMarketplaces`）は公式パターンに忠実。

### 公式と一致を確認した項目

- `strict: false` + インライン `lspServers` のパターン（公式 LSP プラグイン全12個と同じ）
- プラグインディレクトリに README のみ（公式も LICENSE + README のみ。`plugin.json` はオプション）
- `extraKnownMarketplaces` のネスト形式（公式ドキュメントの例と一致）
- `$schema` 削除（URL が 404）
- `marketplace.json` の `description` トップレベル配置（公式実装と一致）

### 修正事項

| #   | 項目             | 修正内容                                              | 根拠                                             |
| --- | ---------------- | ----------------------------------------------------- | ------------------------------------------------ |
| 1   | `enabledPlugins` | `"lua-lsp@claude-plugins-official": false` を明示追加 | 単に削除すると再インストール提案される可能性あり |

### 検証手順の追加

元計画の Phase 3 に以下を追加:

- `which` で各 LSP バイナリの PATH 確認（Nix 管理バイナリが Claude Code から見えるか）
- `claude plugin validate .` で marketplace.json の構文検証（公式提供コマンド）
- `claude plugin marketplace list` でマーケットプレイス認識確認

### 注意事項

- **`vtsls`**: 公式は `typescript-language-server` を使用。`vtsls` は前例なしだが、仕様上任意バイナリを指定可能。`--stdio` での LSP プロトコル互換性を要確認
- **`ENABLE_LSP_TOOL`**: 公式ドキュメントに記載なし。LSP ツールはプラグインインストールのみで有効化される（[plugins-reference](https://code.claude.com/docs/en/plugins-reference#lsp-servers)）。害はないため据え置き
- **`directory` パス**: 公式例は全て絶対パス。チルダ展開は JSON パーサーの保証外。`~` → `$DOTFILES_DIR` → `home.file` の順で段階的に検証

---

## 予実差異

### Phase 1

| 項目                                | 計画                   | 実際                            | 影響                                                                                                              |
| ----------------------------------- | ---------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `marketplace.json` の `description` | トップレベルに配置     | `metadata.description` にネスト | `claude plugin validate` でトップレベル `description` が不正キーとして検出。公式スキーマは `metadata.description` |
| `drs` 実行                          | symlink 反映のため必要 | 不要                            | `settings.json` は既存 symlink で反映済み。新規ファイルは symlink 対象外                                          |

### Phase 2

予実差異なし

### Phase 3

| 項目                        | 計画                    | 実際                                         | 影響                                                                                                  |
| --------------------------- | ----------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `directory` ソースのパス    | `~/Projects/dotfiles`   | `.`（相対パス）                              | `~` はプロジェクトルートからの相対パスとして結合され二重パスになった。同一リポジトリなので `.` で解決 |
| TypeScript LSP 検証         | `goToDefinition` テスト | 一時ファイル `/tmp/lsp-test/index.ts` で検証 | dotfiles に TS ファイルなし。goToDefinition・findReferences・documentSymbol 全て正常動作              |
| Nix LSP 検証                | `findReferences` テスト | `documentSymbol` に変更                      | import パス文字列には references がないため、documentSymbol で動作確認                                |
| フォールバック手順 3-7〜3-9 | 順次検証                | 不要                                         | `path: "."` で一発解決                                                                                |

[official-mp]: https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json

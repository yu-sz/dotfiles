# Go 開発環境構築 実装計画

## 概要

- Nix で Go 開発ツール（gopls, golangci-lint, delve）をインストール
- Neovim に gopls LSP・gofumpt フォーマット・golangci-lint リンター・Treesitter を設定
- Claude Code に gopls LSP プラグインを追加

**出典**:

- [ADR: Go 開発環境のツールチェーン選定](../adr/2026-04-06-go-development-toolchain-selection.md)

---

## 決定事項

| 項目           | 決定                                  | 備考                                      |
| -------------- | ------------------------------------- | ----------------------------------------- |
| Go ランタイム  | **mise で管理**                       | Nix には入れない                          |
| フォーマッター | **gofumpt（gopls 経由）**             | conform.lua 変更不要。lsp_format=fallback |
| import 整理    | **organizeImports 自動実行**          | gopls.lua の on_attach で BufWritePre     |
| リンター       | **golangci-lint + gopls staticcheck** | nvim-lint 名は `golangcilint`             |
| デバッガ       | **delve**                             | nvim-dap 連携は別途                       |
| Treesitter     | **go, gomod, gosum, gowork**          | 4パーサー追加                             |
| Claude Code    | **gopls-lsp プラグイン追加**          | marketplace.json + settings.json          |

---

## 設計: gopls LSP

```lua
-- config/nvim/after/lsp/gopls.lua（新規作成）
---@type vim.lsp.Config
return {
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
        params.context = { only = { "source.organizeImports" } }
        local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
        for _, res in pairs(result or {}) do
          for _, action in pairs(res.result or {}) do
            if action.edit then
              vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
            end
          end
        end
      end,
    })
  end,
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        useany = true,
        nilness = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
}
```

## 設計: Nix パッケージ

```nix
# nix/home/packages/lsp-tools.nix（差分）
home.packages = with pkgs; [
  bash-language-server
  copilot-language-server
  delve              # 追加
  golangci-lint      # 追加
  gopls              # 追加
  lua-language-server
  # ... 以下既存
];
```

## 設計: Claude Code LSP プラグイン

```json
// .claude-plugin/marketplace.json の plugins 配列に追加
{
  "name": "gopls-lsp",
  "source": "./plugins/gopls-lsp",
  "description": "Go language server (gopls) for code intelligence",
  "version": "1.0.0",
  "category": "development",
  "strict": false,
  "lspServers": {
    "gopls": {
      "command": "gopls",
      "extensionToLanguage": {
        ".go": "go",
        ".mod": "gomod"
      }
    }
  }
}
```

```json
// config/claude/settings.json の enabledPlugins に追加
"gopls-lsp@dotfiles-lsp": true
```

---

## 実装手順

### Phase 1: Nix パッケージ追加

- [x] 1-1: `nix/home/packages/lsp-tools.nix` に delve, golangci-lint, gopls を追加
- [x] 1-2: `git add` して `! drs` でインストール
- [x] 1-3: `which gopls golangci-lint dlv` で確認

> **予実差異なし**

### Phase 2: Neovim 設定

- [x] 2-1: `config/nvim/after/lsp/gopls.lua` を新規作成（on_attach + settings）
- [x] 2-2: `config/nvim/lua/lsp/init.lua` の `vim.lsp.enable` に `"gopls"` を追加
- [x] 2-3: `config/nvim/lua/plugins/nvim-lint.lua` に `go = { "golangcilint" }` を追加
- [x] 2-4: `config/nvim/lua/plugins/nvim-treesitter.lua` に `go`, `gomod`, `gosum`, `gowork` を追加
- [x] 2-5: `git add` して `! drs`（新規ファイル gopls.lua があるため）

> **予実差異**: Phase 2 と Phase 3 の `git add` と `drs` は Phase 1 とまとめて1回で実行した。

### Phase 3: Claude Code LSP

- [x] 3-1: `.claude-plugin/marketplace.json` に gopls-lsp プラグインを追加
- [x] 3-2: `config/claude/settings.json` の `enabledPlugins` に `gopls-lsp@dotfiles-lsp: true` を追加
- [x] 3-3: `! drs` で symlink 反映

> **予実差異**: Phase 1 の `drs` でまとめて反映済み。

### Phase 4: 検証

- [ ] 4-1: `.go` ファイルを開いて `:checkhealth lsp` で gopls アタッチ確認
- [ ] 4-2: 保存時に gofumpt フォーマット + organizeImports が動作することを確認
- [ ] 4-3: 未使用変数で golangci-lint 診断が出ることを確認
- [ ] 4-4: `:InspectTree` で Treesitter ハイライト確認
- [ ] 4-5: Claude Code で `.go` ファイルの LSP ツールが動作することを確認

---

## 変更対象ファイル一覧

| ファイル                                      | Phase 1        | Phase 2           | Phase 3          |
| --------------------------------------------- | -------------- | ----------------- | ---------------- |
| `nix/home/packages/lsp-tools.nix`             | パッケージ追加 | -                 | -                |
| `config/nvim/after/lsp/gopls.lua`             | -              | 新規作成          | -                |
| `config/nvim/lua/lsp/init.lua`                | -              | gopls 有効化      | -                |
| `config/nvim/lua/plugins/nvim-lint.lua`       | -              | golangcilint 追加 | -                |
| `config/nvim/lua/plugins/nvim-treesitter.lua` | -              | go パーサー追加   | -                |
| `.claude-plugin/marketplace.json`             | -              | -                 | プラグイン追加   |
| `config/claude/settings.json`                 | -              | -                 | プラグイン有効化 |

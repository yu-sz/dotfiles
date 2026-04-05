# ツール管理再設計 + Markdown チェック追加 実装計画

## 概要

- Mason を全廃し、LSP/フォーマッター/リンターを Nix (home.packages + devShell) に一本化
- home.packages をカテゴリ別ファイルに分割（`nix/home/packages/`）
- pre-commit に markdownlint (リント) + prettier (フォーマット) を追加
- conform.nvim で biome プロジェクトの prettier フォールバックを防止

**出典**:

- [ADR: Mason 全廃と Nix 一本化](../adr/2026-04-05-mason-to-nix-migration.md)
- [ADR: Markdown フォーマッター選定](../adr/2026-04-05-markdown-formatter-selection.md)

---

## 決定事項

| 項目               | 決定                                                          | 備考                                                 |
| ------------------ | ------------------------------------------------------------- | ---------------------------------------------------- |
| ツール管理         | **Mason 全廃、Nix 一本化**                                    | home.packages + devShell                             |
| LSP 配置           | **全て home.packages**                                        | Claude Code LSP プラグインが PATH を要求             |
| フォーマッター配置 | **home.packages + devShell 重複**                             | devShell が優先、home がフォールバック               |
| MD フォーマッター  | **prettier 維持**                                             | mdformat/dprint はデータ損失バグあり                 |
| MD リンター        | **markdownlint (git-hooks.nix ビルトイン)**                   | カスタムフック定義不要                               |
| conform.nvim       | **web_formatter_config を関数化**                             | biome プロジェクト検出で prettier フォールバック防止 |
| TS LSP             | **vtsls (Neovim) + typescript-language-server (Claude Code)** | 別バイナリ、両方 home.packages                       |
| パッケージ構成     | **`nix/home/packages/` に分割**                               | カテゴリ別ファイルで管理                             |
| allowUnfree        | **copilot-language-server を追加**                            | unfree ライセンス (GitHub Copilot License)           |
| MD リント設定      | **`.markdownlint.yaml` を Phase 1 で作成**                    | pre-commit (entry override) と nvim-lint で共有      |

---

## 設計: home.packages の分割

```text
nix/home/
├── default.nix        # imports に ./packages を追加
├── packages/
│   ├── default.nix    # imports で全ファイルを集約
│   ├── base.nix       # neovim, vim, tmux
│   ├── shell.nix      # ripgrep, fd, gomi, hyperfine, zabrze
│   ├── cli.nix        # awscli2, ghq, jq, pgcli, etc.
│   ├── dev.nix        # tree-sitter, hadolint, mkcert, luarocks, postgresql, etc.
│   ├── lsp.nix        # 全 LSP サーバー (NEW)
│   ├── formatter.nix  # prettier, stylua, shfmt (NEW)
│   ├── linter.nix     # shellcheck, luacheck, markdownlint-cli (NEW)
│   └── editor.nix     # claude-code, mise, sheldon, tenv
├── programs/
│   └── ...
└── ...
```

```nix
# nix/home/packages/lsp.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    vtsls
    lua-language-server
    bash-language-server
    vscode-langservers-extracted
    tailwindcss-language-server
    typescript-language-server
    terraform-ls
    yaml-language-server
    prisma-language-server
    copilot-language-server
    nixd
  ];
}
```

```nix
# nix/home/packages/formatter.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    prettier
    stylua
    shfmt
  ];
}
```

```nix
# nix/home/packages/linter.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    shellcheck
    luaPackages.luacheck
    markdownlint-cli
  ];
}
```

---

## 設計: allowUnfree

```nix
# flake.nix — copilot-language-server は unfree (GitHub Copilot License)
nixpkgs.config.allowUnfreePredicate =
  pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [
    "claude-code"
    "copilot-language-server"
  ];
```

---

## 設計: devShell

```nix
# flake.nix
devShells.default = pkgs.mkShell {
  inherit (config.pre-commit) shellHook;
  packages = config.pre-commit.settings.enabledPackages ++ [
    pkgs.just
    pkgs.gitleaks
    pkgs.prettier
    pkgs.stylua
    pkgs.shfmt
    pkgs.luaPackages.luacheck
  ];
};
```

---

## 設計: pre-commit フック

```nix
# flake.nix pre-commit.settings.hooks に追加
markdownlint = {
  enable = true;
  entry = lib.mkForce "${pkgs.markdownlint-cli}/bin/markdownlint -c .markdownlint.yaml";
};
prettier = {
  enable = true;
  # ビルトインのデフォルトは types = [ "text" ] (全テキスト対象)
  # pre-commit は types (AND) と types_or (OR) を両方評価するため、
  # 結果は "text AND (markdown OR yaml)" となる
  # markdown/yaml は text のサブタイプなのでフィルタリングは正しく動作する
  types_or = [ "markdown" "yaml" ];
};
```

---

## 設計: conform.nvim

```lua
-- config/nvim/lua/plugins/conform.lua
local web_formatter_config = function(bufnr)
  if vim.fs.root(bufnr, { "biome.json", "biome.jsonc" }) then
    return { "biome-check" }
  end
  return { "biome-check", "prettier", stop_after_first = true }
end
```

---

## 実装手順

### Phase 1: home.packages 分割 + LSP/formatter/linter 追加

- [x] 1-1: `nix/home/packages/` ディレクトリ作成、既存パッケージをカテゴリ別ファイルに分割（9ファイル作成、gitmux/lazydocker は cli.nix に配置）
- [x] 1-2: `nix/home/packages/lsp.nix` 作成（Mason から移行する LSP 群）（1-1 で実施済み）
- [x] 1-3: `nix/home/packages/formatter.nix` 作成（prettier, stylua, shfmt）（1-1 で実施済み）
- [x] 1-4: `nix/home/packages/linter.nix` 作成（shellcheck, luacheck, markdownlint-cli）（1-1 で実施済み）
- [x] 1-5: `nix/home/default.nix` の imports に `./packages` を追加、既存 home.packages を整理（引数も `{ ... }:` に簡略化）
- [x] 1-6: `flake.nix` の `allowUnfreePredicate` に `"copilot-language-server"` 追加
- [x] 1-7: `flake.nix` の devShell にフォーマッター/リンター追加
- [x] 1-8: `flake.nix` に markdownlint + prettier pre-commit フック追加（perSystem に lib 引数も追加）
- [x] 1-9: `.markdownlint.yaml` 作成（pre-commit と nvim-lint でルール共有）（MD013=300, MD024=siblings_only, MD033=br許可）
- [x] 1-10: `git add` → `! drs` で Nix 設定適用（+687 MiB、LSP/formatter/linter 全て追加成功）
- [x] 1-11: `which vtsls && which prettier && which lua-language-server` で確認（全12ツール PATH 確認済み、Mason 版が優先されるものあり→Phase 2 で解消）
- [x] 1-12: `direnv reload` → pre-commit フック動作確認（devShell で Nix 版 prettier/luacheck 確認）
- [x] 1-13: prettier フックが MD/YAML のみに適用され、JS/TS に適用されないことを確認（Lua ファイルで Skipped 確認）

### Phase 2: Mason 削除 + conform.nvim 修正

- [x] 2-1: `config/nvim/lua/plugins/mason.lua` を削除（gomi でゴミ箱に移動）
- [x] 2-2: `config/nvim/lua/plugins/conform.lua` の `web_formatter_config` を関数化 + `lsp_fallback` → `lsp_format = "fallback"` に更新（LuaCATS アノテーション追加）
- [x] 2-3: `config/nvim/lua/plugins/nvim-lint.lua` に `markdown = { "markdownlint" }` 追加
- [x] 2-4: Neovim で `:checkhealth lsp` — LSP 動作確認（全 LSP が Nix パスに解決、Mason パスなし）
- [x] 2-5: Neovim で `:ConformInfo` — formatter パスが Nix 版を指すことを確認（prettier/stylua/shfmt/nixfmt 全て /nix/store/ パス）
- [x] 2-6: dotfiles で MD を保存 → prettier 適用確認（prettier ready、50ms で応答）
- [x] 2-7: Claude Code で MD 編集 → format.sh で prettier 動作確認（markdownlint-cli 動作確認済み）

### Phase 3: 検証

- [x] 3-1: commit で markdownlint + prettier pre-commit フック動作確認（MD040 検出→修正→Passed）
- [x] 3-2: markdownlint の警告を確認し、`.markdownlint.yaml` のルール調整が必要か検討（MD040 を有効のまま維持、ディレクトリツリーに `text` 言語指定で対応）

---

## 変更対象ファイル一覧

| ファイル                                | Phase 1                                          | Phase 2                                              |
| --------------------------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| `nix/home/default.nix`                  | imports に `./packages` 追加、既存 packages 整理 | -                                                    |
| `nix/home/packages/default.nix`         | 新規作成（集約）                                 | -                                                    |
| `nix/home/packages/base.nix`            | 新規作成                                         | -                                                    |
| `nix/home/packages/shell.nix`           | 新規作成                                         | -                                                    |
| `nix/home/packages/cli.nix`             | 新規作成                                         | -                                                    |
| `nix/home/packages/dev.nix`             | 新規作成                                         | -                                                    |
| `nix/home/packages/lsp.nix`             | 新規作成（Mason から移行）                       | -                                                    |
| `nix/home/packages/formatter.nix`       | 新規作成（Mason から移行）                       | -                                                    |
| `nix/home/packages/linter.nix`          | 新規作成（Mason から移行）                       | -                                                    |
| `nix/home/packages/editor.nix`          | 新規作成                                         | -                                                    |
| `flake.nix`                             | allowUnfree + devShell + pre-commit フック追加   | -                                                    |
| `.markdownlint.yaml`                    | 新規作成（ルール設定）                           | -                                                    |
| `config/nvim/lua/plugins/mason.lua`     | -                                                | 削除                                                 |
| `config/nvim/lua/plugins/conform.lua`   | -                                                | `web_formatter_config` 関数化 + `lsp_fallback` 更��� |
| `config/nvim/lua/plugins/nvim-lint.lua` | -                                                | markdownlint 追加                                    |

---

## 予実差異

### Phase 1

- **perSystem に `lib` 引数追加**: 計画では明示されていなかったが、`lib.mkForce` に必要だったため追加
- **gitmux, lazydocker の配置**: 計画のカテゴリ設計に含まれていなかったため `cli.nix` に配置
- それ以外は予実差異なし

### Phase 2

- 予実差異なし

### Phase 3

- **MD040 (fenced-code-language)**: Plans ファイル内のディレクトリツリー表記でコードブロック言語指定が必要だった。`text` を指定して対応。`.markdownlint.yaml` のルール変更は不要と判断

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Initial setup
./scripts/install.sh

# Apply config changes after editing Nix files
# macOS (uses nh):
drs
# or: just switch (from dotfiles directory)
# Linux:
# home-manager switch --flake .#<user>@<hostname>
```

No tests or build system.

## Architecture

### Symlink Strategy

`config/*` -> `~/.config/` (XDG compliant)

Special cases:
- `config/claude/*` -> `~/.claude/` (Claude CLI does not support XDG)
- `config/zsh/.zshenv` -> `~/.zshenv`

When adding files to `config/claude/`, also update `nix/home/symlinks.nix` (`home.file` section).

### Zsh Loading Pattern

Sheldon manages plugins with `zsh-defer` for lazy loading:
- `eager/*.zsh` - Loaded immediately (PATH, critical settings)
- `lazy/*.zsh` - Deferred loading (aliases, completions, functions)

### Neovim Structure

```
nvim/
├── init.lua           # Entry: requires commands, config, lsp
├── lua/
│   ├── config/        # Options, autocmd, lazy.nvim setup
│   ├── plugins/       # One file per plugin (lazy.nvim spec)
│   ├── commands/      # Custom user commands
│   └── lsp/           # LSP base config
└── after/lsp/         # Per-server LSP overrides
```

Plugin files return lazy.nvim spec table directly.

### WezTerm Structure

Modular Lua config with `require()`:
- `wezterm.lua` - Entry, merges all modules
- `styles.lua`, `tab_bar.lua`, `hooks.lua` - Separated concerns

## Conventions

### Lua Config Files

All Lua configs (Neovim, WezTerm, Yazi) follow:
- Module pattern with LuaCATS annotations
- `snake_case` naming

### Nix Package Management

- **CLI tools**: `nix/home/default.nix` (`home.packages`)
- **macOS-only tools**: `nix/home/darwin.nix`
- **GUI apps (cask)**: `nix/hosts/darwin-shared.nix` (`homebrew.casks`)
- **Fonts**: `nix/hosts/darwin-shared.nix` (`fonts.packages`)
- **Custom packages**: `nix/overlays/` (e.g. zabrze)

After editing, run `drs`.

### Nix Flake Workflow

- Nix flake は Git 追跡ファイルのみ認識する。**新規ファイル作成後は必ず `git add` する**
- `drs` 実行前に `git status` で未追跡ファイルがないか確認する
- 新しいツール導入時: まずパッケージを追加・適用してから設定を切り替える（未インストールのツールを参照しない）

### Zabrze Abbreviations

TOML files in `config/zabrze/` define shell abbreviations:
```toml
[[snippets]]
name = "description"
trigger = "short"
snippet = "expanded command"
```

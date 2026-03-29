# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Initial setup
./scripts/install.sh

# Apply config changes after editing Nix files
# macOS:
darwin-rebuild switch --flake .#suta-ro
# or use the alias: drs
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

After editing, run `drs` (or `darwin-rebuild switch --flake .#<hostname>`).

### Zabrze Abbreviations

TOML files in `config/zabrze/` define shell abbreviations:
```toml
[[snippets]]
name = "description"
trigger = "short"
snippet = "expanded command"
```

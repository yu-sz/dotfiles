# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Initial setup (creates symlinks, installs Homebrew packages, mise tools)
./scripts/setup.sh

# Add new Homebrew package
# Edit config/homebrew/Brewfile, then:
brew bundle install --file config/homebrew/Brewfile
```

No tests or build system.

## Architecture

### Symlink Strategy

`config/*` -> `~/.config/` (XDG compliant)

Special cases:
- `config/claude/*` -> `~/.claude/` (Claude CLI does not support XDG)
- `config/zsh/.zshenv` -> `~/.zshenv`
- `config/vim` -> `~/.vim`

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

### Brewfile Format

```ruby
tap "owner/repo"       # Third-party taps
brew "formula"         # CLI tools
cask "application"     # GUI apps
```

Group by: taps -> formulae (categorized) -> casks

### Zabrze Abbreviations

YAML files in `config/zabrze/` define shell abbreviations:
```yaml
abbrevs:
  - name: description
    abbr: short
    snippet: expanded command
```

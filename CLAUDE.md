# CLAUDE.md

## Commands

```bash
drs                # Apply Nix config changes (macOS, uses nh)
just switch        # Alternative (from dotfiles directory)
```

No tests or build system.

## Symlink Strategy

All configs follow the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/). New config files must be placed under `config/` and symlinked to `~/.config/`.

`config/*` → `~/.config/`

Special cases:

- `config/claude/*` → `~/.claude/`
- `config/zsh/.zshenv` → `~/.zshenv`

When adding files to `config/claude/`, also update `nix/home/symlinks.nix`.

## Multi-Machine Strategy

- `flake.nix` の `darwinConfigurations` がホスト名単位で構成を管理
- `specialArgs` で `username` を渡し、ユーザー名の差異を吸収
- 新マシン追加は `scripts/bootstrap.sh` が自動で行う

## Nix Package Management

- **CLI tools**: `nix/home/default.nix` (`home.packages`)
- **macOS-only tools**: `nix/home/darwin.nix`
- **GUI apps (cask)**: `nix/hosts/darwin-shared.nix` (`homebrew.casks`)
- **Fonts**: `nix/hosts/darwin-shared.nix` (`fonts.packages`)
- **Custom packages**: `nix/overlays/`

## Nix Flake Workflow

- Nix flake only sees Git-tracked files. **Always `git add` after creating new files.**
- Run `git status` before `drs` to check for untracked files.
- When introducing new tools: add package and apply first, then switch configs. Never reference uninstalled tools.
- `drs` / `nh darwin switch` requires sudo. Do not run directly — ask the user to run `! drs` instead.
- `.zshenv` has `unsetopt GLOBAL_RCS`, so HM's `hm-session-vars.sh` is never sourced. Environment variables set via `home.sessionVariables` won't work — use explicit paths instead.

## Lua Config Files

All Lua configs (Neovim, WezTerm, Yazi): module pattern with LuaCATS annotations, `snake_case` naming.

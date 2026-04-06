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

- `darwinConfigurations` in `flake.nix` manages per-host configurations
- `specialArgs` passes `username` to absorb differences across machines
- Adding a new machine is automated by `scripts/bootstrap.sh`

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

## Code Navigation

- Use LSP tools (goToDefinition, findReferences, documentSymbol, workspaceSymbol) for symbol search and reference lookup
- Before renaming or changing a function signature, use findReferences to find all call sites first
- Use Grep only for plain text search or when LSP is unavailable for the file type

## Skills

Skill auto-invocation is unreliable. Always load the corresponding skill before starting these tasks. Never guess formats without loading the skill first.

- **ADR / Plans**: Run `/writing-adr-plans` and follow its workflow and format. Keep Plans updated during implementation
- **Git commits**: Ensure the `commit` skill is loaded and follow Conventional Commits rules

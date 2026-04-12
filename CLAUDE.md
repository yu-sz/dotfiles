# CLAUDE.md

## Commands

```bash
nrs                # Apply Nix config changes (macOS: nh darwin switch, Linux: nh home switch)
```

Other tasks are managed by `just`. Run `just` to see all available recipes.

No tests or build system.

## Symlink Strategy

All configs follow the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/). New config files must be placed under `config/` and symlinked to `~/.config/`.

`config/*` → `~/.config/`

Special cases:

- `config/claude/*` → `~/.claude/`
- `config/zsh/.zshenv` → `~/.zshenv`

When adding files to `config/claude/`, also update `nix/home/symlinks.nix`.

## Multi-Machine Strategy

- `darwinConfigurations` in `flake.nix` manages per-host macOS configurations
- `homeConfigurations` in `flake.nix` manages standalone home-manager for Linux
- `specialArgs` passes `username` to absorb differences across machines
- Adding a new machine is automated by `scripts/bootstrap.sh`

## Nix Package Management

| Category              | macOS                                          | Linux                     |
| --------------------- | ---------------------------------------------- | ------------------------- |
| CLI tools (shared)    | `nix/home/default.nix`                         | ←                         |
| OS-specific tools     | `nix/home/darwin.nix`                          | `nix/home/linux.nix`      |
| GUI apps              | `nix/hosts/darwin-shared.nix` (homebrew.casks) | `nix/home/linux.nix`      |
| Fonts                 | `nix/hosts/darwin-shared.nix` (fonts.packages) | `nix/home/linux.nix`      |
| System packages (apt) | —                                              | `config/apt/packages.txt` |
| Custom packages       | `nix/overlays/`                                | ←                         |

## Nix Flake Workflow

- Nix flake only sees Git-tracked files. **Always `git add` after creating new files.**
- Run `git status` before `nrs` to check for untracked files.
- When introducing new tools: add package and apply first, then switch configs. Never reference uninstalled tools.
- `nrs` requires sudo on macOS (`nh darwin switch`). Do not run directly — ask the user to run `! nrs` instead.
- `.zshenv` has `unsetopt GLOBAL_RCS`, so HM's `hm-session-vars.sh` is never sourced. Environment variables set via `home.sessionVariables` won't work — use explicit paths instead.

## Lua Config Files

All Lua configs (Neovim, WezTerm, Yazi): module pattern with LuaCATS annotations, `snake_case` naming.

## Skills

Always load the corresponding skill before starting these tasks. Never guess formats without loading the skill first.

- **ADR / Plans**: Run `/writing-adr-plans` and follow its workflow and format. Keep Plans updated during implementation

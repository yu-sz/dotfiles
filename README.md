# Dotfiles

Personal config for macOS (Apple Silicon). Managed with Nix (nix-darwin + home-manager).

## Setup

1. Prepare local files:
   - `config/git/config.local` (git auth info)
   - `config/mise/config.toml` (runtime versions)

2. Run:

   ```bash
   ./scripts/install.sh
   ```

Note: Raycast settings must be configured manually.

## Managing Packages

| What | Where |
|---|---|
| CLI tools | `nix/home/default.nix` (`home.packages`) |
| macOS-only tools | `nix/home/darwin.nix` |
| GUI apps (cask) | `nix/hosts/darwin-shared.nix` (`homebrew.casks`) |
| Fonts | `nix/hosts/darwin-shared.nix` (`fonts.packages`) |
| Custom packages | `nix/overlays/` |
| Dotfile symlinks | `nix/home/symlinks.nix` |

After editing, apply with:

```bash
drs
```

## Maintenance

```bash
nix flake update    # Update all packages
drs                 # Apply config
nix-collect-garbage -d                                        # Garbage collect old generations
```

Shell aliases are available after setup: `drs` (darwin-rebuild switch), `ngc` (garbage collect), etc. See `config/zsh/lazy/nix.zsh`.

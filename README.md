# Dotfiles

Personal config for macOS (Apple Silicon). Managed with Nix (nix-darwin + home-manager).

> Linux (standalone home-manager) is scaffolded but not yet active. See `flake.nix`.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/yu-sz/dotfiles/main/scripts/bootstrap.sh | bash
```

### Post-install (manual)

- Create `config/mise/config.toml` with runtime versions and run `mise install`
- Configure Raycast manually

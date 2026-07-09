# Dotfiles

Personal config for macOS and Linux. Managed with Nix (nix-darwin + home-manager).

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/yu-sz/dotfiles/main/scripts/bootstrap.sh | bash
```

### Post-install (manual)

- Run `mise install` to install runtimes (`config/mise/config.toml` is tracked in this repo)
- Configure Raycast manually (see [docs/raycast.md](docs/raycast.md))

## Documentation

- [CLAUDE.md](CLAUDE.md) — repo conventions (symlink strategy, package management)
- [docs/adr/](docs/adr/) — architecture decision records
- [docs/plans/](docs/plans/) — implementation plans

# Dotfiles

Personal config for macOS (Apple Silicon). Managed with Nix (nix-darwin + home-manager).

> Linux (standalone home-manager) is scaffolded but not yet active. See `flake.nix`.

## Setup

### New Mac

```bash
curl -fsSL https://raw.githubusercontent.com/yu-sz/dotfiles/main/scripts/bootstrap.sh | bash
```

### Existing clone

```bash
./scripts/install.sh
```

### Post-install (manual)

- `config/mise/config.toml` を作成してランタイムバージョンを設定し `mise install`
- Raycast は手動設定

### Adding a new machine

`bootstrap.sh` が自動でホスト名を検出し `flake.nix` にエントリを追加する。手動で追加する場合:

```nix
"<hostname>" = mkDarwinConfig { username = "<username>"; };
```

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

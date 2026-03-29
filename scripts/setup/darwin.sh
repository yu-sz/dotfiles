#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

REPO_DIR="${1:?Usage: darwin.sh <repo_dir>}"

# Homebrew (required by nix-homebrew for cask management)
if command -v brew &>/dev/null; then
  info "Homebrew is already installed."
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  info "Homebrew installed."
fi

# Ensure nix is in PATH
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Apply config
info "Applying config (darwin-rebuild switch)..."
# sudo 環境でも nix コマンドと正しい HOME を参照するために環境変数を引き継ぐ
sudo --preserve-env=PATH,HOME,USER \
  nix run nix-darwin -- switch --flake "${REPO_DIR}#suta-ro"
info "Config applied."

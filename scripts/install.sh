#!/usr/bin/env bash
set -eu # Exit on error, exit on unset variables, print commands

echo "--- Dotfiles Setup Started ---"

# Define script and repository paths
export CUR_DIR="$(
  cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
  pwd
)"
export REPO_DIR="$(
  cd "${CUR_DIR}/.." || exit 1
  pwd
)"

# Set XDG Base Directory Specification variables
# These default to ~/.config, ~/.local/share, ~/.local/state, ~/.cache if not already set.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Create XDG directories if they don't exist
mkdir -p \
  "$XDG_CONFIG_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$XDG_CACHE_HOME" \
  "$XDG_DATA_HOME/vim"
echo "XDG directories created."

# Homebrew Setup
echo "--- Starting Homebrew Setup ---"

# Check if Homebrew is installed. If not, install it.
if type brew >/dev/null; then
  echo "Homebrew is already installed."
else
  echo "Installing Homebrew..."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  echo "Homebrew installation complete."
fi

# Install applications and dependencies listed in Brewfile.
echo "Installing Homebrew apps from Brewfile..."
brew bundle install --file "${REPO_DIR}/config/homebrew/Brewfile" --verbose --no-upgrade

# Clean up Homebrew cache to free up space.
echo "Cleaning up Homebrew cache..."
brew cleanup

echo "Homebrew setup complete."

# mise setup and install
echo "--- Installing mise managed tools ---"
if command -v mise &>/dev/null; then
  # use config/mise/config.toml
  mise install
  echo "mise tools installed."
else
  echo "Warning: mise is not installed via Homebrew. Skipping mise tool installation."
fi

# Nix setup
echo "--- Nix Setup ---"
if command -v nix &>/dev/null; then
  echo "Nix is already installed."
else
  echo "Installing Nix (NixOS official installer)..."
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
  echo "Nix installation complete."
  echo "Please restart your shell and run this script again."
  exit 0
fi

echo "--- Dotfiles Setup Complete ---"
echo "✅ All environment configurations and tools have been installed."
echo ""
echo "Next: Run darwin-rebuild switch to apply Nix configuration:"
echo "  sudo nix run nix-darwin -- switch --flake ${REPO_DIR}#\$(scutil --get LocalHostName)"
echo ""
echo "🚀 To apply changes, please open a new terminal session or run 'exec zsh' in your current shell."
echo "💡 If you installed Neovim, open it to allow plugin manager to install plugins on first run."

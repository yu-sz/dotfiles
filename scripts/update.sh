#!/usr/bin/env bash
set -eux 

echo "--- Dotfiles Update Started ---"

# Get repo root directory
export REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1; pwd)"

# 1. Update Homebrew
echo "Updating Homebrew and its packages..."

brew update                                 # Update Homebrew formulae
brew upgrade                                # Upgrade all installed packages
brew bundle install --file "${REPO_DIR}/homebrew/Brewfile" --no-lock --verbose
brew cleanup                                # Remove old versions and clear cache
brew doctor                                 # Diagnose environment issues

echo "Homebrew update complete."

# 2. Update mise managed tools
echo "Updating mise managed tools..."

if command -v mise &> /dev/null; then
    mise install                            # Install/update tools based on global/project configs
    mise prune                              # Remove unused old versions
    echo "mise tools update complete."
else
    echo "mise is not installed. Skipping mise tools update."
fi

# 3. Update Zsh plugins (Sheldon)
echo "Updating Zsh plugins with Sheldon..."
if command -v sheldon &> /dev/null; then
    sheldon update                          # Update plugins based on sheldon.toml
    echo "Zsh plugins update complete."
else
    echo "Sheldon is not installed. Skipping Zsh plugin update."
fi

# 4. Update Neovim plugins
echo "Updating Neovim plugins..."
if command -v nvim &> /dev/null; then
    # Example for Lazy.nvim. Adjust for your plugin manager.
    nvim --headless "+Lazy! sync" +qa       # Run Neovim plugin sync in headless mode
    echo "Neovim plugins update complete."
else
    echo "Neovim is not installed. Skipping Neovim plugin update."
fi

echo "--- Dotfiles Update Complete ---"
echo "✅ All specified components updated."
echo "🚀 Open a new terminal session to apply changes."

#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/dotfiles"
DOTFILES_REPO="https://github.com/yu-sz/dotfiles.git"

info() { printf '\033[34m[INFO]\033[0m %s\n' "$*"; }

if [[ -d "${DOTFILES_DIR}/.git" ]]; then
  info "Dotfiles repo found. Pulling latest..."
  git -C "${DOTFILES_DIR}" pull --rebase || true
else
  info "Cloning dotfiles..."
  mkdir -p "$(dirname "${DOTFILES_DIR}")"
  git clone "${DOTFILES_REPO}" "${DOTFILES_DIR}"
fi

# git config.local の生成（初回のみ）
GIT_CONFIG_LOCAL="${DOTFILES_DIR}/config/git/config.local"
if [[ ! -f "${GIT_CONFIG_LOCAL}" ]]; then
  info "Setting up git config.local..."
  read -rp "Git user.name: " git_name < /dev/tty
  read -rp "Git user.email: " git_email < /dev/tty
  git config --file "${GIT_CONFIG_LOCAL}" user.name "${git_name}"
  git config --file "${GIT_CONFIG_LOCAL}" user.email "${git_email}"
  info "git config.local created."
fi

# darwinConfiguration の自動追加
if [[ "$(uname -s)" == "Darwin" ]]; then
  HOSTNAME="$(scutil --get LocalHostName)"
  USERNAME="$(whoami)"
  if ! grep -q "\"${HOSTNAME}\"" "${DOTFILES_DIR}/flake.nix"; then
    info "Adding darwinConfiguration for ${HOSTNAME}..."
    FLAKE="${DOTFILES_DIR}/flake.nix"
    TMP="$(mktemp)"
    sed "/darwinConfigurations = {/a\\
\\        \"${HOSTNAME}\" = mkDarwinConfig { username = \"${USERNAME}\"; };" \
      "${FLAKE}" > "${TMP}"
    if mv "${TMP}" "${FLAKE}"; then :; else rm -f "${TMP}"; fi
    git -C "${DOTFILES_DIR}" add flake.nix
  fi
fi

exec "${DOTFILES_DIR}/scripts/install.sh"

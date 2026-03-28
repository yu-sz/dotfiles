#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

REPO_DIR="${1:?Usage: linux.sh <repo_dir>}"

# NOTE: flake.nix の homeConfigurations がコメントアウト状態の場合、
# nix run home-manager が失敗する。先に flake.nix を更新すること。

# Ensure nix is in PATH
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Apply config
USERNAME="$(whoami)"
HOSTNAME="$(hostname)"
info "Applying config for ${USERNAME}@${HOSTNAME} (home-manager switch)..."
nix run home-manager -- switch --flake "${REPO_DIR}#${USERNAME}@${HOSTNAME}"
info "Config applied."

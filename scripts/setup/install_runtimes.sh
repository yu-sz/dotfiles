#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

# Ensure nix is in PATH
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# apply_config 後に Nix per-user profile を PATH に追加
# (親プロセスからPATHは継承されるが、per-user profileはapply_config後に作られる)
NIX_PROFILE="/etc/profiles/per-user/${USER}/bin"
if [[ -d "${NIX_PROFILE}" && ":${PATH}:" != *":${NIX_PROFILE}:"* ]]; then
  export PATH="${NIX_PROFILE}:${PATH}"
fi

if ! command -v mise &>/dev/null; then
  warn "mise not found. Skipping runtime install."
  exit 0
fi

info "Installing runtimes via mise..."
mise install
info "Runtimes installed."

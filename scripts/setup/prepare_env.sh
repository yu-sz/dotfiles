source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"

create_directories() {
  mkdir -p \
    "${XDG_CONFIG_HOME:-$HOME/.config}" \
    "${XDG_DATA_HOME:-$HOME/.local/share}" \
    "${XDG_STATE_HOME:-$HOME/.local/state}" \
    "${XDG_CACHE_HOME:-$HOME/.cache}" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/vim"
  info "XDG directories created."
}

install_nix() {
  if command -v nix &>/dev/null; then
    info "Nix is already installed."
    return
  fi
  info "Installing Nix..."
  curl -fSL https://artifacts.nixos.org/nix-installer | sh -s -- install
  info "Nix installed."
}

load_nix_env() {
  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  if ! command -v nix &>/dev/null; then
    error "nix command not found after sourcing nix-daemon.sh"
    exit 1
  fi
}

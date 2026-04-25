#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SETUP="${SCRIPT_DIR}/setup"
OS="$(uname -s)"

trap 'printf "\033[31m[ERROR]\033[0m Failed at line %s.\n" "${LINENO}" >&2' ERR

source "${SETUP}/_helpers.sh"
source "${SETUP}/prepare_env.sh"

info "Dotfiles setup started (${OS})."

create_directories
install_nix
load_nix_env

case "${OS}" in
Darwin) "${SETUP}/darwin.sh" "${REPO_DIR}" ;;
Linux) "${SETUP}/linux.sh" "${REPO_DIR}" ;;
*)
	error "Unsupported OS: ${OS}"
	exit 1
	;;
esac

install_mise

"${SETUP}/install_runtimes.sh"

info "Dotfiles setup complete."

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="${SCRIPT_DIR}/../config/apt/packages.txt"

if [[ "$(uname -s)" != "Linux" ]]; then
	echo "apt-sync: skipping on non-Linux" >&2
	exit 0
fi

if [[ ! -f "${PACKAGES_FILE}" ]]; then
	echo "apt-sync: ${PACKAGES_FILE} not found" >&2
	exit 1
fi

# Read package list (ignore comments and blank lines)
mapfile -t packages < <(grep -v '^\s*#' "${PACKAGES_FILE}" | grep -v '^\s*$')

if [[ ${#packages[@]} -eq 0 ]]; then
	echo "apt-sync: no packages to install"
	exit 0
fi

# Find packages not yet installed
missing=()
for pkg in "${packages[@]}"; do
	if ! dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q "install ok installed"; then
		missing+=("${pkg}")
	fi
done

if [[ ${#missing[@]} -eq 0 ]]; then
	echo "apt-sync: all packages already installed"
	exit 0
fi

echo "apt-sync: installing ${missing[*]}"
sudo apt-get update -qq
sudo apt-get install -y "${missing[@]}"

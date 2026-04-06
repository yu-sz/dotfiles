#!/usr/bin/env bash
set -uo pipefail

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

EXT="${FILE_PATH##*.}"

case "$EXT" in
lua)
	command -v stylua &>/dev/null && stylua "$FILE_PATH"
	;;
nix)
	command -v nixfmt &>/dev/null && nixfmt "$FILE_PATH"
	;;
sh | zsh)
	command -v shfmt &>/dev/null && shfmt -w "$FILE_PATH"
	;;
md | json | jsonc | yaml | yml)
	command -v prettier &>/dev/null && prettier --ignore-path '' --write "$FILE_PATH" 2>/dev/null
	;;
esac

exit 0

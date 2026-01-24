#!/bin/zsh
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

EXT="${FILE_PATH##*.}"

detect_web_formatter() {
	local dir="${1:h}"
	while [[ "$dir" != "/" && "$dir" != "$HOME" ]]; do
		[[ -f "$dir/biome.json" || -f "$dir/biome.jsonc" ]] && {
			echo "biome"
			return
		}
		[[ -f "$dir/.prettierrc" || -f "$dir/.prettierrc.json" ||
			-f "$dir/.prettierrc.yaml" || -f "$dir/.prettierrc.yml" ||
			-f "$dir/.prettierrc.js" || -f "$dir/.prettierrc.cjs" ||
			-f "$dir/prettier.config.js" || -f "$dir/prettier.config.cjs" ]] && {
			echo "prettier"
			return
		}
		dir="${dir:h}"
	done
	echo "biome"
}

ERRORS=""

case "$EXT" in
lua)
	command -v luacheck &>/dev/null && ERRORS=$(luacheck "$FILE_PATH" --no-color 2>&1) || true
	command -v stylua &>/dev/null && stylua "$FILE_PATH"
	;;
sh | bash | zsh)
	command -v shfmt &>/dev/null && shfmt -w "$FILE_PATH"
	;;
ts | tsx | js | jsx)
	FORMATTER=$(detect_web_formatter "$FILE_PATH")
	if [[ "$FORMATTER" == "biome" ]]; then
		command -v biome &>/dev/null && {
			ERRORS=$(biome lint "$FILE_PATH" 2>&1) || true
			biome check --write "$FILE_PATH" 2>/dev/null
		}
	else
		command -v eslint &>/dev/null && { ERRORS=$(eslint "$FILE_PATH" 2>&1) || true; }
		command -v prettier &>/dev/null && prettier --write "$FILE_PATH" 2>/dev/null
	fi
	;;
html | css | scss | less | json | jsonc)
	FORMATTER=$(detect_web_formatter "$FILE_PATH")
	if [[ "$FORMATTER" == "biome" ]]; then
		command -v biome &>/dev/null && biome check --write "$FILE_PATH" 2>/dev/null
	else
		command -v prettier &>/dev/null && prettier --write "$FILE_PATH" 2>/dev/null
	fi
	;;
yaml | yml | md | mdx)
	command -v prettier &>/dev/null && prettier --write "$FILE_PATH" 2>/dev/null
	;;
esac

if [[ -n "$ERRORS" ]]; then
	echo "$ERRORS" >&2
	exit 2
fi

exit 0

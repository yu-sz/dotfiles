#!/bin/bash
#
# PreToolUse hook: パイプ付きコマンドの自動承認
# パイプ/&&/;/|| で分割し、各ステージが settings.json の allow リストに
# マッチすれば自動承認する。1つでも NG ならフォールスルー。

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# パイプ等を含まない場合はフォールスルー（permissions.allow が処理）
echo "$COMMAND" | grep -qE '[|;]|&&' || exit 0

# 危険な環境変数を含む場合はフォールスルー
SENSITIVE_PATTERNS='(^|[;&|]\s*)(PATH|LD_PRELOAD|LD_LIBRARY_PATH|DYLD_LIBRARY_PATH|DYLD_INSERT_LIBRARIES|PYTHONPATH|PYTHONHOME|NODE_PATH|GEM_PATH|GEM_HOME|RUBYLIB|PERL5LIB|CLASSPATH|GOPATH)='
echo "$COMMAND" | grep -qE "$SENSITIVE_PATTERNS" && exit 0

SETTINGS="$HOME/.claude/settings.json"
[ ! -f "$SETTINGS" ] && exit 0

# settings.json から allow リストの Bash プレフィックスを抽出
ALLOWED_PREFIXES=()
while IFS= read -r line; do
	[ -n "$line" ] && ALLOWED_PREFIXES+=("$line")
done < <(
	jq -r '.permissions.allow[]? // empty' "$SETTINGS" |
		grep '^Bash(' |
		sed -n 's/^Bash(\(.*\))$/\1/p' |
		sed 's/:*\*$//' |
		sed 's/ \*$//' |
		sort -u
)

[ ${#ALLOWED_PREFIXES[@]} -eq 0 ] && exit 0

matches_allowed() {
	local cmd="$1"
	cmd="$(echo "$cmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"

	# 環境変数プレフィックスを除去 (e.g. CC=gcc make → make)
	while [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
		if [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*=\"[^\"]*\"[[:space:]]+(.*) ]]; then
			cmd="${BASH_REMATCH[1]}"
		elif [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*=\'[^\']*\'[[:space:]]+(.*) ]]; then
			cmd="${BASH_REMATCH[1]}"
		elif [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*) ]]; then
			cmd="${BASH_REMATCH[1]}"
		else
			break
		fi
	done

	for prefix in "${ALLOWED_PREFIXES[@]}"; do
		if [[ "$cmd" == "$prefix" || "$cmd" == "$prefix "* ]]; then
			return 0
		fi
	done
	return 1
}

# クォート考慮のコマンド分割
split_stages() {
	local cmd="$1"
	local len=${#cmd}
	local i=0
	local sq=false
	local dq=false
	local current=""

	while [ "$i" -lt "$len" ]; do
		local c="${cmd:$i:1}"
		local next="${cmd:$((i + 1)):1}"

		# バックスラッシュエスケープ
		if [ "$c" = "\\" ] && ! $sq; then
			current+="$c$next"
			((i += 2))
			continue
		fi

		# シングルクォートの開閉
		if [ "$c" = "'" ] && ! $dq; then
			if $sq; then sq=false; else sq=true; fi
			current+="$c"
			((i++))
			continue
		fi

		# ダブルクォートの開閉
		if [ "$c" = '"' ] && ! $sq; then
			if $dq; then dq=false; else dq=true; fi
			current+="$c"
			((i++))
			continue
		fi

		# クォートの外にいる場合のみ、演算子で分割
		if ! $sq && ! $dq; then
			if [ "$c" = "|" ] && [ "$next" != "|" ]; then
				printf '%s\n' "$current"
				current=""
				((i++))
				continue
			fi
			if [ "$c" = "|" ] && [ "$next" = "|" ]; then
				printf '%s\n' "$current"
				current=""
				((i += 2))
				continue
			fi
			if [ "$c" = ";" ]; then
				printf '%s\n' "$current"
				current=""
				((i++))
				continue
			fi
			if [ "$c" = "&" ] && [ "$next" = "&" ]; then
				printf '%s\n' "$current"
				current=""
				((i += 2))
				continue
			fi
		fi

		current+="$c"
		((i++))
	done
	[ -n "$current" ] && printf '%s\n' "$current"
}

STAGES=()
while IFS= read -r seg; do
	[ -n "$seg" ] && STAGES+=("$seg")
done < <(split_stages "$COMMAND")

for stage in "${STAGES[@]}"; do
	# リダイレクトとコメント行を除去
	clean="$(echo "$stage" |
		sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' |
		sed 's/[0-9]*>&[0-9]*//g' |
		sed 's/[0-9]*>[>&]*[[:space:]]*[^ ]*//g' |
		sed 's/^[[:space:]]*//' |
		sed 's/[[:space:]]*$//')"

	[ -z "$clean" ] && continue

	if ! matches_allowed "$clean"; then
		exit 0
	fi
done

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    permissionDecisionReason: "All pipeline stages match allowed Bash prefixes"
  }
}'

exit 0

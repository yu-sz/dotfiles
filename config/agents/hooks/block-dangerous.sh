#!/bin/sh
# 危険コマンドを実行前に止める。Claude / Codex / Gemini 共通の hook。
# stdin に hook の JSON を受け取り、.tool_input.command がパターンに当たれば exit 2 で拒否する
# （3 エージェントとも exit 2 + stderr をブロック理由として扱う）
set -eu

PATH="/etc/profiles/per-user/${USER}/bin:${HOME}/.nix-profile/bin:$PATH"
command -v jq >/dev/null 2>&1 || exit 0

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# rm の再帰強制削除、dd による書き込み、fork bomb
pattern='rm +-[A-Za-z]*([rR][A-Za-z]*[fF]|[fF][A-Za-z]*[rR])|dd +if=|:\(\)\{ *:\|:& *\};:'
if printf '%s' "$cmd" | grep -Eq "$pattern"; then
	echo "危険なコマンドは実行できません。別の方法を検討してください。" >&2
	exit 2
fi
exit 0

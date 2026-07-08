#!/bin/sh
# Claude Code hooks から herdr へ agent 状態を明示報告する
# (`pane.agent_status_changed` が emit され sketchybar が push 更新される)。
# Sidekick の nvim split で claude が動く間、herdr のネイティブ検知は
# 前面プロセス (nvim) しか見えないため hook からの報告で補完する。
set -eu

state="${1:?usage: report-herdr-state.sh <idle|working|blocked|unknown>}"

cat >/dev/null 2>&1 || true

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0

# nix-darwin / NixOS は /etc/profiles、standalone home-manager は ~/.nix-profile
PATH="/etc/profiles/per-user/${USER}/bin:${HOME}/.nix-profile/bin:$PATH"
command -v herdr >/dev/null 2>&1 || exit 0

herdr pane report-agent "$HERDR_PANE_ID" \
	--source claude-hook --agent claude --state "$state" >/dev/null 2>&1 || true

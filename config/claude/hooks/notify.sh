#!/bin/bash

command -v terminal-notifier >/dev/null 2>&1 || exit 0

# stdin を消費（hook input JSON）
cat >/dev/null

MESSAGE="${1:-Claude Codeからの通知}"

# Git リポジトリ名とブランチ名を取得
REPO_NAME=""
BRANCH_NAME=""
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null)
  BRANCH_NAME=$(git branch --show-current 2>/dev/null)
fi

# サブタイトルを構築
if [ -n "$REPO_NAME" ] && [ -n "$BRANCH_NAME" ]; then
  SUBTITLE="$REPO_NAME ($BRANCH_NAME)"
elif [ -n "$REPO_NAME" ]; then
  SUBTITLE="$REPO_NAME"
else
  SUBTITLE=$(basename "$PWD")
fi

terminal-notifier \
  -title "⚡️ Claude Code" \
  -subtitle "$SUBTITLE" \
  -message "$MESSAGE" \
  -sound "default" \
  -group "claude-code"

exit 0

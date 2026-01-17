#!/bin/bash
query=$(cat | jq -r '.query')
cd "$CLAUDE_PROJECT_DIR" || exit
fd --hidden | fzf --filter="$query" | head -20

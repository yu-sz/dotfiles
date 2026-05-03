#!/bin/bash
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# current_usage is an object: sum input + output + cache_creation + cache_read
CURRENT_USAGE=$(echo "$input" | jq -r '
  (.context_window.current_usage // {}) as $u |
  (($u.input_tokens // 0) + ($u.output_tokens // 0) +
   ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0))
')
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
USED_PERCENT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
CTX_K=$((CURRENT_USAGE / 1000))
CTX_MAX_K=$((CTX_SIZE / 1000))

API_DURATION_MS=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
API_DURATION_S=$(echo "scale=1; $API_DURATION_MS / 1000" | bc)

EFFORT=$(echo "$input" | jq -r '.effort.level // "-"')

# Format: [Model] effort:xxx | 📁 dir | Context: XXk/XXXk (XX.X%) | X.Xs
echo "[$MODEL_DISPLAY] effort:${EFFORT} | 📁 ${CURRENT_DIR##*/} | Context: ${CTX_K}k/${CTX_MAX_K}k (${USED_PERCENT}%) | ${API_DURATION_S}s"

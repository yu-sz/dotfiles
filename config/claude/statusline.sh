#!/bin/bash
# Read JSON input from stdin
input=$(cat)

# Extract values using jq
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# Token usage information
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
USED_PERCENT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
API_DURATION_MS=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')

# Calculate token counts (in thousands)
INPUT_K=$((INPUT_TOKENS / 1000))
OUTPUT_K=$((OUTPUT_TOKENS / 1000))

# Convert ms to seconds (with one decimal)
API_DURATION_S=$(echo "scale=1; $API_DURATION_MS / 1000" | bc)

# Format: [Model] 📁 dir | XXk/XXk tokens | Context: XX.X% | X.Xs
echo "[$MODEL_DISPLAY] 📁 ${CURRENT_DIR##*/} | ${INPUT_K}k/${OUTPUT_K}k tokens | Context: ${USED_PERCENT}% | ${API_DURATION_S}s"

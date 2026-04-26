#!/usr/bin/env bash
set -euo pipefail

big="${1:-2}"
small="${2:-1}"

aerospace balance-sizes
sleep 0.2

focused_size=$(osascript -e '
tell application "System Events"
    tell (first application process whose frontmost is true)
        return size of window 1
    end tell
end tell')
focused_w="${focused_size%%,*}"
focused_w="${focused_w// /}"

total=$((focused_w * 2))
delta=$((total * (big - small) / (2 * (big + small))))

aerospace resize smart "+$delta"

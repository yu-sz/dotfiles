#!/usr/bin/env bash
set -euo pipefail

aerospace move-workspace-to-monitor --workspace 1 secondary 2>/dev/null || true
aerospace move-workspace-to-monitor --workspace 3 secondary 2>/dev/null || true
aerospace workspace 2

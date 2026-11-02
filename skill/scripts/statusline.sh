#!/usr/bin/env bash
# A status line for Claude Code that also saves usage for /nightshift: model, context use and
# the 5-hour window, for example "Opus  ctx 34%  5h 62%". Needs jq.
input=$(cat)
echo "$input" | "$(dirname "$0")/save-usage.sh"
echo "$input" | jq -r '
  "\(.model.display_name // "Claude")  ctx \((.context_window.used_percentage // 0) | floor)%"
  + (if .rate_limits.five_hour.used_percentage then "  5h \(.rate_limits.five_hour.used_percentage | floor)%" else "" end)'

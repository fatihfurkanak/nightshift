#!/usr/bin/env bash
# Saves the usage windows Claude Code hands the status line (claude.ai Pro, Max and Ultra
# plans) so /nightshift can pause at 85% of the 5-hour window. Reads the status line JSON on
# stdin, prints nothing. Call it from your own status line script if you already have one:
#   echo "$input" | ~/.claude/skills/nightshift/scripts/save-usage.sh
# Needs jq.
set -u
input=$(cat)
dir="${CLAUDE_NIGHTSHIFT_DIR:-$HOME/.claude/nightshift}"
mkdir -p "$dir" 2>/dev/null || exit 0
# Absent before the first reply of a session and on plans without usage windows: keep the
# last reading rather than overwrite it with nothing.
echo "$input" | jq -e '.rate_limits.five_hour // .rate_limits.seven_day' >/dev/null 2>&1 || exit 0
tmp="$dir/usage.json.$$"
echo "$input" | jq -c --argjson now "$(date +%s)" \
  '{saved_at: $now, five_hour: .rate_limits.five_hour, seven_day: .rate_limits.seven_day}' > "$tmp" 2>/dev/null \
  && mv "$tmp" "$dir/usage.json"
rm -f "$tmp"
exit 0

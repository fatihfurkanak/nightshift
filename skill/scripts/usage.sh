#!/usr/bin/env bash
# Prints the last usage reading the status line saved, one key=value per line, for /nightshift:
#   five_hour_pct, five_hour_resets_at (epoch), five_hour_resets_local (HH:MM),
#   seven_day_pct, age_seconds
# A window whose reset time has passed reads 0. Exit 2 with "no-data" when nothing is saved.
f="${CLAUDE_NIGHTSHIFT_DIR:-$HOME/.claude/nightshift}/usage.json"
if [ ! -s "$f" ]; then
  echo "no-data: the status line has not saved usage yet (see the nightshift README), or this plan has no usage windows"
  exit 2
fi
jq -r --argjson now "$(date +%s)" '
  def pct(w): if w == null then "unknown" elif (w.resets_at // 0) <= $now then 0 else w.used_percentage end;
  "five_hour_pct=\(pct(.five_hour))",
  "five_hour_resets_at=\(.five_hour.resets_at // "unknown")",
  "five_hour_resets_local=\(if .five_hour.resets_at then (.five_hour.resets_at | strflocaltime("%H:%M")) else "unknown" end)",
  "seven_day_pct=\(pct(.seven_day))",
  "age_seconds=\($now - .saved_at)"' "$f"

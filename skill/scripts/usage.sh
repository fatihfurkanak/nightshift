#!/usr/bin/env bash
# The last usage reading the status line saved, for /nightshift. Needs jq.
#
#   usage.sh
#     five_hour_pct, five_hour_resets_at (epoch), five_hour_resets_local (HH:MM),
#     seven_day_pct, age_seconds; a window whose reset time has passed reads 0.
#
#   usage.sh --check <wake_up_epoch> <seven_day_pct_at_start>
#     action=work|break|stop with the reason, the limit in force and, for a break, when to
#     come back. The rules: a break at 80% of the 5-hour window, at 70% for the window that
#     runs past the wake-up time (30% stays for the morning), and a stop for the night at
#     95% of the 7-day window or once the night has used 15 points of it.
#
# Exit 2 with "no-data" (or action=work, reason=no-data, with --check) when nothing is saved.
f="${CLAUDE_NIGHTSHIFT_DIR:-$HOME/.claude/nightshift}/usage.json"
BREAK_AT=80 MORNING_BREAK_AT=70 WEEK_STOP_AT=95 NIGHT_WEEK_SHARE=15 STALE_AFTER=900

if [ "${1:-}" = --check ]; then
  wake=${2:?wake-up time (epoch seconds) needed} start7=${3:?7-day percentage at the start needed}
  if [ ! -s "$f" ]; then echo "action=work"; echo "reason=no-data"; exit 2; fi
  jq -r --argjson now "$(date +%s)" --argjson wake "$wake" --argjson start7 "$start7" \
    --argjson brk "$BREAK_AT" --argjson mbrk "$MORNING_BREAK_AT" --argjson wstop "$WEEK_STOP_AT" \
    --argjson share "$NIGHT_WEEK_SHARE" --argjson stale "$STALE_AFTER" '
    def live(w): w != null and (w.resets_at // 0) > $now;
    (if live(.five_hour) then .five_hour.used_percentage else 0 end) as $p5
    | (if live(.seven_day) then .seven_day.used_percentage else null end) as $p7
    | (if live(.five_hour) and .five_hour.resets_at > $wake then $mbrk else $brk end) as $limit
    | ($now - .saved_at) as $age
    | if $age > $stale then ["action=work", "reason=stale-reading", "age_seconds=\($age)"]
      elif $p7 != null and $p7 >= $wstop then ["action=stop", "reason=7-day-window-at-\($p7)"]
      elif $p7 != null and ($p7 - $start7) >= $share then ["action=stop", "reason=night-used-\($p7 - $start7)-points-of-7-day"]
      elif $p5 >= $limit then
        ["action=break", "reason=5-hour-window-at-\($p5)", "limit=\($limit)",
         "resume_at=\(.five_hour.resets_at + 120)", "resume_local=\((.five_hour.resets_at + 120) | strflocaltime("%H:%M"))"]
      else ["action=work", "five_hour_pct=\($p5)", "limit=\($limit)", "seven_day_pct=\($p7 // "unknown")"]
      end | .[]' "$f"
  exit 0
fi

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

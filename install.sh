#!/usr/bin/env bash
# Installs /nightshift for Claude Code: the skill into ~/.claude/skills/nightshift and, when no
# status line is set yet, the status line that saves usage for it (with a backup of the
# settings file). An existing status line is left alone; the line to add to it is printed.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
dest="$HOME/.claude/skills/nightshift"
settings="$HOME/.claude/settings.json"

command -v jq >/dev/null || { echo "jq is needed: brew install jq (macOS) or apt install jq"; exit 1; }

mkdir -p "$dest"
cp -R "$here/skill/." "$dest/"
chmod +x "$dest/scripts/"*.sh
echo "Skill installed: $dest"

[ -f "$settings" ] || echo '{}' > "$settings"
current=$(jq -r '.statusLine.command // empty' "$settings")
if [ -z "$current" ]; then
  cp "$settings" "$settings.bak-nightshift"
  jq --arg cmd "$dest/scripts/statusline.sh" '.statusLine = {type: "command", command: $cmd}' "$settings" > "$settings.tmp"
  mv "$settings.tmp" "$settings"
  echo "Status line set (settings backup: $settings.bak-nightshift)."
elif [ "$current" = "$dest/scripts/statusline.sh" ]; then
  echo "Status line already in place."
else
  echo "You already have a status line ($current). Add this line to it, after it reads stdin into \$input:"
  echo "  echo \"\$input\" | $dest/scripts/save-usage.sh"
fi
echo "Done. Open Claude Code in a terminal and type /nightshift."

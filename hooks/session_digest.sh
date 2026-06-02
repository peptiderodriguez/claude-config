#!/bin/bash
# SessionEnd hook: append a one-line session digest to today's Obsidian daily note.
# V1: timestamp, cwd-basename, last commit, session-id-short. User fills in detail manually if useful.
# If too noisy (many short sessions piling up), edit this script to add a duration gate.

vault=~/data/code/obsidian_base
[ ! -d "$vault" ] && exit 0

today=$(date +'%A %B %-d %Y')
note="$vault/$today.md"

cwd=$(pwd)
proj=$(basename "$cwd")
ts=$(date +'%H:%M')

last_commit=$(cd "$cwd" 2>/dev/null && git log -1 --format='%h %s' 2>/dev/null | head -c 80)
[ -z "$last_commit" ] && last_commit="(no git)"

sid=$(jq -r '.session_id // "unknown"' 2>/dev/null | head -c 8)

# Ensure note exists + has the section
if [ ! -f "$note" ]; then
  printf '# %s\n\n## Session digests\n\n' "$today" > "$note"
elif ! grep -q '^## Session digests' "$note"; then
  printf '\n## Session digests\n\n' >> "$note"
fi

printf -- '- %s  %s  [%s]  %s\n' "$ts" "$proj" "$sid" "$last_commit" >> "$note"

exit 0

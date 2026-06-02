#!/bin/bash
# PostCompact hook: inject a brief resume checklist into context after compaction.
# The fuller orientation is the /orient skill; this is the silent nudge.

cwd=$(pwd)
project_name=$(basename "$cwd")

recent_commits=$(cd "$cwd" 2>/dev/null && git log -3 --oneline 2>/dev/null || echo "(no git)")

cluster=""
if command -v squeue >/dev/null 2>&1; then
  q=$(squeue -u "$USER" -h --format='%i %T %M' 2>/dev/null | head -5)
  [ -n "$q" ] && cluster=$'\n'"SLURM (top 5):"$'\n'"$q"
fi

ctx=$(printf 'Session resumed from compaction.\nCwd: %s (%s)\nRecent commits:\n%s%s\n\nIf the user'\''s next prompt is orientation-style ("where were we?", "what was I doing?", "ok where are we then?"), invoke the /orient skill for a full state report. Otherwise proceed with their actual request — they may have already re-oriented.' "$cwd" "$project_name" "$recent_commits" "$cluster")

jq -nc --arg ctx "$ctx" '{hookSpecificOutput:{hookEventName:"PostCompact",additionalContext:$ctx}}'

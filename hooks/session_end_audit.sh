#!/bin/bash
# SessionEnd hook: scan today's daily note for stakes-pin or new-class-delegation
# tokens that fired during this session window. If found, append a marker
# suggesting a frame-auditor pass next time. Light-touch, no agent dispatch
# (SessionEnd is terminal — context injection has no consumer).

DAILY_DIR="__CLAUDE_HOME__/data/code/obsidian_base"
[ ! -d "$DAILY_DIR" ] && exit 0

# macOS date doesn't honor %-d reliably; strip leading zero with sed
day_label=$(date +'%A %B %d %Y' | sed 's/  */ /g; s/ 0/ /')
DAILY="$DAILY_DIR/$day_label.md"
[ ! -f "$DAILY" ] && exit 0

# Trigger patterns: stakes-pin phrases + delegation-into-new-class signals
if grep -iqE '(above all|we want.*funded|non-negotiable|must work|shipping.*(today|tomorrow|friday|monday|tuesday|wednesday|thursday|saturday|sunday)|use agents|launch.*(agents|adversarial|reviewers))' "$DAILY"; then

  # Don't double-append if already flagged today
  if ! grep -qF "frame-auditor: stakes-pin or delegation tokens detected" "$DAILY"; then
    {
      echo ""
      echo "- ⚠ frame-auditor: stakes-pin or delegation tokens detected this session. Consider running \`Agent(subagent_type: \"frame-auditor\", ...)\` over the transcript to verify CLAUDE.md:50 (stakes-flip-side) and CLAUDE.md:51 (delegation-outpaces-scaffolding) compliance."
    } >> "$DAILY"
  fi
fi

exit 0

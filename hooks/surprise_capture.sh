#!/bin/bash
# UserPromptSubmit hook: detect surprise/curiosity tokens in the user's message
# and nudge Claude (via additionalContext) to offer durable-memory capture.
# Patterns kept high-signal to minimize false-positives on filler "interesting".

# Read prompt — UserPromptSubmit hook places it in various possible fields depending on Claude Code version.
prompt=$(jq -r '.prompt // .user_message // .message // .content // empty' 2>/dev/null | head -c 500)

# Exit silently if nothing parsed
[ -z "$prompt" ] && exit 0

# High-signal surprise/curiosity patterns
# - Standalone "huh" / "huh!" / "huh?"
# - "wait what" / "wait, what" / "wait why"
# - "aha" / "TIL"
# - "didn't know" / "didn't expect"
# - "not what i expected"
# - "that's weird" / "that's odd" / "that's strange"
# - "huh interesting" (the combo)
# - "i didn't know that" / "i had no idea"

if printf '%s' "$prompt" | grep -iqE '(\bhuh[!?.]?(\s|$)|\bwait[, ]+(what|why)|\baha\b|\bTIL\b|\bdidn'\''?t (know|expect|realize)|\bnot what i expected|\bthat('\''?s| is) (weird|odd|strange|surprising|unexpected)|\bi had no idea|\bsurprising(ly)?\b|\bunexpected\b|\bnever knew\b|\bcounter[- ]intuitive)'; then
  jq -nc '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:"SIGNAL: user'\''s message contains a surprise/curiosity token. After answering the substance of their question/task, ONCE briefly offer to capture this insight as durable memory (one-line offer like \"want me to save this as a note for future sessions?\"). If they accept, ask whether it goes in ~/.claude/CLAUDE.md (global), this project'\''s CLAUDE.md (project), or a memory file. If they decline or move on, drop the offer — do not repeat."}}'
fi

exit 0

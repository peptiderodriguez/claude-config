#!/bin/bash
# PostToolUse hook on Skill: after /critique runs, nudge Claude to invoke
# dissent-auditor over the N parallel-agent outputs before final synthesis.
# Belt-and-suspenders companion to the explicit step 5.5 in critique.md.

input=$(cat)

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool" != "Skill" ] && exit 0

skill=$(printf '%s' "$input" | jq -r '.tool_input.skill // empty' 2>/dev/null)
[ "$skill" != "critique" ] && exit 0

jq -nc '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:"REMINDER: /critique just completed. Before finalizing the synthesis to the user, invoke Agent(subagent_type: \"dissent-auditor\", ...) over the N raw adversarial agent outputs. If it returns partial or converged, prepend a ## Dissent check block to your synthesis. If independent, suppress. This is the auto-fire step 5.5 from critique.md."}}'

exit 0

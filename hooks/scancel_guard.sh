#!/bin/bash
# PreToolUse hook on Bash: block `scancel -u <something>` (destructive across cubes).
# All other Bash commands pass through unchanged.

cmd=$(jq -r '.tool_input.command // empty')

# Match `scancel -u` as a separate token. Allow `scancel <jobid>` and any other scancel form.
if printf '%s\n' "$cmd" | grep -qE '(^|[[:space:];&|])scancel[[:space:]]+-u(\b|[[:space:]=])'; then
  jq -nc --arg reason 'Blocked: `scancel -u` is destructive across cubes (past incident wiped a 7-hour library-gen). Cancel by explicit job-id list instead: `scancel <jobid1> <jobid2> ...`. To override this guard intentionally, edit ~/.claude/hooks/scancel_guard.sh.' \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
fi

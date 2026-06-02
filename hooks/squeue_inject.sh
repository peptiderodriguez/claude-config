#!/bin/bash
# UserPromptSubmit hook: inject squeue snapshot into Claude's context when on a SLURM host.
# Silent no-op when squeue is missing (e.g., Mac) or no jobs exist.

command -v squeue >/dev/null 2>&1 || exit 0

out=$(squeue -u "$USER" -h --format='%i %j %T %M %R' 2>/dev/null | head -10)
[ -z "$out" ] && exit 0

jq -nc --arg out "$out" --arg user "$USER" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:("SQUEUE (" + $user + ", up to 10 lines, format: jobid name state runtime reason):\n" + $out)}}'

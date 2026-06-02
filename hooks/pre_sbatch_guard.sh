#!/bin/bash
# PreToolUse hook: Bash. When the command contains `sbatch`, surface scar-anchored
# pre-flight checks as context — does NOT block. Catches: missing env-source step,
# portfolio-scale launches without confirmation, dependency IDs from stale sessions.
#
# To disable: comment out the matcher in ~/.claude/settings.json, or edit
# this script.

# Read the tool input from stdin
input=$(cat)

# Extract the bash command
cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# Only fire when the command actually invokes sbatch (NOT preceded by `.` —
# that would be a file extension like `run.sbatch`, not an invocation).
echo "$cmd" | grep -qE '(^|[[:space:];&|])sbatch\b' || exit 0

# Count sbatch invocations in the same command — strip quoted strings first
# so `echo "sbatch sbatch sbatch"` doesn't trigger the portfolio warning.
cmd_unquoted=$(echo "$cmd" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
# Count sbatch INVOCATIONS: must be at start-of-line OR preceded by a shell
# separator (whitespace, ;, &, |, &&, ||). This excludes file extensions
# like "run.sbatch" where \bsbatch\b would otherwise false-positive (the `.`
# is a word boundary in regex). The grep -oE outputs one match per line so
# wc -l counts occurrences correctly (grep -cE counts matching LINES).
sbatch_count=$(echo "$cmd_unquoted" | grep -oE '(^|[[:space:];&|])sbatch\b' | wc -l | tr -d ' ')

# Also re-gate the initial fire: if quote-stripping killed all sbatch tokens,
# we hit a false-positive case (e.g. `echo "sbatch"`) and should exit silently.
[ "$sbatch_count" -eq 0 ] && exit 0

# Detect missing env-source step (heuristic: look for `source` + `_load_cluster_env.sh`
# OR `module load` earlier in the same compound command)
has_source=0
if echo "$cmd" | grep -qE '(source\s+\S*_load_cluster_env\.sh|module\s+load)'; then
  has_source=1
fi

# Build the reminder — use $'...' for real newlines, not \n literal in regular quotes
warn=""
if [ "$has_source" -eq 0 ]; then
  warn+=$'- No `source .../scripts/_load_cluster_env.sh` (or `module load`) detected earlier in this compound command. If the cluster env isn\'t already loaded in this shell, the sbatch will pick up stale or missing modules.\n'
fi
if [ "$sbatch_count" -ge 2 ]; then
  warn+="- This command issues ${sbatch_count} sbatch calls in one turn — that's portfolio-scale. Verify the prior turn explicitly approved a launch (the operator's defense list #11: 'when the agent says proposing cycle-0c, verify they're proposing, not submitting')."$'\n'
fi

# Always remind about scar-anchored pre-submission checks
checks=$'- Pre-submission: --dependency IDs not stale (sacct -j to verify), --num-gpus matches allocation, Python path is the env interpreter, input paths exist.\n- Post-submission (within 30s): confirm startup in log, check "Starting N GPU workers", tile speeds.'

msg=$'sbatch detected — scar-anchored pre-flight checks:\n'"${warn}${checks}"

# Asymmetry-fix: when portfolio-scale (>=2 sbatch) AND env-source missing, ASK rather
# than silently inject context. Matches the scancel_guard.sh blocking pattern for
# the highest-cost-on-mistake invocations.
if [ "$sbatch_count" -ge 2 ] && [ "$has_source" -eq 0 ]; then
  jq -nc --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$msg}}'
else
  jq -nc --arg msg "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$msg}}'
fi

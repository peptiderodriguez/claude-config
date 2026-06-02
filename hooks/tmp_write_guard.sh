#!/bin/bash
# PreToolUse hook: block Write/Edit/Bash that targets /tmp/*. The /tmp rule
# is the highest-scar in this user's history ("dude i thought i told you not
# to write to tmp - that is non-recoverable.")
#
# Catches:
#   - Write/Edit tool with file_path = /tmp/*
#   - Bash commands with shell redirects to /tmp/ (>, >>, tee /tmp/...,
#     mkdir /tmp/..., cp/mv/touch into /tmp/...)
#
# Does NOT catch (intentional escape hatches):
#   - Reading from /tmp (cat, ls, grep on existing files is fine)
#   - The user explicitly asking to write to /tmp (the user can override
#     via permissions or by editing this hook)
#
# To disable: comment out the matcher in ~/.claude/settings.json, or edit this script.

input=$(cat)

# Extract tool name + relevant inputs
tool=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null)

# Case 1: Write / Edit / MultiEdit / NotebookEdit — check file_path
if [ "$tool" = "Write" ] || [ "$tool" = "Edit" ] || [ "$tool" = "MultiEdit" ] || [ "$tool" = "NotebookEdit" ]; then
  fp=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
  case "$fp" in
    /tmp/*|/private/tmp/*)
      reason="Blocked: writing to ${fp} violates the global no-/tmp rule (non-recoverable; past correction: 'dude i thought i told you not to write to tmp'). Persist under <project>/scripts/, <dataset>/scripts/, or _shared/slurm_logs/ if it's a log. If you genuinely need /tmp (e.g., a one-shot intermediate that MUST be ephemeral), edit ~/.claude/hooks/tmp_write_guard.sh to add an exception."
      jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
      exit 0
      ;;
  esac
  exit 0
fi

# Case 2: Bash — scan command for /tmp writes
if [ "$tool" = "Bash" ]; then
  cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
  [ -z "$cmd" ] && exit 0

  # Strip quoted regions so `echo "/tmp/foo"` doesn't false-positive
  cmd_unquoted=$(echo "$cmd" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

  # Detect /tmp write patterns:
  #   > /tmp/...      append/redirect into /tmp
  #   >> /tmp/...
  #   tee /tmp/...
  #   tee -a /tmp/...
  #   mkdir /tmp/...    (mkdir -p /tmp/foo)
  #   touch /tmp/...
  #   cp/mv ... /tmp/...
  #   rsync ... /tmp/...
  #   cat <<EOF > /tmp/...
  #   python ... > /tmp/...
  if echo "$cmd_unquoted" | grep -qE '(>>?\s*/tmp/|>>?\s*/private/tmp/|\btee\s+(-a\s+)?/tmp/|\btee\s+(-a\s+)?/private/tmp/|\b(mkdir|touch|cp|mv|rsync|install|wget|curl\s+-o|python\s+\S+\s+>)\s+\S*\s*/tmp/|\b(mkdir|touch|cp|mv|rsync)\s+\S*\s*/private/tmp/)'; then
    reason="Blocked: this command writes to /tmp/. Non-recoverable storage; past correction: 'dude i thought i told you not to write to tmp.' Persist under <project>/scripts/, <dataset>/scripts/, or _shared/slurm_logs/ for logs. To override, edit ~/.claude/hooks/tmp_write_guard.sh."
    jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
  fi
  exit 0
fi

# Case 3: not a tool we guard — silent pass
exit 0

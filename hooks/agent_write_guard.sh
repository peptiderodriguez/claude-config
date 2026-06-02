#!/bin/bash
# PreToolUse hook (matcher: Write|Edit|MultiEdit|NotebookEdit) —
# STRUCTURAL GUARDRAIL: subagent / workflow-agent writes are OFF by default.
#
# Subagents CAN write once the cwd's .claude/settings.local.json grants a
# Write/Edit allow-rule (they inherit the parent's permission scope) — but
# uncontrolled parallel agent writes are dangerous: a never-event had two build
# workflows write the SAME core file concurrently → an uncontrolled multi-agent
# merge that tangled verified state with half-finished edits. A briefing ("return
# edits as text") cannot prevent a write; only a gate can. Operator directive:
# "write only when you mean to write."
#
# Policy enforced here:
#   * MAIN-THREAD writes        -> ALLOWED (the human's hands; intentional by definition).
#   * SUBAGENT / WORKFLOW writes -> DENIED, with a message telling the agent to
#     RETURN the edit as text so the main thread applies it as the single
#     write-stream.
#   * Escape hatch for an INTENTIONAL isolated writer (e.g. a single
#     isolation:worktree migration agent): create
#     `<cwd>/.claude/.allow_agent_writes` (or `$HOME/.claude/.allow_agent_writes`).
#     Such agents MUST be worktree-isolated and never two on one file.
#
# Detection (empirically verified): a subagent / workflow tool call carries a
# non-empty top-level `.agent_id` (+ `.agent_type`); a main-thread call has both
# null. NOTE: `.transcript_path` is SHARED with the parent session (same .jsonl),
# so it CANNOT distinguish a subagent — do not use it.
# Every decision is appended to `<cwd>/.claude/agent_write_guard.log` so the guard
# can be SEEN firing, never trusted blind.

input=$(cat)

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
agent_type=$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null)

logdir="${cwd:-.}/.claude"
log="${logdir}/agent_write_guard.log"
[ -d "$logdir" ] && ts=$(date '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)

is_subagent=0
[ -n "$agent_id" ] && is_subagent=1

decision="allow(main)"
if [ "$is_subagent" = "1" ]; then
  if [ -f "${cwd}/.claude/.allow_agent_writes" ] || [ -f "${HOME}/.claude/.allow_agent_writes" ]; then
    decision="allow(agent-armed)"
  else
    decision="DENY(agent)"
  fi
fi

# audit line (best-effort; never block on logging)
[ -d "$logdir" ] && printf '%s\t%s\t%s\t%s\tagent=%s/%s\n' "${ts:-?}" "$decision" "$tool" "$fp" "${agent_id:-main}" "${agent_type:-main}" >> "$log" 2>/dev/null

if [ "$decision" = "DENY(agent)" ]; then
  reason="BLOCKED: subagent/workflow write to ${fp}. Subagent writes are OFF by default (guards against concurrent multi-agent merges on the same file). RETURN this edit as TEXT — path + verbatim old_string/new_string, or full file content — and the MAIN THREAD will apply it as the single write-stream. If an isolated writer is genuinely intended, the operator can 'touch .claude/.allow_agent_writes' AND that agent must be isolation:worktree (never two writers on one file)."
  jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
fi

exit 0

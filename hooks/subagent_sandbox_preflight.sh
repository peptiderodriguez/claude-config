#!/bin/bash
# PreToolUse hook: Task/Agent dispatch. When a subagent prompt references absolute
# paths that AREN'T in this cwd's `.claude/settings.local.json::additionalDirectories`,
# emit a warning. Subagents inherit ONLY the cwd's settings.local.json, NOT the
# user-global ~/.claude/settings.local.json — this is the load-bearing gotcha that
# has bitten 2+ times in flow.
#
# Behavior: WARN (additionalContext), do NOT deny. False positives possible (e.g.,
# paths quoted as documentation) and the model can adapt or the user can override.
#
# Disable: comment out in ~/.claude/settings.json or edit this script.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null)

# Only fire for Task/Agent dispatches
[ "$tool" = "Task" ] || [ "$tool" = "Agent" ] || exit 0

prompt=$(echo "$input" | jq -r '.tool_input.prompt // empty' 2>/dev/null)
[ -z "$prompt" ] && exit 0

# Resolve the cwd's settings.local.json (parent uses its own working dir)
cwd=$(pwd)
local_settings="$cwd/.claude/settings.local.json"

# Build the list of granted prefixes. If no local settings exist, the subagent
# inherits no additionalDirectories at all and ANY pool/projects path is a risk.
granted=$(jq -r '.permissions.additionalDirectories[]? // empty' "$local_settings" 2>/dev/null)

# Find absolute paths in the prompt under high-risk roots.
# Stop chars: newline, tab, quotes, angle brackets, closing paren. Spaces ALLOWED
# (file systems permit them: /Volumes/My Drive/..., etc.). Trim trailing prose
# punctuation. For over-captures across prose (e.g., "/tmp/foo and then exits"),
# walk back word-by-word to find the longest existing prefix; if nothing exists,
# keep the punctuation-trimmed form (planning-case: path not yet created).
raw_paths=$(echo "$prompt" | grep -oE '(/Volumes/|/fs/|/private/tmp/|/tmp/|__CLAUDE_HOME__/\.claude/projects/|__CLAUDE_HOME__/code/)[^"'\''<>)'$'\t''\\]+')
risky_paths=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  # Trim trailing prose punctuation / whitespace
  while [ -n "$p" ]; do
    last="${p: -1}"
    case "$last" in
      ' '|$'\t'|'.'|','|';'|':'|'!'|'?'|']') p="${p%?}" ;;
      *) break ;;
    esac
  done
  # If the path doesn't exist, walk back word-by-word looking for the longest
  # existing prefix (collapses prose over-capture). If nothing exists, keep as-is.
  if [ ! -e "$p" ]; then
    candidate="$p"
    while [ -n "$candidate" ] && [ ! -e "$candidate" ]; do
      next="${candidate% *}"
      [ "$next" = "$candidate" ] && break
      candidate="$next"
    done
    [ -n "$candidate" ] && [ -e "$candidate" ] && p="$candidate"
  fi
  risky_paths+="${p}"$'\n'
done <<< "$raw_paths"
risky_paths=$(printf '%s' "$risky_paths" | grep -v '^$' | sort -u)

# /tmp check first — separate scar, always warn (even if granted, the parent rule says no /tmp)
tmp_paths=$(echo "$risky_paths" | grep -E '^(/tmp/|/private/tmp/)')

# For each risky path, check if it's covered by a granted prefix
uncovered=""
while IFS= read -r path; do
  [ -z "$path" ] && continue
  # Skip /tmp paths in this loop (handled separately)
  case "$path" in /tmp/*|/private/tmp/*) continue ;; esac

  covered=0
  while IFS= read -r prefix; do
    [ -z "$prefix" ] && continue
    case "$path" in
      "$prefix"|"$prefix"/*) covered=1; break ;;
    esac
  done <<< "$granted"

  if [ "$covered" -eq 0 ]; then
    uncovered+="${path}"$'\n'
  fi
done <<< "$risky_paths"

# If everything is covered AND no /tmp violations → silent pass
if [ -z "$uncovered" ] && [ -z "$tmp_paths" ]; then
  exit 0
fi

# Build the warning
warn_body=""
if [ -n "$uncovered" ]; then
  warn_body+=$'⚠ Subagent briefing references absolute paths NOT in this cwd\'s `.claude/settings.local.json::additionalDirectories`:\n'
  warn_body+="$(echo "$uncovered" | sed 's/^/    /' | grep -v '^    $')"$'\n'
  warn_body+=$'\nThe subagent will fail silently with "I need permission." Before dispatching:\n  1. Add the missing prefixes to '"$local_settings"$' (the user-global ~/.claude/settings.local.json does NOT propagate to subagents).\n  2. OR pre-extract the data and pass it inline in the briefing.\n  3. OR scope the agent to paths it CAN read.\n'
fi
if [ -n "$tmp_paths" ]; then
  warn_body+=$'⚠ Subagent briefing instructs writes to /tmp:\n'
  warn_body+="$(echo "$tmp_paths" | sed 's/^/    /' | grep -v '^    $')"$'\n'
  warn_body+=$'\nGlobal rule: NEVER write to /tmp (non-recoverable). Re-brief the agent to use <project>/scripts/ or stdout.\n'
fi

jq -nc --arg msg "$warn_body" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$msg}}'

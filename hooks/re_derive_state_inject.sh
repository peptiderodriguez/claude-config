#!/bin/bash
# UserPromptSubmit hook: when the user asks a status / orientation / "is it done"
# question, inject a reminder to RE-DERIVE state from disk (squeue, mtimes, sentinels)
# rather than quoting from a session summary or prior message.
#
# Scar: minibinder/CLAUDE.md "incomplete state is NOT acceptable state — verify, don't tolerate"
# + Tuesday May 26 daily-note red-team item: trusting stale summary numbers.
#
# To disable: comment out in ~/.claude/settings.json or edit this script.

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // empty' 2>/dev/null)
[ -z "$prompt" ] && exit 0

# Status / orientation phrasings (lowercase compare). Patterns include common typos.
# Keep regex permissive — informal prompts use loose grammar.
matched=0

# Permissive pattern set — informal status/orientation phrasings.
# Engineering agent (2026-05-31) flagged 5 misses + 1 false-positive (`state` too broad).
# Fixed: constrain `state` to state-of-(jobs|run|cluster|...); add update/progress/stuck/still-running/anything-finished patterns.
echo "$prompt" | grep -iqE '\b(how (are|r) (the |my )?(jobs|runs|things)|whats? the (status|state)|where (are we|did we|r we|am i)|what.?s (the |our )?(status|state) of (the |our )?(jobs|run|runs|cluster|pipeline|sbatch|deploy|build)|is (it|that|\S+) (done|finished|complete|ready)|did (it|that|the run|anything|all) (finish|complete|crash|fail|land)|are (the|my) (jobs|runs) (done|finished|still going|still running)|(still|currently) (running|going|in flight)|cluster status|squeue|whats happen|whats going on|any update|update on (the |my |our )?(cluster|run|jobs|pipeline)|stuck\??$|hung\??$|hanging\??$|status update)' && matched=1

[ "$matched" -eq 0 ] && exit 0

reminder='RE-DERIVE STATE FROM DISK before answering. Do NOT quote a number from a session_summary / prior message / your own previous response:

1. squeue -u $USER -h --format="%.10i %.8T %.10M %R" 2>/dev/null — current jobs (RUNNING / QUEUED / state)
2. For each "done" claim, verify sentinel mtime > latest input mtime (find -newer / stat). Sentinel newer ≠ task succeeded — check the exit code or stdout signal too.
3. For "in progress" claim, specify which of 4: RUNNING / QUEUED / FAILED / STALE-SENTINEL.

Memory is a snapshot; disk is right. "Looks fine" from a stale summary is the failure mode here.'

jq -nc --arg msg "$reminder" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'

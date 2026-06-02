#!/bin/bash
# PostToolUse hook: Edit/Write. When a project ships an opt-in headline-numbers
# regression contract at `<repo>/.claude/headline_numbers_check.yaml`, validate
# that any edit to a "headline-bearing" path didn't drift the locked numbers.
#
# Opt-in shape (per-project): `<repo>/.claude/headline_numbers_check.yaml`:
#   test_script: scripts/test_headline_numbers.py
#   trigger_paths:
#     - "grant_prep/.*\\.md$"
#     - "biology_for_grant\\.md$"
#     - "FUNDABILITY.*\\.md$"
#     - "CLAUDE\\.md$"
#
# When the hook fires:
#   1. Find the repo root of the edited file (walk up to first .git/).
#   2. If `<repo>/.claude/headline_numbers_check.yaml` doesn't exist → silent pass.
#   3. If it exists but the edited file_path doesn't match any trigger_paths → silent pass.
#   4. Otherwise run `<repo>/<test_script>`; on non-zero exit, inject the script's
#      stderr/stdout as `additionalContext` (does NOT block — edit already landed —
#      but surfaces the failure loudly so the next turn can revert or fix).
#
# Replaces the previously-fake reference in `~/.claude/commands/grant-work-mode.md`.
# Designed for rlink2026, but project-agnostic by construction — any project with a
# locked headline-numbers contract benefits.
#
# To disable: comment out the matcher in `~/.claude/settings.json` or edit this script.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null)

# Only fire on Edit-family tools
case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

fp=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
[ -z "$fp" ] && exit 0
[ ! -f "$fp" ] && exit 0

# Walk up to find the repo root
dir=$(dirname "$fp")
repo=""
while [ "$dir" != "/" ] && [ -n "$dir" ]; do
  if [ -d "$dir/.git" ]; then
    repo="$dir"
    break
  fi
  dir=$(dirname "$dir")
done
[ -z "$repo" ] && exit 0

opt_in="$repo/.claude/headline_numbers_check.yaml"
[ ! -f "$opt_in" ] && exit 0

# FAST PRE-CHECK — bail before shelling out to python+yaml if the edited file
# doesn't match any trigger_paths. Engineering critique flagged that python
# ran on every Edit/Write in any git repo. This greps the YAML directly for
# the rel-path basename and quoted patterns — coarse but cheap.
rel_path=$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$fp" "$repo" 2>/dev/null || echo "")
if [ -n "$rel_path" ]; then
  # Extract trigger_paths regexes (lines under `trigger_paths:` starting with `  -`)
  # and check any matches rel_path. Falls back to full parse if grep is ambiguous.
  triggers_inline=$(awk '/^trigger_paths:/{flag=1;next} /^[^ -]/{flag=0} flag && /^\s*-/{print}' "$opt_in" 2>/dev/null)
  if [ -n "$triggers_inline" ]; then
    matched=0
    while IFS= read -r pat; do
      # Strip leading "  - " and surrounding quotes
      pat_clean=$(echo "$pat" | sed -E 's/^\s*-\s*//; s/^"//; s/"$//; s/^'\''//; s/'\''$//')
      [ -z "$pat_clean" ] && continue
      if echo "$rel_path" | grep -qE "$pat_clean" 2>/dev/null; then
        matched=1
        break
      fi
    done <<< "$triggers_inline"
    [ "$matched" -eq 0 ] && exit 0
  fi
fi

# Extract test_script + trigger_paths via Python (no yq dependency)
parsed=$(python3 - "$opt_in" "$fp" "$repo" <<'PY' 2>/dev/null
import sys, re, yaml, os
opt_in, fp, repo = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    cfg = yaml.safe_load(open(opt_in))
except Exception as e:
    print(f"PARSE_ERROR:{e}")
    sys.exit(0)
script = cfg.get("test_script", "")
triggers = cfg.get("trigger_paths", []) or []
rel = os.path.relpath(fp, repo)
matched = any(re.search(pat, rel) for pat in triggers)
if not script or not matched:
    print("SKIP")
else:
    print(f"RUN:{script}")
PY
)

case "$parsed" in
  PARSE_ERROR:*)
    msg="headline_numbers_check.yaml at $opt_in failed to parse: ${parsed#PARSE_ERROR:}. Hook silently passing — fix the YAML to re-engage the gate."
    jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
    exit 0
    ;;
  SKIP|"")
    exit 0
    ;;
  RUN:*)
    script="${parsed#RUN:}"
    ;;
esac

# Run the test from the repo root, capture both stderr+stdout
abs_script="$repo/$script"
if [ ! -f "$abs_script" ]; then
  msg="headline_numbers_check.yaml points at $script but $abs_script doesn't exist. Hook silently passing — wire the script or remove the opt-in."
  jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
  exit 0
fi

# Find the project venv interpreter (prefer .venv/bin/python over system python3)
if [ -x "$repo/.venv/bin/python" ]; then
  py="$repo/.venv/bin/python"
else
  py="python3"
fi

out=$( (cd "$repo" && "$py" "$script") 2>&1)
rc=$?

if [ "$rc" -eq 0 ]; then
  # All green — silent (don't flood context on success)
  exit 0
fi

# Failure — surface loudly
msg=$(printf '⚠ HEADLINE-NUMBERS REGRESSION on edit to %s.\n\nProject ships an opt-in headline-numbers contract at .claude/headline_numbers_check.yaml; the edit triggered %s which returned non-zero:\n\n%s\n\nLikely cause: a locked headline number was changed (or the source-of-truth file is stale). Re-derive the headline from the canonical CSV/parquet, then either (a) update the test if the change is intentional + documented, OR (b) revert the edit. Do NOT silently re-edit to match — that bakes drift into the canon.' "$fp" "$script" "$out")

jq -nc --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'

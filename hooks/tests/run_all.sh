#!/bin/bash
# Pipe-test every hook with positive + negative cases. Closes the
# `process_onboard_methodology.md:52` mandate ("pipe-test every hook with BOTH
# positive and negative cases").
#
# Usage:
#   bash ~/.claude/hooks/tests/run_all.sh         # run all
#   bash ~/.claude/hooks/tests/run_all.sh tmp     # filter to hooks matching 'tmp'
#
# Exit code: 0 if all pass, 1 if any fail. Output is one line per test:
#   PASS  <hook>::<case>
#   FAIL  <hook>::<case>  expected=<X> got=<Y>

set -u
HOOK_DIR="${HOME}/.claude/hooks"
filter="${1:-}"
pass=0
fail=0

# tests are: hook_name|case_name|expected_outcome|stdin_json[|grant_dir]
# expected_outcome ∈ {fire, silent, deny, ask}
# fire = emits non-empty JSON with additionalContext
# silent = emits nothing OR exits without writing to stdout
# deny = emits permissionDecision="deny"
# ask = emits permissionDecision="ask"
# grant_dir (optional 5th field) = an absolute path to grant via a throwaway
#   .claude/settings.local.json in a sandbox cwd the hook is run from. Use for
#   hooks (e.g. subagent_sandbox_preflight) whose behavior depends on the cwd's
#   additionalDirectories — keeps the test self-contained and cwd-independent
#   instead of depending on a real project's grant.

cases=$(cat <<'EOF'
scancel_guard|denies-scancel-u|deny|{"tool_input":{"command":"scancel -u $USER"}}
scancel_guard|allows-scancel-by-jobid|silent|{"tool_input":{"command":"scancel 12345 67890"}}
tmp_write_guard|denies-write-to-tmp|deny|{"tool_name":"Write","tool_input":{"file_path":"/tmp/scratch.py","content":"x"}}
tmp_write_guard|denies-bash-redirect-to-tmp|deny|{"tool_name":"Bash","tool_input":{"command":"echo hello > /tmp/foo.txt"}}
tmp_write_guard|allows-write-to-project|silent|{"tool_name":"Write","tool_input":{"file_path":"$HOME/data/code/obsidian_base/scripts/x.py","content":""}}
tmp_write_guard|allows-cat-from-tmp|silent|{"tool_name":"Bash","tool_input":{"command":"cat /tmp/existing.log"}}
tmp_write_guard|no-false-positive-quoted-tmp|silent|{"tool_name":"Bash","tool_input":{"command":"echo \"about /tmp/foo\""}}
pre_sbatch_guard|fires-on-sbatch|fire|{"tool_input":{"command":"sbatch run.sbatch"}}
pre_sbatch_guard|asks-on-portfolio-launch|ask|{"tool_input":{"command":"sbatch a.sbatch && sbatch b.sbatch && sbatch c.sbatch"}}
pre_sbatch_guard|silent-on-no-sbatch|silent|{"tool_input":{"command":"ls -la"}}
pre_sbatch_guard|no-false-positive-quoted-sbatch|silent|{"tool_input":{"command":"echo \"sbatch sbatch\""}}
re_derive_state_inject|fires-on-how-are-jobs|fire|{"prompt":"how are the jobs going"}
re_derive_state_inject|fires-on-stuck|fire|{"prompt":"stuck?"}
re_derive_state_inject|fires-on-any-update|fire|{"prompt":"any update on the cluster"}
re_derive_state_inject|silent-on-unrelated|silent|{"prompt":"refactor the auth module"}
re_derive_state_inject|silent-on-api-state|silent|{"prompt":"what is the state of the API"}
surprise_capture|fires-on-huh|fire|{"prompt":"huh, that is weird"}
surprise_capture|silent-on-unrelated|silent|{"prompt":"refactor the auth module"}
subagent_sandbox_preflight|fires-on-uncovered-fs-path|fire|{"tool_name":"Task","tool_input":{"prompt":"Read /fs/pool/some/other/dir/file.txt and report."}}
subagent_sandbox_preflight|silent-on-covered|silent|{"tool_name":"Task","tool_input":{"prompt":"Read /fs/example/code_bin/proj/CLAUDE.md"}}|/fs/example/code_bin
subagent_sandbox_preflight|fires-on-tmp|fire|{"tool_name":"Task","tool_input":{"prompt":"Save output to /tmp/scratch.txt"}}
headline_numbers_check|silent-without-opt-in|silent|{"tool_name":"Write","tool_input":{"file_path":"$HOME/data/code/obsidian_base/random.md"}}
headline_numbers_check|silent-on-non-edit-tool|silent|{"tool_name":"Bash","tool_input":{"command":"ls"}}
pmid_citation_guard|silent-on-no-pmid|silent|{"tool_name":"Write","tool_input":{"file_path":"$HOME/data/code/obsidian_base/scripts/no_pmid_here.md"}}
pmid_citation_guard|silent-on-non-text-file|silent|{"tool_name":"Write","tool_input":{"file_path":"$HOME/.claude/hooks/test.sh"}}
EOF
)

while IFS='|' read -r hook case_name expected stdin grant; do
  [ -z "$hook" ] && continue
  [ -n "$filter" ] && [[ "$hook" != *"$filter"* ]] && continue
  hook_path="$HOOK_DIR/${hook}.sh"
  if [ ! -x "$hook_path" ]; then
    echo "SKIP  ${hook}::${case_name}  not-executable=$hook_path"
    continue
  fi

  if [ -n "$grant" ]; then
    # Run the hook from a throwaway cwd that grants $grant, so cwd-dependent
    # hooks are tested self-contained (no reliance on a real project's grant).
    sandbox="$HOOK_DIR/tests/.sandbox_cwd"
    rm -rf "$sandbox"; mkdir -p "$sandbox/.claude"
    printf '{"permissions":{"additionalDirectories":["%s"]}}\n' "$grant" \
      > "$sandbox/.claude/settings.local.json"
    output=$(cd "$sandbox" && echo "$stdin" | bash "$hook_path" 2>/dev/null)
    rm -rf "$sandbox"
  else
    output=$(echo "$stdin" | bash "$hook_path" 2>/dev/null)
  fi
  if [ -z "$output" ]; then
    got="silent"
  else
    decision=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
    if [ -n "$decision" ]; then
      got="$decision"  # "deny" or "ask"
    else
      got="fire"
    fi
  fi

  if [ "$got" = "$expected" ]; then
    echo "PASS  ${hook}::${case_name}"
    pass=$((pass+1))
  else
    echo "FAIL  ${hook}::${case_name}  expected=$expected got=$got"
    fail=$((fail+1))
  fi
done <<< "$cases"

echo ""
echo "=== Summary: ${pass} pass, ${fail} fail ==="
[ "$fail" -eq 0 ]

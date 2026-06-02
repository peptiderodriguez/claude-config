#!/bin/bash
# Integration test: a fresh collaborator install produces a working persona.
#
# Installs the repo into a throwaway $HOME sandbox, asserts the persona landed
# (CLAUDE.md + every skill/hook/agent/script/memory file the repo ships), that
# the __CLAUDE_HOME__ placeholder fully resolved, that settings.json is valid
# JSON, that the custom agents carry registerable `name:` frontmatter, that the
# hook smoke-test passes, and that the repo carries no un-anonymized identifiers.
# Expected counts are DERIVED FROM THE REPO so this never goes stale on additions.
# Lives in tests/ (NOT scripts/) so it is not shipped into users' ~/.claude/.
#
# Run locally:  bash tests/test_install.sh
# CI:           .github/workflows/install-test.yml
set -uo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/cc-install-test.XXXXXX")
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

fail=0
ck() { # description  actual  expected
  if [ "$2" = "$3" ]; then printf '  PASS  %s (%s)\n' "$1" "$2"
  else printf '  FAIL  %s: got "%s", expected "%s"\n' "$1" "$2" "$3"; fail=1; fi
}
n() { ls $1 2>/dev/null | wc -l | tr -d ' '; }   # arg is a single quoted glob string

# expected counts, derived from the repo (not hardcoded)
exp_skills=$(n "$REPO/commands/*.md")
exp_hooks=$(n "$REPO/hooks/*.sh")
exp_agents=$(n "$REPO/agents/*.md")
exp_scripts=$(n "$REPO/scripts/*")
exp_memory=$(n "$REPO/memory/*.md")

echo "== install into sandbox HOME ($SANDBOX) =="
if ! env HOME="$SANDBOX" bash "$REPO/install.sh" >/dev/null 2>&1; then
  echo "  FAIL  install.sh exited non-zero"; exit 1
fi
C="$SANDBOX/.claude"

echo "== persona landed =="
ck "CLAUDE.md installed"        "$([ -f "$C/CLAUDE.md" ] && echo 1 || echo 0)" "1"
ck "skills installed"          "$(n "$C/commands/*.md")"  "$exp_skills"
ck "hooks installed"           "$(n "$C/hooks/*.sh")"     "$exp_hooks"
ck "agents installed"          "$(n "$C/agents/*.md")"    "$exp_agents"
ck "scripts installed"         "$(n "$C/scripts/*")"      "$exp_scripts"
ck "memory installed"          "$(n "$C/projects/*/memory/*.md")" "$exp_memory"
ck "citation manifest seeded"  "$([ -f "$C/state/citations.csv" ] && echo 1 || echo 0)" "1"

echo "== placeholder + validity =="
ck "settings.json: __CLAUDE_HOME__ resolved" "$(grep -c __CLAUDE_HOME__ "$C/settings.json" 2>/dev/null | tr -d ' ')" "0"
ck "hooks: __CLAUDE_HOME__ resolved"          "$(grep -rl __CLAUDE_HOME__ "$C/hooks/" 2>/dev/null | wc -l | tr -d ' ')" "0"
ck "settings.json valid JSON" "$(python3 -c "import json;json.load(open('$C/settings.json'));print(1)" 2>/dev/null || echo 0)" "1"
ck "all agents have name: frontmatter" "$(grep -l '^name:' "$C/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')" "$exp_agents"

echo "== hook smoke-test (fresh install) =="
hb=$(env HOME="$SANDBOX" bash "$C/hooks/tests/run_all.sh" 2>&1 | tail -1)
echo "  $hb"
echo "$hb" | grep -q "0 fail" || { echo "  FAIL  hook harness not green"; fail=1; }

echo "== anonymization (no un-scrubbed identifiers in the shipped repo) =="
if python3 "$REPO/scripts/anonymize.py" --check "$REPO" >/dev/null 2>&1; then
  echo "  PASS  anonymize --check"
else
  echo "  FAIL  anonymize --check found identifiers"; fail=1
fi

echo
if [ "$fail" = "0" ]; then echo "ALL INSTALL TESTS PASSED"; else echo "INSTALL TESTS FAILED"; fi
exit "$fail"

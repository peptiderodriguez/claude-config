#!/bin/bash
# Doc-consistency gate — encodes "always update the docs" as a test, not a memory.
# Fails if the docs disagree with the repo: stated counts (skills/hooks/agents/
# memory/scripts) must match disk; every skill/hook/agent file must appear in its
# catalog page + README (+ skills also in the sync.sh whitelist); the mkdocs nav
# must be 1:1 with docs/*.md. Add a component without updating its docs -> red.
#
# Run locally:  bash tests/test_docs_consistency.sh    CI: install-test.yml
set -uo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd); cd "$REPO"
fail=0
F(){ printf '  FAIL  %s\n' "$1"; fail=1; }
OK(){ printf '  ok    %s\n' "$1"; }
n(){ ls $1 2>/dev/null | wc -l | tr -d ' '; }
hdr(){ grep -m1 -oE '\([0-9]+\)' "$1" 2>/dev/null | tr -d '()'; }   # "# Skills (12)" -> 12
idx(){ grep -E "\| $1 \|" docs/index.md | grep -oE '[0-9]+' | head -1; }  # inventory row

S=$(n 'commands/*.md'); H=$(n 'hooks/*.sh'); A=$(n 'agents/*.md')
MF=$(ls memory/*.md 2>/dev/null | grep -v MEMORY.md | wc -l | tr -d ' '); SC=$(n 'scripts/*')
echo "disk: skills=$S hooks=$H agents=$A memory-files=$MF scripts=$SC"

echo "== catalog headers match disk =="
[ "$(hdr docs/catalog/skills.md)" = "$S" ]  && OK "Skills ($S)"  || F "catalog/skills.md header $(hdr docs/catalog/skills.md) != $S"
[ "$(hdr docs/catalog/hooks.md)"  = "$H" ]  && OK "Hooks ($H)"   || F "catalog/hooks.md header $(hdr docs/catalog/hooks.md) != $H"
[ "$(hdr docs/catalog/agents.md)" = "$A" ]  && OK "Agents ($A)"  || F "catalog/agents.md header $(hdr docs/catalog/agents.md) != $A"
[ "$(hdr docs/catalog/memory.md)" = "$MF" ] && OK "Memory ($MF)" || F "catalog/memory.md header $(hdr docs/catalog/memory.md) != $MF"

echo "== docs/index inventory table matches disk =="
[ "$(idx Skills)" = "$S" ]  && OK "index Skills"  || F "index Skills $(idx Skills) != $S"
[ "$(idx Hooks)"  = "$H" ]  && OK "index Hooks"   || F "index Hooks $(idx Hooks) != $H"
[ "$(idx Agents)" = "$A" ]  && OK "index Agents"  || F "index Agents $(idx Agents) != $A"
[ "$(grep -E '\| Memory files \|' docs/index.md | grep -oE '[0-9]+' | head -1)" = "$MF" ] && OK "index Memory" || F "index Memory != $MF"
[ "$(grep -E '\| Helper scripts \|' docs/index.md | grep -oE '[0-9]+' | head -1)" = "$SC" ] && OK "index Scripts" || F "index Scripts != $SC"

echo "== every component file is documented =="
for f in commands/*.md; do b=$(basename "$f" .md)
  grep -q "\`$b\`" docs/catalog/skills.md || F "skill '$b' missing from catalog/skills.md"
  grep -q "\`$b\`" README.md              || F "skill '$b' missing from README"
  grep -qw "$b" sync.sh                    || F "skill '$b' missing from sync.sh whitelist"
done
for f in hooks/*.sh; do b=$(basename "$f" .sh)
  grep -q "$b" docs/catalog/hooks.md || F "hook '$b' missing from catalog/hooks.md"
  grep -q "$b" README.md             || F "hook '$b' missing from README"
done
for f in agents/*.md; do b=$(basename "$f" .md)
  grep -q "$b" docs/catalog/agents.md || F "agent '$b' missing from catalog/agents.md"
  grep -q "$b" README.md              || F "agent '$b' missing from README"
done
[ "$fail" = 0 ] && OK "all skill/hook/agent files appear in their catalog + README"

echo "== mkdocs nav 1:1 with docs/*.md =="
nav=$(grep -cE '\.md$' mkdocs.yml); docs=$(find docs -name '*.md' | wc -l | tr -d ' ')
[ "$nav" = "$docs" ] && OK "nav=$nav == docs=$docs" || F "mkdocs nav ($nav) != docs/*.md ($docs)"

echo
[ "$fail" = 0 ] && echo "DOCS CONSISTENT" || echo "DOCS DRIFT — update the docs to match the repo"
exit "$fail"

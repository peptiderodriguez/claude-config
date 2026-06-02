#!/bin/bash
# sync.sh — pull live ~/.claude/ files into this repo so they can be committed.
# Run from the repo root.
set -e
REPO=$(cd "$(dirname "$0")" && pwd)
cd "$REPO"

mkdir -p commands hooks hooks/tests memory agents scripts

cp ~/.claude/CLAUDE.md CLAUDE.md
cp ~/.claude/settings.json settings.json

# Custom skills only (skip pre-existing globals like debug-segmentation / review-code)
for name in critique cluster-traffic sessions orient onboard scaffold-agent scaffold-analyze anti-fabrication grant-work-mode covariate-screen scaffold-discipline; do
  src=~/.claude/commands/$name.md
  [ -f "$src" ] && cp "$src" commands/
done

# All hooks + agents + tests
for f in ~/.claude/hooks/*.sh; do
  [ -f "$f" ] && cp "$f" hooks/
done

for f in ~/.claude/hooks/tests/*.sh; do
  [ -f "$f" ] && cp "$f" hooks/tests/
done

for f in ~/.claude/agents/*.md; do
  [ -f "$f" ] && cp "$f" agents/
done

# Scripts (e.g., seed_pubmed_cache.py for the pmid_citation_guard hook composition)
for f in ~/.claude/scripts/*; do
  [ -f "$f" ] && cp "$f" scripts/
done

# Memory dir is keyed by the sanitized cwd Claude derives from your global-memory
# location ($HOME/data/code → every non-alphanumeric char replaced by '-'), the
# same rule install.sh uses. If your durable memory lives elsewhere, point MEM_SRC
# at it directly.
MEM_SRC="$HOME/.claude/projects/$(printf '%s' "$HOME/data/code" | sed 's|[^a-zA-Z0-9]|-|g')/memory"
mem_copied=0
for f in "$MEM_SRC"/*.md; do
  [ -f "$f" ] && cp "$f" memory/ && mem_copied=$((mem_copied + 1))
done
if [ "$mem_copied" -eq 0 ]; then
  echo "WARN: synced 0 memory files — '$MEM_SRC' is empty or wrong. Point MEM_SRC at your durable-memory dir." >&2
fi

# Vault meta-analyses (lives outside ~/.claude/) — glob all versions
for f in ~/data/code/obsidian_base/meta_claude_usage_*.md; do
  [ -f "$f" ] && cp "$f" "$(basename "$f")"
done

# --- Anonymize everything just synced (live real names -> generic), then verify ---
# The repo is a public, anonymized fork of the live ~/.claude. Without this step a
# sync would re-leak real project names / identifiers. The map is the source of
# truth (scripts/anonymize_map.tsv); the --check is fail-closed.
echo "Anonymizing synced files (scripts/anonymize_map.tsv)..."
python3 "$REPO/scripts/anonymize.py" --apply "$REPO"

echo "Verifying no real identifiers leaked..."
if ! python3 "$REPO/scripts/anonymize.py" --check "$REPO"; then
  echo "ERROR: anonymization check FAILED — real identifiers are present in the repo." >&2
  echo "       Add the missing mapping to scripts/anonymize_map.tsv, then re-run ./sync.sh." >&2
  echo "       Do NOT commit until this passes." >&2
  exit 1
fi

echo "Synced + anonymized. Review with: git diff"

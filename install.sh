#!/bin/bash
# install.sh — install this snapshot into ~/.claude/ on any machine.
# Rewrites the __CLAUDE_HOME__ placeholder token in settings.json + hooks to the
# resolved $HOME of the current user, so the same snapshot installs on Mac
# (/Users/...) and cluster (/fs/.../home/...).
# Backs up any existing files to *.pre-install before overwriting.
set -e
REPO=$(cd "$(dirname "$0")" && pwd)
TARGET="${HOME}/.claude"

# Memory lives under the projects/<dir> that Claude derives from the operator's
# global-memory cwd ($HOME/data/code). Claude builds that dir name by replacing
# every non-alphanumeric char in the cwd with '-'; reproduce it from the current
# user's $HOME so memory installs where Claude will actually read it (a hardcoded
# -Users-<name>-data-code would land the files in a dir Claude never loads).
MEM_DIR="$TARGET/projects/$(printf '%s' "$HOME/data/code" | sed 's|[^a-zA-Z0-9]|-|g')/memory"

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    echo "  Backing up existing $path -> $path.pre-install"
    mv "$path" "$path.pre-install"
  fi
}

echo "Installing claude-config from $REPO -> $TARGET/"
echo "  HOME = $HOME"
echo "  USER = $USER"
echo "  MEM  = $MEM_DIR  (memory loads only for sessions whose cwd is \$HOME/data/code)"

# Directory scaffolding
mkdir -p "$TARGET/commands" \
         "$TARGET/hooks" \
         "$TARGET/hooks/tests" \
         "$TARGET/agents" \
         "$TARGET/scripts" \
         "$TARGET/state" \
         "$TARGET/cache/pubmed" \
         "$MEM_DIR"

# Top-level files — sed-rewrite __CLAUDE_HOME__ → $HOME in settings.json
backup_if_exists "$TARGET/CLAUDE.md"
cp "$REPO/CLAUDE.md" "$TARGET/CLAUDE.md"

backup_if_exists "$TARGET/settings.json"
sed "s|__CLAUDE_HOME__|$HOME|g" "$REPO/settings.json" > "$TARGET/settings.json"

# Commands (custom skills)
for f in "$REPO"/commands/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  backup_if_exists "$TARGET/commands/$name"
  cp "$f" "$TARGET/commands/$name"
done

# Hooks (sed-rewrite __CLAUDE_HOME__ → $HOME in any hook that references it)
for f in "$REPO"/hooks/*.sh; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  backup_if_exists "$TARGET/hooks/$name"
  sed "s|__CLAUDE_HOME__|$HOME|g" "$f" > "$TARGET/hooks/$name"
  chmod +x "$TARGET/hooks/$name"
done

# Hook test harness
for f in "$REPO"/hooks/tests/*.sh; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  backup_if_exists "$TARGET/hooks/tests/$name"
  sed "s|__CLAUDE_HOME__|$HOME|g" "$f" > "$TARGET/hooks/tests/$name"
  chmod +x "$TARGET/hooks/tests/$name"
done

# Agents
for f in "$REPO"/agents/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  backup_if_exists "$TARGET/agents/$name"
  cp "$f" "$TARGET/agents/$name"
done

# Scripts (e.g. seed_pubmed_cache.py)
for f in "$REPO"/scripts/*; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  backup_if_exists "$TARGET/scripts/$name"
  cp "$f" "$TARGET/scripts/$name"
  [[ "$name" == *.sh ]] && chmod +x "$TARGET/scripts/$name"
  [[ "$name" == *.py ]] && chmod +x "$TARGET/scripts/$name"
done

# Memory
for f in "$REPO"/memory/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  backup_if_exists "$MEM_DIR/$name"
  cp "$f" "$MEM_DIR/$name"
done

# Initialize empty citation manifest if it doesn't exist
if [ ! -f "$TARGET/state/citations.csv" ]; then
  echo "pmid,first_author,year,journal,fixture,used_in,status" > "$TARGET/state/citations.csv"
  echo "  Initialized empty PMID manifest at $TARGET/state/citations.csv"
fi

echo
echo "Install complete."
echo "  - Originals (if any) backed up at *.pre-install"
echo "  - settings.json rewritten with HOME=$HOME"
echo "  - Open /hooks once in Claude Code (or restart) to activate hook watcher"
echo
echo "Smoke-test the hooks:"
echo "  bash $TARGET/hooks/tests/run_all.sh"

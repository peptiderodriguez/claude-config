# Syncing changes back

The repo is a **snapshot**, not a live link to `~/.claude/`. When you've edited a file in `~/.claude/` — because Claude Code updated `settings.json`, or you tweaked a skill — capture it with `sync.sh`:

```bash
cd ~/code/claude-config
./sync.sh            # copies live ~/.claude/ files back into the repo
git diff             # review
git add -A && git commit -m "sync: <what changed>"
git push
```

## What `sync.sh` copies

- `~/.claude/CLAUDE.md` and `~/.claude/settings.json`
- All 13 hooks + the hook test harness (`hooks/tests/`)
- All 3 agents and the `scripts/` helpers
- The **10 custom skills** named in the whitelist at `sync.sh:14` (it skips any pre-existing global commands you didn't author)
- Durable memory, from the directory derived from `$HOME/data/code` (same sanitizing rule `install.sh` uses)
- The vault meta-analyses (`meta_claude_usage_*.md`)

!!! warning "Two spots to edit when you fork"
    `sync.sh` has a **hardcoded skills whitelist** (line 14) — add new skill names there or they won't sync. If your durable memory lives somewhere other than `$HOME/data/code`, point `MEM_SRC` at it directly.

## Propagating to another machine

`sync.sh` runs wherever you author changes; the other machines just `git pull` and re-run `install.sh` (idempotent). See the [Cluster runbook](cluster.md#sync-upstream-changes-from-the-mac) for the cluster side.

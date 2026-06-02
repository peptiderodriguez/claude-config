Quick session resume — read memory, check state, surface what was in flight. Use after compaction, session restart, or when the user has lost the thread.

TRIGGER when user asks: "where were we", "ok where are we", "what was I doing", "resume", "continue from where we left off", "remind me what we were working on", "pick up from", "what's the status of", "what's our state". Also auto-invoke on the first user prompt after seeing "This session is being continued from a previous conversation" anywhere in the loaded context — that's a compaction-resume signal.

SKIP when the user is starting a clearly new topic (different repo, different domain), or when they've already been driving for several turns this session — only useful at the orientation moment.

## Sequence

1. **Detect cwd mode.** First decide: is this a **project** cwd (a real code repo with substantive code under it) or a **vault/coordination** cwd (the Obsidian vault `~/data/code/obsidian_base/`, or a notes-only tree with no source code)? **Vault mode if any:** (a) cwd basename is `obsidian_base`, (b) cwd path starts with `~/data/code/obsidian_base/`, (c) cwd has no source files (only `.md` notes), (d) cwd has no `.git` at all. Note that the vault itself may be a git repo (just notes under version control) — `is-inside-work-tree` is NOT a reliable signal. Prefer the basename/path check. If vault mode, use step 1V. Otherwise proceed with the project sequence.

### Project mode (cwd is a real repo)

2. **Read memory** — `~/.claude/projects/<sanitized-cwd>/memory/MEMORY.md` if the index exists; load whichever sub-files seem relevant to the cwd. Also load global `~/.claude/CLAUDE.md`.

3. **Check current state** — in parallel:
   - `pwd` and `git -C $PWD rev-parse --abbrev-ref HEAD` to identify project + branch
   - `git -C $PWD log -5 --oneline` for recent commits
   - `git -C $PWD status -s` for uncommitted work
   - `TaskList` for open tasks in this conversation
   - `squeue -u $USER -h --format='%.10i %.8T %.10M %R' 2>/dev/null | head -5` if SLURM available
   - `gh pr list --limit 3 2>/dev/null` if gh + remote available

4. **Skim today's daily note** — `cat /Users/<operator>/data/code/obsidian_base/<DayOfWeek MMM DD YYYY>.md 2>/dev/null` if present. Look for the `CLAUDE SESSIONS:` block (what sessions are active) and the most recent decisions/notes.

5. **Produce a 5–8 line state report:**

```
RESUME — <project> @ <branch>
  Memory: <which files loaded, comma-list>
  Open tasks (N): <first 2 task titles>
  Recent commits: <last 2 short>
  Uncommitted: <count + brief>
  Cluster: <queue state or "off">
  Today's note: <last 1-2 decisions>
  Likely next step: <inference from above + last conversation turn>
```

### Vault mode (cwd is the Obsidian vault or has no project state)

1V. **The vault has no project state of its own — pivot to surfacing the *sibling* sessions** the operator is coordinating across. The `obsidian_base/<DayOfWeek MMM DD YYYY>.md` daily note's `CLAUDE SESSIONS:` block is the authoritative source.

2V. **Read today's daily note + sessions block:**
   - `cat /Users/<operator>/data/code/obsidian_base/$(date +'%A %B %-d %Y').md 2>/dev/null`
   - Extract the `CLAUDE SESSIONS:` block — lines of form `- <name>: <path>`. These are the active sibling sessions.
   - If the note doesn't exist for today, fall back to yesterday's.

3V. **For each sibling session (up to 5)**, grab a one-line state digest in parallel:
   - Branch: `git -C <path> rev-parse --abbrev-ref HEAD 2>/dev/null`
   - Last commit (subject only): `git -C <path> log -1 --format='%h %s' 2>/dev/null | head -c 80`
   - Uncommitted file count: `git -C <path> status -s 2>/dev/null | wc -l`
   - If `/Volumes/pool-mann-<operator>/...` symlinked, use the cluster `/fs/...` mount only when unambiguous.

4V. **Skim the daily note for recent decisions** — last ~30 lines, look for bulleted action items, "address this", "next:", or fresh deliverables. Surface the 1-2 most recent.

5V. **Cluster snapshot** — if `squeue` available (rare from this Mac), grab top-5 jobs. Otherwise note "off".

6V. **Produce a 7–10 line vault-mode report:**

```
RESUME (vault) — coordinating N sessions
  Sessions:
    <name1>: <path>  @ <branch>  · <last commit>  · <±uncommitted>
    <name2>: <path>  @ <branch>  · <last commit>  · <±uncommitted>
    <name3>: <path>  @ <branch>  · <last commit>  · <±uncommitted>
  Cluster: <queue state or "off">
  Today's note (last decisions): <1-2 fresh items, terse>
  Likely next step: <which sibling session looks most actionable + why>
```

Vault-mode answers the question "which of my sessions is most in flight + needs me next?" instead of "what's in this cwd?" — because the answer to the second question is always "nothing, it's a vault."

5. **Don't go deeper than the snapshot.** The user is reorienting; they'll ask for details if they need them. The goal is to compress 30 seconds of "let me figure out where I am" into 5 seconds of "ah, right, X — let's do Y".

## Notes

- Mirror the user's terse register here. This is an ops update, not a stakes-spike — no narration, no preamble.
- If the cwd is outside `~/data/code/`, the memory dir may not exist — skip silently.
- If the daily note doesn't exist for today, check yesterday's.
- This skill is also fired automatically by the `PostCompact` hook (`~/.claude/hooks/postcompact_resume.sh`) which injects a brief state snapshot into context — `/orient` does the fuller version.

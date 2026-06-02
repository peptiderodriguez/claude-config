# Cluster-side install runbook — for Claude to follow

You are a Claude Code session running on the HPC cluster (or any non-Mac host). The user wants you to install the global Claude Code infrastructure from this snapshot into the cluster's `$HOME/.claude/`.

## What you're installing

A snapshot of `~/.claude/`, path-agnostic (Mac paths tokenized as `__CLAUDE_HOME__`), containing:

- **Global rules** (`CLAUDE.md`) — house style, cluster discipline, subagent rules, statistics methodology, driving philosophies, etc.
- **11 custom skills** with auto-fire TRIGGERs (`commands/*.md`): `critique`, `cluster-traffic`, `sessions`, `orient`, `onboard`, `scaffold-agent`, `scaffold-analyze`, `anti-fabrication`, `grant-work-mode`, `covariate-screen`, `scaffold-discipline`
- **3 custom agents** (`agents/*.md`): `dfg-reviewer`, `frame-auditor`, `dissent-auditor`
- **13 hooks** (`hooks/*.sh`) — mechanical enforcement (scancel-deny, /tmp-write-deny, sbatch-preflight, PMID-citation-guard, etc.)
- **Settings wiring** (`settings.json`)
- **Helper script** (`scripts/seed_pubmed_cache.py`)
- **Hook test harness** (`hooks/tests/run_all.sh`)
- **Durable memory** (`memory/*.md`)

The install script handles cluster-vs-Mac path differences automatically — it sed-rewrites the `__CLAUDE_HOME__` placeholder token in `settings.json` and all hooks/hook-tests to the resolved `$HOME` on the target machine. It also derives the durable-memory install dir from the current user's `$HOME` (`$HOME/data/code` → every non-alphanumeric char replaced by `-`), not a hardcoded path.

## Step-by-step (for you, the cluster-side Claude session)

### 1. Confirm context

```bash
echo "HOME=$HOME"
echo "USER=$USER"
echo "hostname=$(hostname)"
pwd
ls install.sh sync.sh CLAUDE.md  # confirm you're in the claude-config snapshot dir
```

If `pwd` is not a directory containing `install.sh`, `cd` to wherever this `CLUSTER_INSTALL.md` lives — usually `/fs/<pool>/<lab>/code_bin/claude-config/` on cluster.

### 2. Inspect what exists on this cluster's `$HOME/.claude/` already

```bash
ls -la "$HOME/.claude/" 2>&1 | head -20
```

If the dir already exists with content, the install will back up existing files to `*.pre-install` — that's safe. If it's a clean directory, the install creates everything fresh.

### 3. Run the install

```bash
bash install.sh
```

Expected output: a list of file copies + the path rewrites, ending with `Install complete.`

### 4. Smoke-test the hooks

```bash
bash "$HOME/.claude/hooks/tests/run_all.sh"
```

Expected: `25 pass, 0 fail`. If any FAIL, surface the names to the user.

**Two known gotchas:**

- **Many tests FAIL `got=silent`** → `jq` is missing on PATH (see Troubleshooting). Every JSON-parsing hook exits silently without it. Fix `jq` first, then re-run — the failures clear.
- **`subagent_sandbox_preflight` tests are self-contained** — the harness writes a throwaway `.claude/settings.local.json` granting `/fs/example/code_bin` in a sandbox cwd, so `silent-on-covered` passes regardless of where you run from. If you instead see `got=fire` here, you're on a stale harness (pre-`8af66ce`); re-pull. To run just this hook's cases from any cwd:
  ```bash
  bash "$HOME/.claude/hooks/tests/run_all.sh" subagent_sandbox_preflight   # → 3 pass, 0 fail, from any cwd
  ```

### 5. Validate `settings.json` JSON structure

```bash
python3 -c "import json; json.load(open('$HOME/.claude/settings.json')); print('settings.json valid JSON')"
```

### 6. Re-activate the hook watcher

The Claude Code hook watcher only tracks files that existed at session start. **Tell the user to either:**
- Type `/hooks` in their Claude Code session to reload the watcher, OR
- Restart their Claude Code session

Until one of these happens, the newly-installed hooks are present on disk but NOT firing.

### 7. Confirm the install landed

```bash
echo "=== Files installed ==="
ls "$HOME/.claude/CLAUDE.md" "$HOME/.claude/settings.json"
ls "$HOME/.claude/commands/" | wc -l   # >= 11 (11 custom from snapshot + any pre-existing globals)
ls "$HOME/.claude/agents/" | wc -l     # should be 3
ls "$HOME/.claude/hooks/"*.sh | wc -l  # should be 13
ls "$HOME/.claude/scripts/" 2>/dev/null
ls "$HOME/.claude/state/citations.csv"  # PMID manifest header
```

### 8. Per-project wiring (the `additionalDirectories` step)

The 5 active project repos under `/fs/<pool>/<lab>/code_bin/` already have their `.claude/settings.local.json` files updated to include both `/Volumes/pool-mann-<operator>/code_bin` (Mac path) AND `/fs/<pool>/<lab>/code_bin` (HPC path). On cluster these grants now resolve correctly — subagent_sandbox_preflight will work in either path context.

If any new project needs Claude scaffolding from the cluster side, create `<project>/.claude/settings.local.json` with:

```json
{
  "permissions": {
    "additionalDirectories": [
      "/fs/<pool>/<lab>/code_bin",
      "/fs/<pool>/<lab>"
    ]
  }
}
```

## Sync upstream changes from the Mac

When the operator's Mac `~/.claude/` evolves and they want the cluster to follow, they run (on the Mac):

```bash
cd ~/code/claude-config
./sync.sh           # pulls live ~/.claude/ files into the repo
git add -A && git commit -m "<what changed>" && git push
```

Then on the cluster:

```bash
cd /fs/<pool>/<lab>/code_bin/claude-config
git pull
bash install.sh
```

The install is idempotent (backs up + replaces) so re-running is safe.

## Troubleshooting

- **Hooks not firing after install:** see step 6. The watcher needs a reload.
- **`jq: command not found`** in hook scripts: the hooks call the **`jq` CLI binary** (bare `jq ...`), which is the only hard dependency. Note: `pip install jq` does NOT fix this — that installs a Python *library*, not the `jq` command on PATH. On the HPC site there is no `module jq`, and `conda install -n base -c conda-forge jq` fails (conda-forge tries to remove conda's own deps). The working fix is an isolated env + symlink onto PATH:
  ```bash
  conda create -y -p "$HOME/.claude/condaenv-jq" -c conda-forge jq
  ln -sf "$HOME/.claude/condaenv-jq/bin/jq" "$HOME/.local/bin/jq"   # ~/.local/bin is first on PATH
  jq --version   # confirm
  ```
  This is durable across sessions as long as `~/.local/bin` stays on PATH. If hooks ever go silent again, check `command -v jq` first.
- **`python3` not on PATH:** the hooks call `python3` for inline JSON parsing. The cluster typically has Python 3 in `/usr/bin/python3` or via `module load python/3.11`. Confirm `python3 --version` works.
- **Paths not rewritten despite the sed:** double-check by `grep -rE "__CLAUDE_HOME__|/Users/" "$HOME/.claude/hooks/" "$HOME/.claude/settings.json"` — should return nothing. A surviving `__CLAUDE_HOME__` token means the placeholder sed failed; a surviving `/Users/...` literal means a Mac path slipped through. Either way, report to the user.
- **`squeue_inject.sh`** is designed to fire only when `squeue` is on PATH. On the cluster `squeue` exists, so this hook WILL inject current job state into every prompt — this is the intended behavior, not a bug.

## What's not yet installed

The following are Mac-specific and don't need to install on cluster:
- The pool mount-path conventions (`/Volumes/...`) — cluster uses `/fs/...` directly
- The Obsidian vault at `$HOME/data/code/obsidian_base/` — Mac-only daily-note coordination
- `session_digest.sh` and `session_end_audit.sh` write to the Obsidian vault path — they're harmless on cluster (the path won't exist, they exit 0) but won't produce useful output

If you want to repurpose `session_digest.sh` for cluster use, point it at a cluster-side notes dir (e.g., `~/notes/daily/`).

## Done

After steps 1–7 complete cleanly and the user has reloaded `/hooks`, the cluster session has the full infrastructure active. Report to the user:

```
Cluster install complete.
  $HOME/.claude/ populated: <X> hooks, <Y> skills, <Z> agents
  Smoke test: 25/25 pass
  settings.json: valid
  Action required: type /hooks to reload, OR restart this Claude session.
```

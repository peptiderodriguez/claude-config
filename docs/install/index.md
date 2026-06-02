# Quickstart install

## Prerequisites

- **[Claude Code](https://claude.com/claude-code)** — this repo is a configuration *for* it.
- **`jq`** — the CLI binary, **not** the `pip install jq` Python library. Every JSON-parsing hook calls it; without it, hooks fail silently. See [cluster troubleshooting](cluster.md#troubleshooting) for an isolated-env install that also works on a Mac (`conda`/`brew install jq`).
- **`python3`** — hooks use it for inline JSON parsing.
- **(Docs only)** `mkdocs-material` via `pip install -r requirements-docs.txt` if you want to build this site locally.

```bash
git clone <repo-url> ~/code/claude-config
cd ~/code/claude-config
./install.sh
```

## What `install.sh` does

- Copies `CLAUDE.md`, `settings.json`, all skills, hooks, hook tests, agents, scripts, and memory into `~/.claude/`.
- **Rewrites paths to your machine.** The snapshot stores Mac-specific paths as a `__CLAUDE_HOME__` placeholder token; the installer `sed`-replaces it with your resolved `$HOME` in `settings.json` and every hook.
- **Places memory where Claude will read it.** Claude keys durable memory to the sanitized cwd; the installer derives that directory from *your* `$HOME/data/code` (every non-alphanumeric char → `-`), rather than hardcoding the original operator's path.
- **Backs up first.** Any existing file is moved to `*.pre-install` before overwriting — re-running is safe and idempotent.
- **Seeds the citation manifest** at `~/.claude/state/citations.csv` if absent.

## Activate the hooks

!!! note "Hooks need a session reload"
    The Claude Code hook watcher only tracks files that existed at session start. After install, **type `/hooks`** in your session or **restart it** — until then the newly-installed hooks are on disk but not firing.

## Smoke-test

```bash
bash "$HOME/.claude/hooks/tests/run_all.sh"     # expect: 25 pass, 0 fail
```

If tests fail with `got=silent`, you're likely missing the `jq` CLI — see the [Cluster runbook](cluster.md#troubleshooting) for the fix (it applies anywhere).

## Where memory loads

Durable memory only auto-loads when you start Claude with a cwd that matches the installed memory directory — for the operator that's `~/data/code`. Starting elsewhere loads the global `CLAUDE.md` rules, skills, hooks, and agents (those are cwd-independent) but **not** the memory files. See [Make it yours](../adapt/index.md) to point memory at your own working directory.

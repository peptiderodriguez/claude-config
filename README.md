# claude-config

Personal Claude Code configuration for cluster-scale R&D work: global rules, custom skills with auto-fire TRIGGERs, custom agents, mechanical-enforcement hooks, durable memory, and the meta-analyses that produced them.

Snapshot, not live — sync explicitly via `./sync.sh` when you want to capture changes from `~/.claude/`.

> 📖 **Full documentation site** (MkDocs Material): https://peptiderodriguez.github.io/claude-config/ — built from `docs/`. Build locally with `pip install -r requirements-docs.txt && mkdocs serve`. See [Documentation site](#documentation-site).

## What this gives you

A `~/.claude/` install that **auto-fires the right discipline at the right time** across every Claude Code session, without you having to remember the rule. Specifically:

- **10 global skills** with TRIGGER clauses — fire automatically when their phrase patterns appear in the prompt.
- **3 custom agents** with TRIGGER conditions — for adversarial review (`dfg-reviewer`), CLAUDE.md-compliance audit (`frame-auditor`), and dissent meta-check (`dissent-auditor`).
- **13 hooks** — mechanically enforce rules (block destructive commands, inject context on status questions, surface scar-anchored pre-flight checks, etc.).
- **Durable memory** across sessions for the patterns that don't fit in the global CLAUDE.md.
- **Project-portable building blocks** — copy `_rot_exceptions.py` / `audit_xfail_age.py` / `_pre_push_suite_green.sh` into a fresh repo and you've got anti-rot discipline in 5 minutes (the `scaffold-discipline` skill plans this for you).

## What's installed

### Rules (`~/.claude/CLAUDE.md`)

Loaded into every Claude Code session as memory. **Scar-tissue only** — every rule traces to a specific past incident. Sections:

- **Driving philosophies (with falsifiable triggers)** — flywheel-not-pipeline, fix-the-representation, generalization-as-destination, fail-loud, reviewer-proof-in-production, correct-over-expeditious (with 4 banned shortcuts: threshold-gaming / count-padding / tidy-over-true / allowlist-loosening), hacky-vs-clean (retreat to fewer cleaner claims), claims-defended-by-stacks, "while we wait" parallel-fill rhythm.
- **House style** — `AskUserQuestion` always, plan-mode-first, terse, never write `/tmp`, numbered-reply coupling, compaction protocol, "never claim absence from a narrow search" (BANNED phrases + 3-step grep/call-chain protocol), re-derive live state from disk, FIX-to-defaults.
- **Cluster discipline** — never the login node, scancel by job-id only, surface job status proactively, stale-state hygiene, sentinel-after-success, sequential-not-chained-`afterok`, inspect input format before config, 4-state diagnosis (RUNNING/QUEUED/FAILED/STALE-SENTINEL).
- **Subagents** — DEFAULT-DELEGATE for read-heavy work, NEVER blind-trust agent returns, VERIFY ALIVE by notification not polling, DON'T BABYSIT, agents-cannot-write in pool, sandbox-caveat with per-cwd settings.local.json clarification.
- **Statistics + methodology** — benchmark-before-default, wrap helpers don't reimplement, don't double-correct paired designs, assumption manifest before sim/power-calc, verify execution environment, Python over R default.
- **Critique loop** — `/critique` skill is the entry; cross-module composition pass after parallel fan-out; severity-tag + word-budget + N-axes output contract.
- **How the operator works with you (relational)** — counterparty not yes-agent, mirror register, don't catastrophize cluster ops, stakes-flip-side, watch for delegation outpacing scaffolding, don't over-identify.

### Skills (`~/.claude/commands/*.md`) — auto-fire via TRIGGER

| Skill | What it does | Auto-fires when |
|---|---|---|
| `critique` | Multi-agent adversarial review with 3-4 personas; auto-includes Frame-skeptic on grant context; wires `dfg-reviewer` for methodology slot; dissent-auditor meta-check at step 5.5 | User says "review", "critique", "launch [N] adversarial agents" |
| `cluster-traffic` | SLURM queue + partition snapshot (`squeue`, `sinfo`); per-job log-tail flow | "how are the jobs", "what's running", "what's the cluster doing" |
| `orient` | Post-compaction state report; project mode vs vault mode; reads daily-note CLAUDE SESSIONS block | "where are we", "what was I doing", post-compaction context |
| `sessions` | Maintain daily-note `CLAUDE SESSIONS:` block | Session start/end |
| `onboard` | Re-run the meta-analysis methodology if friction patterns re-emerge | "analyze how I use you", "audit my Claude setup" |
| `scaffold-agent` | Bootstrap a new subagent spec with the conventions converged across `dfg-reviewer` / `frame-auditor` / `dissent-auditor` | "scaffold a new agent" |
| `anti-fabrication` | Refuse to invent PMIDs, PDB IDs, UniProt accessions, vendor catalog numbers, etc. — every claim either verified or `[NEEDS X — check Y at Z]` | Mentions of PMID / PDB / UniProt / Addgene / vendor cat / cite |
| `grant-work-mode` | Bundles canonical-headlines (read from project source-of-truth file, NOT hardcoded), stakes-flip-side, no-hedged-claims, reviewer-proof posture | Cwd contains `rlink2026` / `*grant*`, OR prompt mentions DFG / NIH / NSF / submission / reviewer-proof / preregistration |
| `covariate-screen` | Cross-sectional clinical-covariate screen for any feature × sample matrix (proteome / transcriptome / count matrix). Geyer plasma-QC (proteomics-only), Phase-4 confounding sanity, Phase-6 cross-sectional with single-feature-nominal-p-not-actionable rule | "correlate X to covariates", "is plate a confound", "what covariates should I adjust for" |
| `scaffold-discipline` | Plan to bootstrap the drop-in anti-rot tier (`_rot_exceptions.py`, `audit_xfail_age.py`, placeholder-citations scanner, hygiene block, `_pre_push_suite_green.sh`, CI mirroring) into a fresh repo | "set up anti-rot", "bootstrap pre-commit", "scaffold discipline" |

### Agents (`~/.claude/agents/*.md`)

| Agent | Persona / job | Invocation |
|---|---|---|
| `dfg-reviewer` | Adversarial DFG/NIH/NSF grant reviewer who previously denied this group funding. Exacting, not cruel. | Used by `/critique` in grant context; or directly: `Agent(subagent_type="dfg-reviewer", ...)` |
| `frame-auditor` | Audits a transcript against CLAUDE.md meta-rules (stakes-flip-side, delegation-outpacing-scaffolding). Catches drift the user hasn't named yet. | Auto-fire from `session_end_audit.sh` hook when stakes-pin tokens detected; or directly |
| `dissent-auditor` | Audits whether N parallel critique agents converged or stayed independent. Fires at `/critique` step 5.5. | Used by `/critique`; or directly when "have the personas converged?" |

### Hooks (`~/.claude/hooks/*.sh` + wiring in `~/.claude/settings.json`)

| Hook | Event | What it does |
|---|---|---|
| `squeue_inject.sh` | UserPromptSubmit | Injects squeue snapshot on cluster hosts (silent on Mac) |
| `surprise_capture.sh` | UserPromptSubmit | Detects "huh / wait what / aha / TIL" — offers to capture as durable memory once |
| `re_derive_state_inject.sh` | UserPromptSubmit | Detects status/orientation phrasings ("how are the jobs", "stuck?", "any update", "did anything finish") — injects re-derive-from-disk reminder before Claude quotes from a stale summary |
| `scancel_guard.sh` | PreToolUse (Bash) | **DENIES** `scancel -u $USER` (past wiped-libgen scar). Kill by explicit job-id list instead. |
| `pre_sbatch_guard.sh` | PreToolUse (Bash) | Injects scar-anchored pre-flight (env-source, dependency IDs, num-gpus, etc.); **ASKS for confirmation** on portfolio-scale launches (≥2 sbatch + no env-source) |
| `tmp_write_guard.sh` | PreToolUse (Bash / Write / Edit / MultiEdit / NotebookEdit) | **DENIES** writes to `/tmp/*` (highest-scar rule — "dude i thought i told you not to write to tmp" is non-recoverable) |
| `subagent_sandbox_preflight.sh` | PreToolUse (Task / Agent) | Warns when subagent briefings reference paths outside this cwd's `settings.local.json::additionalDirectories` (catches the silent "I need permission" failure mode) |
| `headline_numbers_check.sh` | PostToolUse (Edit / Write) | Per-project opt-in via `<repo>/.claude/headline_numbers_check.yaml`. Fast trigger_paths pre-check skips silently if the edited file doesn't match. When triggered, runs the project's `test_headline_numbers.py` regression — surfaces drift loudly. |
| `pmid_citation_guard.sh` | PostToolUse (Edit / Write / MultiEdit / NotebookEdit) | Per-project or global manifest at `~/.claude/state/citations.csv` (DataFrame: pmid, first_author, year, journal, fixture, used_in, status) joined to cache at `~/.claude/cache/pubmed/<PMID>.json`. Fails loud on mismatch / missing row / missing cache. Composes with the `anti-fabrication` skill (skill = generation-time policy; hook = write-time mechanical enforcement). Seed via `~/.claude/scripts/seed_pubmed_cache.py <PMID>`. |
| `post_critique_dissent.sh` | PostToolUse (Skill=critique) | Reminds Claude to run dissent-auditor before finalizing the critique synthesis |
| `postcompact_resume.sh` | PostCompact | Injects post-compaction state snapshot + nudge toward `/orient` skill |
| `session_digest.sh` | SessionEnd | Appends one-line digest to today's daily note |
| `session_end_audit.sh` | SessionEnd | Scans today's daily note for stakes-pin / delegation tokens; appends frame-auditor reminder marker if found |

### Durable memory (`~/.claude/projects/<sanitized-cwd>/memory/`)

Loaded for sessions whose cwd sanitizes to the installed memory dir (the operator's is `~/data/code/`; `install.sh` derives it from your `$HOME`). Index in `MEMORY.md`. 9 files (filenames use underscores): `user_psychological_style`, `feedback_house_style`, `feedback_critique_loop`, `feedback_use_agents`, `feedback_slurm_discipline`, `feedback_no_fabricated_panels`, `project_pool_and_workflow`, `process_onboard_methodology`, `stop_parsing_restructure_the_substrate`.

## How auto-firing works (key examples)

**Example 1 — "how are the jobs?" → mechanical state-injection.**
User: *"how are the jobs going?"*
Hook chain (UserPromptSubmit):
1. `squeue_inject.sh` — fires `squeue -u $USER`, injects current job table as context
2. `re_derive_state_inject.sh` — detects "how are the jobs" → injects "RE-DERIVE STATE FROM DISK, don't quote from stale summary. squeue / sentinel mtime / 4-state diagnosis."

Claude then answers grounded in disk state, not its own prior message.

**Example 2 — Agent tries to write `/tmp/scratch.py` → mechanical block.**
Tool call: `Write(file_path="/tmp/scratch.py", ...)`
Hook (PreToolUse, Write matcher): `tmp_write_guard.sh` returns `permissionDecision: "deny"` with reason citing the scar. Write fails loudly; Claude redirects to `<project>/scripts/`.

**Example 3 — "review the migration plan" → `/critique` skill auto-fires.**
User: *"review the migration plan for issues / bugs / inefficiencies"*
- The TRIGGER clause on `~/.claude/commands/critique.md` matches "review" + the verbatim checklist
- Skill dispatches 3 parallel adversarial agents with personas (methodology, engineering, tests/docs)
- Grant context auto-includes the Frame-skeptic persona
- Step 5.5 dispatches `dissent-auditor` to check convergence
- Synthesis: blockers + convergent concerns + persona-specific + "what they agreed was fine" + Claude's independent take

**Example 4 — Edit to `rlink2026/biology_for_grant.md` → headline regression auto-check.**
Tool call: `Edit(file_path="/Volumes/pool-mann-<operator>/code_bin/rlink2026/biology_for_grant.md", ...)`
Hook (PostToolUse, Edit matcher): `headline_numbers_check.sh`
1. Walks up to repo root (`rlink2026/`)
2. Reads `<repo>/.claude/headline_numbers_check.yaml` — finds trigger_paths matching the edited file
3. Runs `scripts/test_grant_headline_numbers.py`
4. If the test fails (a locked number was drifted) → emits loud warning context: *"⚠ HEADLINE-NUMBERS REGRESSION on edit to <file>. Likely cause: locked headline changed. Re-derive from canonical CSV, then either update the test (if intentional + documented) or revert. Do NOT silently re-edit to match — bakes drift into the canon."*

**Example 5 — Subagent briefing references unmounted pool path → preflight warning.**
Tool call: `Task(prompt="Read /fs/<pool>/<project>/CLAUDE.md and report")` (HPC path that won't propagate via the Mac cwd's settings)
Hook (PreToolUse, Task matcher): `subagent_sandbox_preflight.sh`
- Scans the prompt for absolute paths under `/Volumes/`, `/fs/`, `/tmp/`, `~/.claude/projects/`
- Checks each against this cwd's `.claude/settings.local.json::additionalDirectories`
- The `/fs/...` path isn't covered → emits warning: *"⚠ Subagent briefing references paths NOT in this cwd's additionalDirectories. The subagent will fail silently with 'I need permission.' Before dispatching: (1) add the prefix to <local settings.local.json> — note the user-global ~/.claude/settings.local.json does NOT propagate to subagents, (2) OR pre-extract the data inline, (3) OR scope the agent to paths it CAN read."*

## Install on a fresh machine

```bash
git clone <repo-url> ~/code/claude-config
cd ~/code/claude-config
./install.sh   # copies files into ~/.claude/, prompts before overwriting
```

After install, reload the session to activate the hook watcher (see [Notes](#notes)).

## Sync changes back from `~/.claude/` to this repo

When you've edited a file in `~/.claude/` (e.g. via Claude Code itself updating settings.json, or you tweaked a skill) and want to capture the change:

```bash
cd ~/code/claude-config
./sync.sh    # copies live ~/.claude/ files back into the repo
git diff     # review changes
git add -A && git commit -m "sync: <what changed>"
git push     # if remote configured
```

The sync covers `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, all 13 hooks, the hook test harness (`hooks/tests/`), all 10 custom skills (whitelist in `sync.sh:14` — update when adding new skills), all 3 agents, `scripts/`, the durable-memory dir (derived from `$HOME/data/code`), and the vault meta-analyses.

## Documentation site

A MkDocs (Material) site in `docs/` reorganizes everything here into a navigable form — install runbooks, the philosophy tour, the auto-firing worked examples, and browsable Skill/Hook/Agent/Memory catalogs (each row links to the source file).

```bash
pip install -r requirements-docs.txt
mkdocs serve            # local preview at http://127.0.0.1:8000
mkdocs gh-deploy        # publish to the gh-pages branch (or let .github/workflows/docs.yml do it on push)
```

Fill in `site_url`/`repo_url` in `mkdocs.yml` before deploying. This README stays the standalone landing doc; the site is the same content reorganized for browsing.

## Provenance

Initial bootstrap: 2026-05-24 — meta-analysis of ~5,270 user messages + 6 pool `CLAUDE.md` files + 5 `/analyze` slash-commands. See `meta_claude_usage_2026-05-24.md` + `_v3.md` for the operator-platform reframe.

2026-05-31 to 2026-06-01 expansion: deep mining across all active project CLAUDE.mds (minibinder + alphaquant + xldvp_seg + rlink2026 + ehr_proteomics + ehr_r046) + 18 conversation_*.md scratchpads + the most-recent daily notes — producing the driving-philosophies section, 5 new hooks (`tmp_write_guard`, `subagent_sandbox_preflight`, `pre_sbatch_guard`, `re_derive_state_inject`, `headline_numbers_check`), and 4 new skills (`anti-fabrication` hoisted from minibinder, `grant-work-mode`, `covariate-screen`, `scaffold-discipline`). Adversarial /critique pass surfaced 3 blockers + 6 serious + frame-skeptic-flagged decoration, all corrected in-session.

## Notes

- **Private repo recommended.** `memory/` references colleagues, project paths, and the lab's internal patterns; `CLAUDE.md` includes psychological-style notes that aren't public; nothing is a secret but it's personal context.
- **The hooks need a session reload after install.** Open `/hooks` once in Claude Code or restart the session — the watcher only tracks files that existed at session start.
- **Skills appear in the available-skills list automatically.** TRIGGERs at the top of each skill description determine auto-firing; you can also invoke explicitly as `/skill-name`.
- **Custom agents (frame-auditor, dissent-auditor, dfg-reviewer) require explicit registration** in the model's agent type registry — they may not appear as `subagent_type` options out of the box. If `Agent(subagent_type="dfg-reviewer", ...)` returns "agent type not found", invoke as `subagent_type="general-purpose"` with the agent's prompt body embedded inline.

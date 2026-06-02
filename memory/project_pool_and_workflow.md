---
name: project-pool-and-workflow
description: "Pool mount + cluster cheatsheet, repo layout under code_bin, multi-session workflow pattern, Obsidian vault role, skill candidates open"
metadata: 
  node_type: memory
  type: project
  originSessionId: a5e7d312-de62-4697-a680-4de8f458852a
---

## Pool mount symmetry

Same storage, two paths depending on host:
- **Mac:** `/Volumes/pool-mann-<operator>/`
- **HPC nodes:** `/fs/pool/pool-mann-<operator>/`

Daily notes use the HPC form (sessions run on cluster). Local Claude Code uses the Mac form. Normalize the prefix when following paths across contexts.

## Repo layout under `code_bin/`

Notable repos with their own `CLAUDE.md`:

| Repo | Purpose | `/analyze` | Custom agents |
|---|---|---|---|
| `xldvp_seg` | Spatial segmentation, DVP, LMD export | yes (1344-line) | 4 (annotation-trainer, detection-dev, lmd-export, pipeline-runner) |
| `alphaquant` | Tree-based proteomics quant | — | — |
| `minibinder` | De novo binder design (RFdiffusion+ProteinMPNN+BindCraft+Boltz) | yes | — |
| `ehr_proteomics_analysis` | DIA proteomics pipeline | yes + `/clinical_eda` | — |
| `ehr_r046` | EHR-linked proteomics | yes | — |
| `rlink2026` | psychiatric biomarker grant project | grant-specific subdir CLAUDE.md | — |
| `aq_runner` | Batch wrapper around alphaquant | — | — |

Per-dataset analyses live under `/Volumes/pool-mann-<operator>/DIA_output/<dataset>/scripts/`, NOT inside packages. Shared scripts in `/Volumes/pool-mann-<operator>/DIA_output/_shared/`.

## Slurm partitions (`b_mann` account)

| Partition | Hardware | Use |
|---|---|---|
| `p.hpcl93` | 19 nodes, 256 CPU / 760G / 4× L40S | Heavy GPU, DIA-NN libgen, segmentation detection |
| `p.hpcl8` | 55 nodes, 24 CPU / 380G / 2× RTX 5000 | CPU work, msconvert/Singularity, interactive dev |
| `p.hpcl92` | CPU partition | CPU-only batch |

`b_mann` cannot submit to H100 or A40 — they reject the account. Time limit 42 days on 93 and 8.

## Multi-session workflow

They runs **3–5 concurrent Claude Code sessions** in parallel, one per task, often against different repos. Session names are short tmux-style labels (`grant`, `csf3`, `rlink`, `minibinder2`, `marcpos2`, `senescence`). Same repo can host multiple task-scoped sessions — e.g. `alphaquant` hosted `csf3` + `rlink` + `marcpos2` on May 23.

The daily note at `$HOME/data/code/obsidian_base/<DayOfWeek MMM DD YYYY>.md` opens with:
```
- CLAUDE SESSIONS:
    - <session-name>: <repo-path>
```
This is their inter-session working memory. If they references a session name without a path, check today's or yesterday's daily note to resolve it.

"What's NOT in this plan" carve-outs in daily notes are boundary markers for *other sessions'* concurrent work — respect them; don't touch the carved-out scope.

## Obsidian vault role

`$HOME/data/code/obsidian_base` is their daily-notes vault. Daily notes capture Claude session indices + inline feedback/decisions from those sessions. They also drops drafts there (e.g. `meta_claude_usage_2026-05-24.md`, `critique_skill_v1.md`) for their own review before installing.

## Subagent sandbox caveat (load-bearing)

Subagents spawned from a Claude Code session **inherit the parent's sandbox scope**. They cannot read `/Volumes/pool-mann-<operator>/` or `~/.claude/projects/` unless the parent project has those in `.claude/settings.local.json::additionalDirectories`. Before delegating, either:
- Add the required directories to settings.local.json, OR
- Pre-extract data to the project root, OR
- Symlink the dirs into the working tree.

Confirmed failure: 2026-05-24 — two subagents both denied access to pool + projects dirs and reported "I need permission" instead of completing. Main session had access; subagents didn't.

## Project CLAUDE.md global-pointer status

Projects whose `CLAUDE.md` has been updated with the global-pointer block (catalog of auto-loaded global skills + project-specific subset of cross-cutting rules from the meta-analysis):

| Project | Path | Status | Notes |
|---|---|---|---|
| minibinder | `/Volumes/pool-mann-<operator>/code_bin/minibinder/CLAUDE.md` | **done 2026-05-24** | Emphasizes pre-flight (`perturb_phos doctor`), Frame-skeptic on target selection, cluster visibility (this project is the local origin of /cluster-traffic) |
| rlink2026 | `/Volumes/pool-mann-<operator>/code_bin/rlink2026/CLAUDE.md` | **done 2026-05-24** | Emphasizes PDF-grep panel verification, stakes flip-side (grant-funding optimization), `dfg-reviewer` (built from this project), dual-roots subagent sandbox |
| xldvp_seg | `/Volumes/pool-mann-<operator>/code_bin/xldvp_seg/CLAUDE.md` | not yet | Has its own substantive CLAUDE.md (318 lines) + custom agents; adding pointer block would be additive |
| alphaquant | `/Volumes/pool-mann-<operator>/code_bin/alphaquant/CLAUDE.md` | not yet | Has 69-line CLAUDE.md from prior |
| ehr_proteomics_analysis | `/Volumes/pool-mann-<operator>/code_bin/ehr_proteomics_analysis/CLAUDE.md` | not yet | Has 112-line CLAUDE.md from prior |
| ehr_r046 | `/Volumes/pool-mann-<operator>/code_bin/ehr_r046/CLAUDE.md` | not yet | Has 120-line CLAUDE.md from prior |
| `<collab>_collab` / `<collab>_phase2` | `/Volumes/pool-mann-<operator>/code_bin/rlink2026/<collab>_*/CLAUDE.md` | not yet | Sub-project CLAUDE.md files under rlink2026 |

Add the pointer block to a project's CLAUDE.md only when actively working in that project — skip dormant ones. Pattern documented in `[[process-onboard-methodology]]` Phase 6.5.

## Open skill candidates (2026-05 snapshot)

- **`/critique`** — drop-in skill drafted at `$HOME/data/code/obsidian_base/critique_skill_v1.md`. Copy to project `.claude/commands/` or global `~/.claude/commands/`.
- **`/cluster-traffic`** — hoist `minibinder`'s `perturb_phos traffic` to a shared skill. Wraps `squeue`, `sinfo`, partition availability. Addresses #1 friction (cluster opacity). `xldvp_seg/scripts/system_info.py` does most of it already.
- **`/sessions`** — auto-emit/maintain the daily-note `CLAUDE SESSIONS:` block on session start/stop. Removes manual book-keeping.
- **`/scaffold-analyze <project>`** — generate a stub `analyze.md` following the convention they's converged on across 4 repos.
- **Stale-state pre-commit hook** — flag `.aq_runner_done` / `--dependency` / `_complete.json` files older than latest input touch. "Stale" appears 53× in one transcript.
- **`/verify-panel`** — global PDF-grep panel-verification skill, hoisted from `ehr_proteomics_analysis/clinical_eda.md` (see [[feedback-no-fabricated-panels]]).

Related: [[feedback-house-style]], [[feedback-slurm-discipline]], [[feedback-use-agents]], [[feedback-critique-loop]]

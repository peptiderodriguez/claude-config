---
name: feedback-slurm-discipline
description: "the lab cluster usage rules baked in from prior incidents — login-node ban, scancel safety, stale-state hygiene, job-status visibility"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a5e7d312-de62-4697-a680-4de8f458852a
---

**Rules — apply on any project using the the lab cluster:**

1. **Never run heavy compute on the login node.** Submit via Slurm always. Verbatim correction: *"do not use the login node to run jobs."* Default partition for CPU: `p.hpcl8 --exclusive`. GPU: `p.hpcl93` (L40S). msconvert/Singularity must run on `p.hpcl8`. `b_mann` account can't submit to H100/A40.

2. **Never `scancel -u $USER`** — kill by job-id list. *"`scancel -u $USER` is destructive across cubes. Hard lesson from the bm_mk_e2e_pipeline_test debug session that wiped a 7-hour libgen."*

3. **Pre-submission checklist (every sbatch):** `--dependency` job IDs aren't stale, `--num-gpus` matches allocation, Python path is the env's interpreter (not bare `python`), input file paths exist.

4. **Post-submission verification (within 30s):** check first output lines for startup, look for "Starting N GPU workers", tile speeds ~3-15s (not 2 min, which would mean only 1 GPU is actually working).

5. **Never combine the two parallelism layers** — outer Slurm sweep + inner `--aq-strategy slurm_array` exhausts the array-job quota. Pick one.

6. **Persist scripts under `<project>/scripts/` or `<dataset>/scripts/`, logs under `_shared/slurm_logs/`. Never `/tmp`.** Verbatim May 16 correction: *"dude i thought i told you not to write to tmp - that is non-recoverable."* This rule has been re-violated — keep it active.

7. **Stale-state hygiene** is a top-3 concern (the word "stale" appears 53× in one transcript). `.aq_runner_done` sentinels must be touched only AFTER `ContrastResult.success == True`. Before trusting "skip if exists" logic, verify sentinel mtime vs latest-input mtime.

8. **Cluster visibility is friction-#1.** They polls job status repeatedly per day (3+ distinct *"how are the jobs"* questions in one May-17 session). Proactively check `squeue -u $USER` and surface state before they asks. The `minibinder` repo's `perturb_phos traffic` subcommand is the existing pattern to copy — wraps queue + partition availability into one snapshot.

**Why:** Each rule is a scar from a prior multi-hour incident. The CLAUDE.md files in `xldvp_seg`, `ehr_proteomics_analysis`, and `minibinder` all encode these (sometimes verbatim). Consolidating here so new projects inherit without re-discovering.

**How to apply:**
- Before any `sbatch`, `srun`, or background compute, run the pre-submission checklist out loud.
- If asked to "kill jobs", insist on job IDs — refuse `-u $USER` even if the user types it.
- For long-running pipelines, periodically (every few turns) check `squeue` and surface status proactively.
- A `/cluster-traffic` skill that bundles this is open (see [[project-pool-and-workflow]] skill candidates).

Related: [[project-pool-and-workflow]], [[feedback-house-style]]

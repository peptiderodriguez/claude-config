# Skills (11)

Custom skills live in `commands/*.md` and **auto-fire** when a prompt matches the TRIGGER clause at the top of each file. You can also invoke any of them explicitly as `/<name>`.

!!! note "The file is authoritative"
    This table summarizes; the TRIGGER clauses and step sequences in each `commands/<name>.md` are the source of truth. Browse them at `https://github.com/peptiderodriguez/claude-config/tree/main/commands`.

Grouped by **portability** — if you're adapting this repo, tier 1 transfers to anyone, tier 2 to any researcher, and tier 3 is HPC/omics-specific (take or drop as a unit).

## Tier 1 — General (any user)

| Skill | What it does | Auto-fires when |
|---|---|---|
| `critique` | Multi-agent adversarial review (3–4 personas); auto-adds a Frame-skeptic in grant context; wires `dfg-reviewer` for the methodology slot; `dissent-auditor` meta-check at step 5.5 | "review", "critique", "launch [N] adversarial agents" |
| `orient` | Post-compaction state report; project mode vs vault mode; reads the daily-note CLAUDE SESSIONS block | "where are we", "what was I doing", post-compaction context |
| `sessions` | Maintains the daily-note `CLAUDE SESSIONS:` block | Session start / end |
| `onboard` | Re-runs the meta-analysis methodology when friction patterns re-emerge | "analyze how I use you", "audit my Claude setup" |
| `scaffold-agent` | Bootstraps a new subagent spec with the converged conventions | "scaffold a new agent" |
| `scaffold-discipline` | Plans the drop-in anti-rot tier (rot-exceptions, xfail-age audit, placeholder-citation scanner, suite-green gate, CI mirroring) into a fresh repo | "set up anti-rot", "bootstrap pre-commit", "scaffold discipline" |
| `scaffold-analyze` | Generates a project's `/analyze` command — an interactive pipeline UI that guides novice/pro users through the workflow; interviews you and writes `<project>/.claude/commands/analyze.md` from the convention (see [Writing an /analyze guide](../adapt/analyze-pattern.md)) | "scaffold an analyze command", "give my pipeline a Claude UI" |

## Tier 2 — Research-general (any scientist)

| Skill | What it does | Auto-fires when |
|---|---|---|
| `anti-fabrication` | Refuses to invent PMIDs / PDB IDs / UniProt accessions / catalog numbers — every claim verified or `[NEEDS X — check Y at Z]` | mentions of PMID / PDB / UniProt / Addgene / vendor cat / cite |
| `grant-work-mode` | Canonical-headlines (from a project source-of-truth file), stakes-flip-side, no-hedged-claims, reviewer-proof posture | cwd matches `*grant*`, or prompt mentions DFG / NIH / NSF / reviewer / preregistration |

## Tier 3 — Domain & infra-specific (HPC + omics)

| Skill | What it does | Auto-fires when |
|---|---|---|
| `cluster-traffic` | SLURM queue + partition snapshot (`squeue`, `sinfo`); per-job log-tail flow | "how are the jobs", "what's running", "what's the cluster doing" |
| `covariate-screen` | Cross-sectional clinical-covariate screen for any feature × sample matrix; Geyer plasma-QC (proteomics); confounding sanity check | "is plate a confound", "what covariates should I adjust for" |

See [How auto-firing works](../philosophy/auto-firing.md) for `critique` and the hook chain in action.

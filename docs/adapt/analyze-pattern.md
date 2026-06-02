# Writing an `/analyze` pipeline guide

`/analyze` is the operator's most-reused convention: a **project-scoped** slash command (`<project>/.claude/commands/analyze.md`) that is *the pipeline's front door*. A user — novice or pro — types `/analyze` and gets walked through the whole workflow interactively, adapted to their experience level and their machine. The operator converged on the same skeleton independently across four unrelated pipelines (imaging segmentation, binder design, two clinical-omics repos), which is why it's worth writing down once here.

It is **not** in this repo's `commands/` (it's per-project, not global) and it is distinct from [`/onboard`](meta-analysis.md): `/onboard` builds your *config*; `/analyze` guides users through a *pipeline*.

## The mandatory startup sequence

Every `/analyze` begins the same way — encode this at the very top of the file, marked CRITICAL so it isn't skipped:

1. **Run system/environment detection silently** (don't show raw output).
2. **Greet warmly**, one sentence naming the pipeline and what it does end-to-end.
3. **Ask experience level** via `AskUserQuestion` — *always ask, never infer* ("New to this pipeline" / "Experienced"). The user can switch mid-session.
4. **Ask for the key input(s)** (file/dir path, target, cohort) via `AskUserQuestion`.
5. **Proceed through the phases.**

> A new user who just installed the package types `/analyze` and expects to be guided. Don't get derailed by prior conversation context or substitute a status dump for the actual workflow.

## Non-negotiables

- **`AskUserQuestion` for every question** — multiple-choice, confirmations, and free-text alike (free-text rides the auto "Other" option). Never solicit input as inline prose. Batch up to 4 independent questions.
- **Tone: concise, colleague-not-textbook.** Don't narrate; do. Show a command briefly, run it. Explain things as they come up, not all upfront.

## Guiding Principles (the three roles the assistant plays)

State these near the top so the assistant's behavior is principled, not ad-hoc:

- **Planner** — choose sensible defaults from hardware + data metadata. Don't over-ask when the answer is obvious.
- **Guardrail** — enforce the inspect-before-you-act invariants that prevent silent corruption (e.g. inspect input format before writing any config; confirm the destructive/expensive step before launching). This is where the project's scar-tissue rules live.
- **Collaborator** — users run in very different settings (**SLURM cluster / workstation / laptop**). **Never assume a cluster.** Detect the environment and adapt: if there's no scheduler, drop to direct commands with a sane resource cap; don't hallucinate partitions or catastrophize local runs.

## Phase 0 — Environment + experience level

The universal first phase:

- **Install preflight (optional but powerful):** if the package isn't installed, just install it — detect platform/GPU, confirm once via `AskUserQuestion`, run the right installer silently with high-level progress, surface real errors with known fallbacks. The user shouldn't need to know about CUDA/MPS/conda.
- **Detect environment** (cluster / workstation / laptop) and report briefly with a concrete recommendation. On shared clusters, respect etiquette caps; on local machines, **ask** what fraction of the machine to use (never default).
- **Ask experience level** and adapt verbosity: *beginner* → define jargon inline, show expected outputs, explain each step as you reach it; *advanced* → concise, "command → looks good? → run."

## Phases 1…N — the pipeline itself

One phase per major pipeline stage. Each phase:

- Shows the command(s) briefly before running (give both the cluster and the local form when they differ).
- Gates decisions through `AskUserQuestion` (cell type, threshold, resolution, "looks good?").
- States the expected output so the user knows what success looks like.
- Carries **adaptive feedback**: after a stage, inspect the result and suggest the next move (e.g. "too many objects → raise threshold," "low F1 → try the deep-feature variant"). This is what makes it feel like an expert is watching.

## Analysis catalog (at the end)

Put the full toolbox of optional/advanced commands at the **bottom**, and only surface it when the user asks "what can this do?" — keep the main flow linear.

## Minimal skeleton to copy

The repo ships a ready-to-fill version at [`templates/analyze.template.md`](https://github.com/peptiderodriguez/claude-config/blob/main/templates/analyze.template.md) — copy it to `<your-project>/.claude/commands/analyze.md` and replace the `<FILL IN …>` blanks. Inline:

```markdown
You are the **<project> pipeline assistant**. Guide the user through <one-line end-to-end>.

CRITICAL — every time /analyze is invoked: (1) detect system silently,
(2) greet warmly, (3) AskUserQuestion experience level, (4) AskUserQuestion inputs,
(5) proceed through phases. Never substitute a status dump for the workflow.

Always use AskUserQuestion for every question. Tone: concise, colleague-not-textbook.

## Guiding Principles
**Planner:** sensible defaults from hardware + metadata.
**Guardrail:** <inspect-before-act invariants for this pipeline>.
**Collaborator:** cluster / workstation / laptop — detect, never assume cluster.

## Phase 0 — Environment + experience level
<install preflight; detect env; resource choice; ask beginner/advanced>

## Phase 1 … N — <pipeline stages>
<command (cluster + local) · AskUserQuestion gates · expected output · adaptive feedback>

## Analysis catalog
<full toolbox — shown only on request>
```

!!! tip "Want this generated?"
    The `meta_claude_usage` notes flag a `/scaffold-analyze` skill — a generator that stubs a project's `analyze.md` from this skeleton — as the highest-leverage unbuilt tool. It isn't in this repo yet; see [Provenance](../provenance.md). Ask if you'd like it built.

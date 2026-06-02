Bootstrap a project's `/analyze` command — the pipeline's interactive front door that guides a user (novice or pro) through the whole workflow. Interviews you about your pipeline and writes `<project>/.claude/commands/analyze.md` from the operator's converged convention (the same skeleton across several of the operator's pipelines). See the `analyze-pattern` docs guide + `templates/analyze.template.md`.

TRIGGER when user asks: "scaffold an analyze command", "make an /analyze for this pipeline", "give my pipeline a Claude UI", "add a guided entry point for X", "create an analyze.md for this repo", "turn this CLI into a guided workflow". Also TRIGGER proactively when working in a project repo that has a runnable pipeline/CLI but no `.claude/commands/analyze.md` (offer once — don't nag).

SKIP when: an `analyze.md` already exists for this project (use Edit to refine it, don't regenerate); the user wants a one-off guided run right now (just guide them inline — no file needed); the project has no real multi-step pipeline (a single command doesn't need an `/analyze` front door).

## Sequence

1. **Inspect the project first — don't ask what you can detect.** Read `README` / `pyproject.toml` / the CLI entrypoint / `scripts/` to propose defaults: project name, the end-to-end one-liner, the install + system-detection commands, and a first guess at the pipeline stages. Carry these as pre-filled options into the questions below.

2. **Batched `AskUserQuestion` #1 — identity + inputs:**
   - **Project name** — as it should greet the user.
   - **One-line end-to-end** — raw input → … → final output.
   - **Key input(s)** the user supplies (file/dir path, target, cohort).
   - **System-detection command** to run silently at startup (e.g. `python scripts/system_info.py --json`, or "none").

3. **Batched `AskUserQuestion` #2 — pipeline shape:**
   - **Ordered stages** (Phase 1…N names) — free-text list.
   - **Guardrail invariants** — the inspect-before-act checks that prevent silent corruption (e.g. "inspect input format before writing config"; "confirm the expensive/destructive step before launching").
   - **Environments** to support: cluster / workstation / laptop (which apply?).

4. **Batched `AskUserQuestion` #3 — polish:**
   - **Install preflight?** (Y/N; if Y, the install command.)
   - **Experience adaptation** — beginner-verbose + advanced-concise (default on)?
   - **Analysis catalog** — optional/advanced commands to list at the bottom, or skip.

5. **Generate the file.** Start from `templates/analyze.template.md`, fill every `<FILL IN …>` from the answers, delete the HTML comments, and write to `<project>/.claude/commands/analyze.md`. Preserve the canonical skeleton exactly:
   - **Startup sequence** (detect silently → greet → `AskUserQuestion` experience → `AskUserQuestion` inputs → phases), marked CRITICAL.
   - **`AskUserQuestion` for every question** (free-text via the auto "Other").
   - **Guiding Principles**: Planner / Guardrail / Collaborator (never assume a cluster).
   - **Phase 0** (environment + experience level), then **one phase per stage** with command (cluster + local forms) · gate · expected output · adaptive feedback.
   - **Analysis catalog at the end**, surfaced only on request.

6. **Confirm + hand off.** Commands auto-list (no `/hooks` reload needed for skills), so tell the user to type `/analyze` in that project to test, and offer a first dry run together. **If a stage's command is unknown, write a `<FILL IN>` placeholder rather than inventing one** (anti-fabrication — never fabricate a command the pipeline may not have).

## Conventions

- Front-load TRIGGER/SKIP at the top of the generated file — the skill listing truncates around 100 chars, so a buried trigger is undiscoverable.
- Generated tone: concise, colleague-not-textbook; one question at a time per field; run detection silently; show commands briefly before running.
- The [`analyze-pattern`](../docs/adapt/analyze-pattern.md) guide and `templates/analyze.template.md` are the source of truth — keep the generated file consistent with them.

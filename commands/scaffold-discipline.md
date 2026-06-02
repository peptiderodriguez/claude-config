---
name: scaffold-discipline
description: Bootstrap minibinder's drop-in anti-rot tier into a fresh the operator repo. Creates `.rot-exceptions.yaml` (dated-expiry-only deferrals, fail-closed), `scripts/_rot_exceptions.py` (shared loader), `scripts/audit_xfail_age.py` (90d xfail budget), `placeholder-citations-audit` hook (`[NEEDS CITATION]` / `[PENDING]` / `[FIXME]` / `[TODO CITATION]` scanner), the pre-commit-hooks v5.0.0 hygiene block, ruff config, `scripts/_pre_push_suite_green.sh` (commit-pinned suite-green stamp gate), and the matching GitHub Actions jobs so `--no-verify` surfaces in PR checks.
trigger: When the user says "scaffold discipline", "set up anti-rot for this project", "bootstrap pre-commit", "set up CI mirroring", "I'm starting a new pipeline repo", "drop in the operator's discipline conventions", or starts work in a fresh repo under `code_bin/` that lacks `.pre-commit-config.yaml`.
---

# Scaffold discipline skill

Drop minibinder's drop-in anti-rot tier into a new repo. The skill is a **planner + step-by-step**: it surfaces the exact files to write, the canonical sources to copy from, and the matching CI stanzas — it does NOT execute writes itself. The user (or a follow-up turn) writes the files.

Canonical source repo: `/Volumes/pool-mann-<operator>/code_bin/minibinder/`. Every file referenced below is verified to exist there as of 2026-05.

## Sequence

### 1. Verify prerequisites (cwd reads)

Run these in parallel, no writes:

- `ls -la .pre-commit-config.yaml pyproject.toml .github/workflows/ scripts/ 2>&1`
- `git rev-parse --show-toplevel` (confirm cwd is a git repo root; if not, refuse)
- `grep -E '^\[tool\.ruff' pyproject.toml 2>/dev/null` (does ruff config already exist?)

Report what's already present. The scaffold is additive — never overwrite an existing `.pre-commit-config.yaml`; merge into it.

### 2. Batched `AskUserQuestion` — which tiers

Single call, up to 4 questions:

- **Drop-in tier (always on)** — confirm: hygiene + ruff + xfail-age + placeholder-citations + `_rot_exceptions.py` + `_pre_push_suite_green.sh`. (Default: yes; skip if user already said yes in the prompt.)
- **Failure-modes-log convention** — opt-in. Adds `docs/failure_modes_log.md` + `scripts/failure_log_coverage.py` (every `OPEN`/`MITIGATED` entry must declare an `auto-detector:` field). Source: `minibinder/scripts/failure_log_coverage.py`.
- **Locked-holdout pattern** — opt-in. Adds `scripts/audit_holdout_no_peek.py` + a `docs/calibration_holdout_<DATE>.yaml` stub. Only useful if the project will have validation fixtures w/ train-test discipline. Source: `minibinder/scripts/audit_holdout_no_peek.py`.
- **Schema-default audit** — opt-in. Adds `scripts/audit_schema_defaults.py` — only useful if the project has a `src/<pkg>/config_schema.py` with `FieldSpec`-style defaults to keep in sync with a `docs/publication_bars.yaml`. Source: `minibinder/scripts/audit_schema_defaults.py`.

### 3. Emit the write plan (per opted-in tier)

For each file below, surface a concrete instruction shaped like:

> Create `<cwd>/scripts/_rot_exceptions.py` by copying `/Volumes/pool-mann-<operator>/code_bin/minibinder/scripts/_rot_exceptions.py` verbatim. The file is project-agnostic — no edits needed (the loader resolves `REPO_ROOT = Path(__file__).resolve().parents[1]` dynamically).

#### Drop-in tier files (always)

| Target path (cwd-relative) | Source (verbatim copy) | Edits needed |
|---|---|---|
| `scripts/_rot_exceptions.py` | `minibinder/scripts/_rot_exceptions.py` | None — project-agnostic (resolves repo root via `__file__`). |
| `.rot-exceptions.yaml` | `minibinder/.rot-exceptions.yaml` lines 1-30 (header doc + empty `exceptions:` list); strip the historical RESOLVED entries (lines 31-91). | Replace `# Hook ids:` block with the subset the project actually installs. Keep `xfail_age`, `placeholder_citations`. Add others only if opted-in. |
| `scripts/audit_xfail_age.py` | `minibinder/scripts/audit_xfail_age.py` | None — pure AST, imports only stdlib + `_rot_exceptions`. `MAX_AGE_DAYS = 90` is intentional; leave it. |
| `scripts/citation_audit.py` (placeholder scanner only) | `minibinder/scripts/citation_audit.py` — the `_PLACEHOLDER_TOKENS` tuple at line 89 + `_scan_placeholders` at line 98 + the `--fail-on-placeholder` arg-parser branch | If the project doesn't need PMID auditing yet, ship a TRIMMED version with only the placeholder scanner. Tokens: `[NEEDS CITATION]`, `[PENDING]`, `[FIXME]`, `[TODO CITATION]`. **Do NOT include `[PENDING CURATOR]`** — that token is a curator sentinel, not a placeholder; minibinder explicitly removed it on 2026-06-01 (issue #88) because gating commits on it blocked every commit while any onboarded-but-unlaunched template existed. See `minibinder/scripts/citation_audit.py:89-105` for the verbatim rationale and memory `[[never-degrade-citation-detection]]`. |
| `scripts/_pre_push_suite_green.sh` | `minibinder/scripts/_pre_push_suite_green.sh` | None for the script itself. BUT — the script depends on `results/_suite_green_stamp.json` being produced by *some* CI job. Either (a) emit a placeholder `scripts/_suite_green_gate.sbatch` if the project will use SLURM, OR (b) note that until the gate-producer exists, the pre-push hook will block every push — operator should run a one-shot `python -c 'import json; json.dump({"commit": "<HEAD>", "tree_dirty_files": 0, "failures": 0}, open("results/_suite_green_stamp.json","w"))'` after each green local test run. Flag this trade-off explicitly. |
| `.pre-commit-config.yaml` | Use `minibinder/.pre-commit-config.yaml` lines 1-77 (header doc + `default_install_hook_types: [pre-commit, pre-push]` + hygiene block + ruff block) as the skeleton. APPEND only the local hooks the user opted into. | Strip the project-internal doc comment lines 1-42; replace with a one-line header naming the current project. The `default_install_hook_types: [pre-commit, pre-push]` line at minibinder line 43 is **load-bearing** — keep it so a plain `pre-commit install` wires the pre-push hook too. |
| `pyproject.toml` (ruff config) | If pyproject lacks `[tool.ruff]`, add: `[tool.ruff] line-length = 100, target-version = "py310"` (mirror minibinder convention). | Match the ruff-pre-commit `rev: v0.7.4` pin in the pre-commit config. |

#### Pre-commit local hook stanzas (paste into `.pre-commit-config.yaml` under `- repo: local; hooks:`)

```yaml
      - id: xfail-age-audit
        name: anti-rot — @pytest.mark.xfail must include since=YYYY-MM-DD strict=...
        entry: python scripts/audit_xfail_age.py
        language: system
        files: ^tests/.*\.py$
        pass_filenames: false

      - id: placeholder-citations-audit
        name: anti-rot — placeholder citation tokens in fixtures/configs
        entry: python scripts/citation_audit.py
        args: [--no-fetch, --inventory-only, --fail-on-placeholder, --doc-pattern, /nonexistent/*.md]
        language: system
        files: >
          (?x)^(
            tests/fixtures/.*\.yaml|
            config/.*\.yaml|
            runs/[^/]+/config_.*\.yaml
          )$
        pass_filenames: false

      - id: suite-green-pre-push
        name: "require suite-green stamp at HEAD before push"
        entry: bash scripts/_pre_push_suite_green.sh
        language: system
        stages: [pre-push]
        always_run: true
        pass_filenames: false
```

### 4. Mirror every hook in CI

**Rule (load-bearing):** every pre-commit hook the user installs gets a matching GitHub Actions job, so `--no-verify` bypass surfaces in PR checks. Source pattern: `minibinder/.github/workflows/test.yml` lines 365-379 (xfail-age) + 337-363 (placeholder-citations).

Emit `.github/workflows/discipline.yml` (or merge into existing `test.yml`):

```yaml
name: discipline
on:
  push: { branches: [main, master] }
  pull_request: { branches: [main, master] }

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  xfail-age:
    name: anti-rot — xfail age budget (90d)
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.10" }
      - run: pip install PyYAML
      - run: python scripts/audit_xfail_age.py

  placeholder-citations:
    name: anti-rot — placeholder citations
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.10" }
      - run: pip install PyYAML
      - run: |
          python scripts/citation_audit.py \
            --no-fetch --inventory-only --fail-on-placeholder \
            --doc-pattern '/nonexistent/*.md'

  ruff:
    name: ruff (lint + format)
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.10" }
      - run: pip install ruff==0.7.4
      - run: ruff check . && ruff format --check .
```

For each opted-in extra tier (failure-modes-log, holdout-no-peek, schema-defaults), append the matching job — pattern in `minibinder/.github/workflows/test.yml` at lines 248-276 (failure-log-coverage), 401-427 (holdout-no-peek), 381-399 (schema-defaults).

### 5. Install instructions to surface to the user

After the writes land, the user runs once:

```bash
pip install pre-commit
pre-commit install        # wires pre-commit AND pre-push thanks to default_install_hook_types
pre-commit run --all-files  # smoke-test the install
```

### 6. Sanity checks before declaring done

- Confirm `.pre-commit-config.yaml` has the `default_install_hook_types: [pre-commit, pre-push]` line — otherwise the pre-push hook is silently dead.
- Confirm `scripts/_rot_exceptions.py` resolves `REPO_ROOT` correctly (parent of `scripts/` should be the repo root).
- Confirm `.rot-exceptions.yaml` starts with `exceptions: []` or an empty list — the loader fails closed on malformed shape.
- Confirm every emitted hook has a matching CI job. Diff-check: each `- id: <foo>` in `.pre-commit-config.yaml` should map to a `<foo>:` job in the workflow.

## Hard rules

- **Don't overwrite an existing `.pre-commit-config.yaml`.** Merge: read what's there, add the missing hooks, preserve order.
- **Don't drop `default_install_hook_types: [pre-commit, pre-push]`** — without it `pre-commit install` skips the pre-push hook and `_pre_push_suite_green.sh` never fires.
- **Don't lower `MAX_AGE_DAYS = 90`** in `audit_xfail_age.py` to make a noisy repo quiet. The 90-day budget is the discipline; a longer budget defeats the gate. If the operator needs to defer, that's what `.rot-exceptions.yaml` (dated-expiry-only) is for.
- **Don't ship `.rot-exceptions.yaml` pre-populated.** Empty list. Every entry must be added deliberately with an owner + future expires date.
- **Don't skip the CI mirror.** A pre-commit hook without a matching CI job is bypassable via `git commit --no-verify`; the CI job is what makes the discipline survive `--no-verify`.
- **The `_pre_push_suite_green.sh` hook will block every push until a `results/_suite_green_stamp.json` exists.** Surface this trade-off explicitly to the operator on first install — it's not a bug, it's the contract, but a fresh repo needs the stamp-producer wired before the first push lands.

## Related

- `~/.claude/commands/anti-fabrication.md` — citation-verification contract that the placeholder-citations hook enforces statically
- `~/.claude/commands/scaffold-agent.md` — sibling skill for scaffolding subagent specs
- `~/.claude/commands/critique.md` — adversarial-review macro that the suite-green gate makes survivable
- Source repo: `/Volumes/pool-mann-<operator>/code_bin/minibinder/` — canonical pattern, all files referenced above are verified to exist there as of 2026-05

# Building blocks

Most of this config is personal. The **anti-rot tier** is the part that transfers cleanly to any repo, regardless of domain — the `scaffold-discipline` skill plans it into a fresh project.

## What it drops in

- **`_rot_exceptions.py` + `.rot-exceptions.yaml`** — a shared loader for dated-expiry-only deferrals (fail-closed: an undated exception is an error, not a silent pass).
- **`audit_xfail_age.py`** — enforces a 90-day budget on `xfail`/`skip` markers so they can't quietly become permanent.
- **placeholder-citations scanner** — flags `[NEEDS CITATION]` / `[PENDING]` / `[FIXME]` / `[TODO CITATION]` before they ship.
- **`_pre_push_suite_green.sh`** — a commit-pinned suite-green stamp gate so `--no-verify` pushes surface in CI.
- **pre-commit hygiene block + ruff config**, mirrored by GitHub Actions jobs so a bypassed local hook still fails the PR check.

## Why it's domain-free

These enforce *process* invariants — no test silently disabled forever, no placeholder citation in a release, no green local run that hides a red suite — none of which depend on what your code does. They're the mechanical expression of the [claims-defended-by-stacks](../philosophy/index.md) principle: no single check is load-bearing.

## Install it

Invoke the `scaffold-discipline` skill in the target repo (it runs in plan mode first), or copy the scripts directly and wire the pre-commit + Actions blocks. See `commands/scaffold-discipline.md` for the full plan and the opt-in extras (failure-modes log, locked-holdout pattern, schema-default audit).

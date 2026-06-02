# Provenance

This config wasn't designed top-down — it was *mined* from how the operator actually worked, then refined adversarially.

## The bootstrap (2026-05-24)

A meta-analysis of ~5,270 user messages, 6 pool `CLAUDE.md` files, and 5 `/analyze` slash-commands produced the "operator-platform" reframe: that `CLAUDE.md` is prosthetic memory, the `/analyze` commands are internalized agents, and the daily note is a fleet lab-notebook. The two analysis passes are preserved in the repo root:

- `meta_claude_usage_2026-05-24.md` — the foundational analysis (the reframe, friction ranking, psychological layer).
- `meta_claude_usage_2026-05-24_v3.md` — a validation pass that *corrects* v1 (e.g. re-ranks cross-session coordination above cluster-opacity) and catalogs hoist-able patterns.

!!! note "Historical snapshots"
    Both files are date-pinned. Their counts and line-numbers reflect 2026-05-24, not the current repo — they're kept as an audit trail of *why* the config evolved, not as current-state docs. Read v1 first, then v3.

## The expansion (2026-05-31 → 06-01)

Deep mining across all active project `CLAUDE.md` files plus conversation scratchpads and daily notes produced the driving-philosophies section, 5 new hooks (`tmp_write_guard`, `subagent_sandbox_preflight`, `pre_sbatch_guard`, `re_derive_state_inject`, `headline_numbers_check`), and 4 new skills (`anti-fabrication`, `grant-work-mode`, `covariate-screen`, `scaffold-discipline`). An adversarial `/critique` pass then surfaced blockers and decoration, corrected in-session.

## The discipline that keeps it honest

Every rule traces to a real incident, gated by [correction-frequency](philosophy/index.md). That's why the file is dense with things that actually bite instead of generic advice — and why the provenance docs are worth keeping: they show the method working on itself.

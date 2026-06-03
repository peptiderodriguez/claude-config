Write a dated checkpoint / handoff doc so a fresh window (after compaction, a session close, or before a risky step) can resume fast and safely. Captures committed state, in-flight work (4-state), the EXACT next-step resume sequence, and the gates to clear. The write-side complement to `/orient` (which reads state back on resume).

TRIGGER when the user says: "checkpoint", "save a handoff", "write a resume doc / continuation", "i'm running low on context", "wrap up / before we stop", "save state before the risky step", "leave a breadcrumb". Also fire proactively at ~15% context remaining (the compaction protocol), or when you're about to stop at a boundary where the next step needs a fresh window to be done safely.

SKIP when: the session is trivial / nothing is in flight; you're mid-task with no natural stop boundary (keep going); `/orient` was just run and nothing has changed since.

## Sequence

1. **Re-derive live state from disk — never write state from memory.** Run, in parallel: `git -C $PWD status -s` + `git log -5 --oneline`, `squeue -u $USER` (if cluster), the open `TaskList`, and the relevant test/suite status. The summary is only trustworthy if it's disk-derived.

2. **Classify what's safe-committed vs in-flight.** For every in-flight item, tag which of the 4 states: **RUNNING** / **QUEUED** / **FAILED** / **STALE-SENTINEL** (sentinel mtime vs latest input). The last two demand a note, not "looks fine."

3. **Write `docs/session_summary_<YYYY-MM-DD>.md`** (or the project's existing convention, e.g. `CONTINUATION_<date>.md` — match what's already there; never overwrite a prior dated summary — it's an audit trail). Sections:
   - **Committed / done** — with commit hashes.
   - **In flight (4-state)** — per item, with job-ids / paths.
   - **Resume sequence** — the EXACT ordered next steps a fresh window runs, as concrete commands + gates (e.g. *"apply finish_guard → test → SLURM pre-submit gate → commit → launch (gate: ≥1 cloning_candidate) → fan out the pilot"*). This is the load-bearing section: it must let the next window "drive the finish straight through," not re-plan.
   - **Gates / do-not-cross** — conditions that must hold before each risky/irreversible step (e.g. pipeline green before wet-lab; dependency job succeeded before the dependent runs).
   - **Don't-trust list** — claims in this summary a fresh agent must re-derive rather than believe (counts, "0 X anywhere", "done"), per the re-derive-from-disk rule.

4. **Commit the doc** (a breadcrumb only helps if it survives the window) — but only the summary + already-safe work; do NOT commit the risky in-flight change the checkpoint exists to defer.

5. **Hand off:** tell the user the doc path + the one-line resume cue for the fresh window (*"open `docs/session_summary_<date>.md` and run the resume sequence"*), so `/orient` or a fresh session picks it up immediately.

## Conventions

- **Pairs with `/orient`:** `/checkpoint` writes the breadcrumb; `/orient` reads it (its daily-note + state scan should surface the latest dated summary).
- Concrete over vague: a resume sequence of named commands + gates, not "continue the work."
- Date every file; append, never overwrite — the dated series is the audit trail of how the work progressed.
- Re-derive from disk before writing any number or status into the summary.

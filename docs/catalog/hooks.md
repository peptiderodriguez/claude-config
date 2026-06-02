# Hooks (13)

Hooks live in `hooks/*.sh` and are wired to tool/session events in `settings.json`. They are the *mechanical* layer — they fire whether or not Claude remembers the rule.

!!! danger "Two hooks hard-deny; one asks"
    `scancel_guard` and `tmp_write_guard` return `permissionDecision: deny`. `pre_sbatch_guard` asks for confirmation on portfolio-scale launches. The rest inject context or run checks.

| Hook | Event | What it does |
|---|---|---|
| `squeue_inject.sh` | UserPromptSubmit | Injects a `squeue` snapshot on cluster hosts (silent on Mac) |
| `surprise_capture.sh` | UserPromptSubmit | Detects "huh / wait what / aha / TIL" — offers to capture as durable memory, once |
| `re_derive_state_inject.sh` | UserPromptSubmit | On status/orientation phrasings, injects a "re-derive from disk, don't quote a stale summary" reminder |
| **`scancel_guard.sh`** | PreToolUse (Bash) | **DENIES** `scancel -u $USER` (wiped-libgen scar). Kill by explicit job-id list |
| `pre_sbatch_guard.sh` | PreToolUse (Bash) | Injects scar-anchored pre-flight; **ASKS** on portfolio-scale launches (≥2 sbatch + no env-source) |
| **`tmp_write_guard.sh`** | PreToolUse (Bash/Write/Edit/…) | **DENIES** writes to `/tmp/*` (highest-scar rule — non-recoverable) |
| `subagent_sandbox_preflight.sh` | PreToolUse (Task) | Warns when a subagent briefing references paths outside this cwd's `additionalDirectories` |
| `headline_numbers_check.sh` | PostToolUse (Edit/Write) | Per-project opt-in; runs the project's headline-numbers regression on matching edits, surfaces drift loudly |
| `pmid_citation_guard.sh` | PostToolUse (Edit/Write/…) | Joins a citation manifest to a PubMed cache; fails loud on mismatch / missing row / missing cache. Composes with the `anti-fabrication` skill |
| `post_critique_dissent.sh` | PostToolUse (Skill=critique) | Reminds Claude to run `dissent-auditor` before finalizing the critique synthesis |
| `postcompact_resume.sh` | PostCompact | Injects a post-compaction state snapshot + nudge toward the `/orient` skill |
| `session_digest.sh` | SessionEnd | Appends a one-line digest to today's daily note |
| `session_end_audit.sh` | SessionEnd | Scans the daily note for stakes-pin / delegation tokens; appends a `frame-auditor` reminder if found |

Browse the scripts at `https://github.com/peptiderodriguez/claude-config/tree/main/hooks`. The skill ↔ hook split: a skill is generation-time policy; a hook is write/run-time mechanical enforcement.

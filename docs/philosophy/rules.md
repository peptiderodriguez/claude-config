# The CLAUDE.md taxonomy

`CLAUDE.md` is the rules file loaded into every session. It's long because it's exhaustive; this page is the guided tour. Read the full file in the repo root for the authoritative text.

| Section | What it governs | Representative rule |
|---|---|---|
| **Driving philosophies** | The meta-frames that shape *what* to build | Flywheel-not-pipeline; fix-the-representation; fail-loud; correct-over-expeditious (4 banned shortcuts) |
| **House style** | Interaction conventions | `AskUserQuestion` for every prompt; plan-mode-first; terse; never write `/tmp`; never claim absence from a narrow grep |
| **Cluster discipline** | HPC / SLURM safety | Never the login node; `scancel` by job-id only (never `-u $USER`); sentinel-after-success; 4-state diagnosis |
| **Subagents** | Delegation rules | Default to parallel for read-heavy work; never blind-trust agent returns; agents can't Write in pool projects; pre-grant sandbox dirs |
| **Statistics + methodology** | Analysis hygiene | Benchmark before flipping a default; wrap correctness-invariant helpers, don't reimplement; emit the assumption manifest unsolicited |
| **Critique loop** | How review happens | `/critique` dispatches adversarial personas; cross-module composition pass after fan-out; severity-tag + word-budget output contract |
| **Relational** | How to work *with* the operator | Counterparty not yes-agent; mirror register; surface stakes-relevant findings unprompted; don't over-identify |
| **Trust signals** | Decoding terse phrasing | *"ok where are we?"* = orientation drift; *"dude i thought i told you…"* = rule violation; *"do you agree?"* = wants independent take |
| **Front-load** | Pre-work clarification | One batched `AskUserQuestion` on goal + scope before any >1-file / >50-line / cluster-state task |
| **Surprise capture** | Memory nudges | A hook detects "huh / wait what / TIL" and offers to save the insight as durable memory |
| **Memory layer** | Where durable facts live | Index + sub-files under `~/.claude/projects/<sanitized-cwd>/memory/` |

!!! tip "The meta-rule"
    At the top of the file: *every rule traces to a specific incident; aspirations belong in project docs or memory, not here.* That's what keeps it from bloating into generic advice. See [Why scar-tissue rules](index.md).

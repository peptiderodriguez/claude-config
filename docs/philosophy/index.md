# Why scar-tissue rules

The global `CLAUDE.md` is not a "best practices" document. **Every rule traces to a specific past incident** — a wiped 7-hour job, a fabricated protein panel that embarrassed the lab, a silent `/tmp` write that lost work, a benchmark number that drifted unnoticed. The file is scar tissue.

## The correction-frequency gate

Rules earn their place by recurrence, not by sounding wise:

| Times the same correction happens | Result |
|---|---|
| 1st | Nothing — could be a one-off |
| 2nd | Candidate for a memory note |
| 3rd | Promoted to a `CLAUDE.md` rule |

This keeps the rules file dense with things that actually bite, instead of aspirational advice that never fires.

## Every philosophy carries a falsifiable trigger

A principle that can't tell you *when it applies* is decoration. So each driving philosophy in `CLAUDE.md` ships with a concrete, mechanical trigger — a condition under which Claude should do or refuse something. Examples:

- **Fail loud, never silent** → *when writing a function that may return empty/None/partial, raise a typed error at the boundary instead.*
- **Fix the representation, not the symptom** → *before patching the N-th bug in the same module, ask whether a substrate change kills the whole bug-class.*
- **Correct over expeditious** → *four banned shortcut shapes (threshold-gaming, count-padding, tidy-over-true, allowlist-loosening) to recognize and refuse on sight.*

If a bullet can't pass the "when X happens, do/refuse Y" test, it gets deleted.

## Why this matters for *you*

If you adapt this repo, don't copy the rules wholesale — copy the **method**. Your scars are different. Start from the correction-frequency gate and the falsifiable-trigger discipline, and let your own incidents fill the file. See [The CLAUDE.md taxonomy](rules.md) for the sections, and [Make it yours](../adapt/index.md) for pruning guidance.

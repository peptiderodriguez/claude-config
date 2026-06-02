Run a multi-agent adversarial critique pass over the named target. Dispatch parallel subagents with distinct personas, then synthesize a single verdict — do NOT dump raw agent reports.

TRIGGER when user asks to: "review", "critique", "review/critique", "review your plan", "review your work", "look for issues / flaws / bugs / problems", "audit", "do a deep review", "find what's wrong with", "what would a reviewer say", "imagine a [skeptical / adversarial / critical] reviewer", "launch [N] [adversarial / review / critic] agents". Especially trigger on the verbatim checklist: "logical flaws, errors/bugs, computational inefficiencies, code duplications, security issues, poor/no testing, bad/stale/unhelpful documentation". Adversarial-persona framing ("reviewer who has previously rejected this work", "skeptical methodologist") strongly indicates this skill.

SKIP for: trivial one-line / typo / syntax-error fixes (single-pass review fits, multi-agent dispatch is overkill); when a critique has already been run this turn (don't churn); when the user explicitly wants a single voice (e.g. "just give me your take" — that's not a critique pass, that's an opinion).

**DO NOT BYPASS.** When the TRIGGER conditions match, invoke this skill via the Skill tool — do NOT dispatch parallel `general-purpose` agents directly with a review prompt. The dissent-auditor meta-check (step 5.5), the `dfg-reviewer` wiring in grant contexts (step 4), and the synthesis-not-raw-dump rule are load-bearing — they only fire when this skill drives the dispatch. Bypass = the custom agents stay dead, the dissent check never runs, and review surfaces as a raw report dump. Past sessions have bypassed; the agents on disk have zero real invocations. Do not be the next session that does this.

AUTO-INCLUDE the "Frame skeptic" persona (in addition to the user's selection or the default 3) when the prompt or recent context contains stakes-anchoring keywords: "grant", "funding", "submit", "submission", "reviewer", "deadline", "PI sign-off", "fundable", "DFG", "NIH", "NSF". Rationale: stakes-named work is where execution-within-frame critique most often misses the higher-order question "is this the right project to be optimizing for at all?" Surface the lens *without* requiring the user to remember it.

## Sequence

1. **Identify the target.** If named in slash-command args (`/critique the migration plan`), use it. Otherwise AskUserQuestion: *"What should I critique?"* Options: "The current plan we just made" / "Recent code changes in this branch" / "A specific file or dir (Other to type path)" / "The whole package end-to-end".

2. **Pick personas** via AskUserQuestion (multiSelect, default first three):
   - **Methodology / logic** — statistical errors, logical flaws, "this won't support the claim" reviewer (execution-within-frame)
   - **Engineering / perf** — bugs (including basics: missing imports, wrong dict keys, sys.exit-without-import-sys), inefficiencies, duplications, security issues (execution-within-frame)
   - **Tests / docs** — missing/poor tests, stale or inaccurate or unhelpful documentation, examples that don't run (execution-within-frame)
   - **Frame skeptic** (higher-order — opt in explicitly) — *questions the project itself*. Should this be done at all? Is the goal worth the cost? Is the hypothesis sound? Is the design answering the right question? Are we solving the *stated* problem or a proxy for it? Use when you suspect the work is well-executed but possibly misaimed. The user's standard agent-dispatch doesn't include this lens — surface it.
   - Free-text "Other" supports custom personas like "reviewer who has previously rejected this group's funding", "clinical translation skeptic", "omics-skeptic methods reviewer". Up to 4 agents total.

3. **Scope.** AskUserQuestion if not obvious: "This conversation's plan + new code only" / "Whole repo" / "Specific subtree (Other to type path)".

4. **Dispatch in parallel.** Multiple `Agent` tool calls in one message. Brief each agent like a smart colleague who just walked in:
   - State what they're reviewing (file paths, line numbers)
   - State the user's goal and what's already been ruled out
   - **Anchor the persona explicitly** — "You are a statistical-methods reviewer who has previously denied this group funding. Read with that POV. Don't soften."
   - Embed the canonical checklist verbatim for their lens (see persona prompts below)
   - Ask for under-400-word structured report: top 3 issues with file:line citations, severity (blocker / serious / minor), and a specific suggested fix per issue.

   **`subagent_type` mapping** — use the custom agent when one exists; fall back to `general-purpose` otherwise:
   - **Methodology / logic** in a grant / funding / submission / DFG-NIH-NSF context → `subagent_type: "dfg-reviewer"` (adversarial grant-reviewer persona, prompt is self-contained, do not duplicate the canonical checklist)
   - **Methodology / logic** in a non-grant context → `subagent_type: "general-purpose"` with the Methodology template below
   - **Engineering / perf** → `subagent_type: "general-purpose"` with the Engineering template below
   - **Tests / docs** → `subagent_type: "general-purpose"` with the Tests/Docs template below
   - **Frame skeptic** → `subagent_type: "general-purpose"` with the Frame-skeptic template (NOT `frame-auditor` — that's a different agent for auditing CLAUDE.md compliance in transcripts, not the work itself)
   - **Custom "Other" persona** → `subagent_type: "general-purpose"` with the Custom template

   If you find yourself about to dispatch all-general-purpose agents in a grant context, stop — wire `dfg-reviewer` for the methodology slot. The whole point of having that agent on disk is for this slot.

5. **Synthesize.** When all agents complete, produce ONE verdict:
   - **Blockers** — anything any agent flagged as blocker, one-line summary + file:line + which agent
   - **Convergent concerns** — issues ≥2 agents raised (highest-confidence findings)
   - **Persona-specific concerns** — one-liners per remaining serious finding, grouped by agent
   - **What the agents agreed was fine** — short list. Matters for calibration; review-only-finds-problems creates over-correction.
   - **My take** — your own one-paragraph synthesis. Where do you agree with the agents? Where do you push back? The user often asks "do you agree with the review?" — be ready with an independent opinion.

5.5. **Dissent meta-check (PRN, auto-fire).** Before showing the synthesis, dispatch `Agent(subagent_type: "dissent-auditor", ...)` passing the N raw agent outputs. If it returns `partial` or `converged`, prepend a `## Dissent check` block to your synthesis with the dissent-auditor's recommendation (sharpen persona X / seed adversary Z / retire persona Y). If `independent`, suppress — silence = pass. This guards against the adversarial-personas-have-converged failure mode without requiring the operator to remember to ask.

6. **AskUserQuestion next step:** "Address all blockers now" / "Address blockers + convergent concerns" / "Show me agent X's full report" / "I'll triage manually — done".

## Persona prompts (canonical checklist embedded)

The user's verbatim review checklist is reused across all personas:

> "review to look for logical flaws, errors/bugs, computational inefficiencies, code duplications, security issues, poor/no testing, bad/stale/unhelpful documentation, etc."

**Methodology / logic** template:
> You are a critical methodology reviewer. Look for: logical flaws in the argument or design; statistical errors or situations where the chosen statistics will not be appropriate (low n, wrong test, multiple-comparison hygiene, assumption violations); claims unsupported by cited evidence; cases where the work would not convince a skeptical reviewer in this domain. Don't pad. File:line cites. Top 3 with severity + concrete fix. Under 400 words.

**Engineering / perf** template:
> You are an engineering reviewer focused on correctness and performance. Look for: bugs including basics (missing imports, wrong dict keys, off-by-one, sys.exit without import sys); computational inefficiencies (O(n²) where O(n) exists, repeated work that could cache); code duplications across files; security issues (command injection, unescaped paths, secrets in logs); fragile patterns that silently produce wrong results on edge cases. File:line cites. Top 3 with severity + concrete fix. Under 400 words.

**Tests / docs** template:
> You are a tests-and-docs reviewer. Look for: missing tests for new behavior; tests that don't actually test the claim; stale, inaccurate, or unhelpful documentation; examples that don't run; comments that lie or are now wrong; missing rationale for non-obvious design choices. File:line cites. Top 3 with severity + concrete fix. Under 400 words.

**Frame skeptic** template (when "Frame skeptic" is selected):
> You are a frame-skeptic reviewer. Your job is NOT to find bugs in the work; it is to question whether the work itself is well-aimed. Ask: Should this project be done at all? Is the stated hypothesis defensible — or is it a proxy that *looks* like the real question but isn't? Are the deliverables aligned with the goal, or with what's easy to measure? Would a thoughtful outsider in this field see the project as misconceived even if executed perfectly? Find the strongest version of "this is well-built but answering the wrong question". Top 3 frame-level objections with concrete reasoning + what would have to be true for the objection to be wrong. Under 400 words.

**Custom-persona** template (when user picks "Other"):
> You are a {custom_persona}. Read the work from that POV. Don't soften your read; the user is asking for it. Top 3 issues with file:line cites, severity, concrete fix. Under 400 words.

## Tone & conventions

- Use AskUserQuestion for every interactive choice — never inline prose options.
- One question at a time unless batching truly independent ones.
- Don't show raw agent reports unless asked.
- Default agent count = 3 (matches default persona set). Scale to 4 for larger reviews; rarely useful above that. Don't lock the cap — adapt to problem size.
- If the work has already been critiqued once this session, ask before re-running.
- If Agent tool isn't available, fall back to a single sequential pass through the three lenses, labeled by section.

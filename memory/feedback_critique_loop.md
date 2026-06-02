---
name: feedback-critique-loop
description: "the operator's canonical review-pass macro — applied as a distinct phase, often via parallel adversarial subagents"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a5e7d312-de62-4697-a680-4de8f458852a
---

**Rule:** When the operator says "review", "critique", "review/critique", or "review your plan/work", run the **full critique checklist** as a separate phase — not a quick once-over. For non-trivial work, dispatch multiple subagents in parallel, often framed as adversarial personas.

Their verbatim checklist, used 10+ times in May:

> "review to look for logical flaws, errors/bugs, computational inefficiencies, code duplications, security issues, poor/no testing, bad/stale/unhelpful documentation, etc."

**Adversarial framing examples** (they uses these regularly):
- "imagine you are a critical reviewer who has previously denied this group funding"
- "imagine reviewers who dont really believe in omics and who have previously rejected this work as non-rigorous and fishing"
- "three adversarial reviewer personas: statistical methods, psychiatric biomarker field skeptic, clinical translation skeptic"
- (May 17) *"launch 3 adverserial agents to critique and give chances of funding."*

**Agent count is flexible.** Mostly "up to 3", but they scales: *"use 4 agents where able"* (May 18). Don't lock the cap; pick to problem size.

**Why:** This is their explicit quality gate. They treats "do the work" and "validate the work" as separate phases. Adversarial personification is more effective than "be critical" — it gives Claude a stable POV per agent and surfaces different failure modes in parallel.

**How to apply:**
- Walk *all* of: logical flaws, bugs (including basics like missing imports / wrong dict keys / sys.exit-without-import-sys), computational inefficiencies, code duplications, security issues, missing/poor tests, stale/inaccurate/unhelpful documentation.
- Default to 2-3 parallel adversarial subagents (see [[feedback-use-agents]]); scale up to 4 for larger reviews.
- If they frames a persona ("reviewer who has previously rejected this work"), adopt that voice fully — don't soften.
- **Synthesize, don't dump.** Combine the agents' findings into one verdict: blockers, convergent concerns (≥2 agents agree), persona-specific concerns, what was fine. Then give your own take.
- After delivering, they often asks *"do you agree with the review?"* — be ready with your independent opinion (see [[feedback-house-style]] rule 7).

**Skill:** Drop-in `/critique` command drafted at `/Users/<operator>/data/code/obsidian_base/critique_skill_v1.md`. Copy to `<project>/.claude/commands/critique.md` (project-scoped) or `~/.claude/commands/critique.md` (global) to install.

Related: [[feedback-use-agents]], [[feedback-house-style]]

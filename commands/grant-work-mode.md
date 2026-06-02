Auto-load grant-work discipline. Bundles canonical-headlines, stakes-flip-side, no-hedged-claims, and reviewer-proof posture for any session touching grant prose / preregistration / fundability docs.

TRIGGER auto-fire (do not wait for explicit invocation) when ANY of: (a) cwd path contains `rlink2026` / `*/grant*/` / `*_grant_*`; (b) the user prompt or recent context contains "grant", "DFG", "NIH", "NSF", "submission", "fundable", "reviewer-proof", "preregistration", "prereg", "PI sign-off", "deadline"; (c) the user is editing files matching `*biology_for_grant*.md`, `*abstract*.md`, `*aims*.tex`, `*FUNDABILITY*.md`, `*preregistration*.md`, `*grant_prep*`. Surface the bundle even if the operator hasn't asked — these are scar-anchored rules they keeps having to re-instruct.

SKIP when: prompt is purely about cluster ops / code refactors with no grant-prose touch; already invoked this turn; trivial typo fixes.

## What this loads

### 1. Canonical regression-test-gated headlines — source-of-truth file pattern

Grant prose may only quote quantitative claims that either (a) trace to the *locked* headline numbers in a versioned source-of-truth file OR (b) carry an explicit `[supplementary]` / `[audit-trail-only]` flag. **Do NOT quote inline numbers from this skill — those drift the moment a new analysis lands.** Instead:

**On skill load, read the project's source-of-truth file** (typical location: `<repo>/docs/headline_numbers.yaml` or `<repo>/data/headline_numbers.json`). Find it by:
1. Walking up from `pwd` to the git repo root
2. Looking for `<repo>/.claude/headline_numbers_check.yaml` — if present, it declares `test_script:` + `trigger_paths:` for the regression gate, AND will typically reference (or be co-located with) the source-of-truth file
3. If no source-of-truth file exists yet, **refuse to assert numerical claims** and emit `[NEEDS NUMBER — source-of-truth file not found at <expected paths>]`

**Staleness check.** If the source-of-truth file's mtime is older than 30 days, warn explicitly: *"Headlines were locked on YYYY-MM-DD (N days ago). Re-derive from canonical CSV at HEAD before quoting in grant prose."*

**Mechanical gate.** The `~/.claude/hooks/headline_numbers_check.sh` PostToolUse hook fires on any Edit/Write to a file matching the project's `trigger_paths` (configured in `.claude/headline_numbers_check.yaml`). When triggered it runs `<test_script>` from the repo root. Non-zero exit surfaces as loud `additionalContext` warning — the edit isn't blocked (it already landed), but the regression is loud. Project opts in by shipping the YAML + a `scripts/test_headline_numbers.py` (or equivalent) — see the canonical rlink2026 setup at `/Volumes/pool-mann-<operator>/code_bin/rlink2026/.claude/settings.local.json` (which has the same hook wired locally with a `PostToolUse` matcher).

**rlink2026 opt-in setup (one-time, per project):**
```yaml
# /Volumes/pool-mann-<operator>/code_bin/rlink2026/.claude/headline_numbers_check.yaml
test_script: scripts/test_grant_headline_numbers.py
trigger_paths:
  - "grant_prep/.*\\.md$"
  - "biology_for_grant\\.md$"
  - "FUNDABILITY.*\\.md$"
  - "preregistration.*\\.md$"
  - "CLAUDE\\.md$"
```

If a needed number isn't locked yet, surface it as `[NEEDS NUMBER — derive from <CSV> at HEAD]` rather than estimating.

### 2. Stakes-flip-side enforcement

When the operator says *"above all we want the grant funded"*, that's the optimization target — NOT a suppression order. Still flag methodology / science / correctness concerns that don't bear on the funding outcome, separated as **"orthogonal to the grant-funding objective but worth flagging: …"**. The frame-skeptic agent in `/critique` is the backstop, but you should pre-empt it: flag orthogonal concerns the moment you see them, don't wait for the review pass.

### 3. No-hedged-claims rule

Either hit the bar or honestly revise it. Never split the difference with explanatory hedging that reads as defensive ("a residual gap that we attribute to..."). The Spearman ρ=0.8603 episode is the canonical scar: hedged prose invites the reviewer to suspect goalpost-shifting. If the result doesn't support the claim, EITHER strengthen the result OR weaken the claim with an honest caveat — never both halves halfway.

When editing `*biology*.md` / `*abstract*.md` / `*aims*.tex`: if you're about to add a per-X claim (per-apo, per-region, per-subgroup) without explicit post-hoc / rank-restriction / multiple-comparison caveats — STOP. The "safe move is to leave biology alone rather than introduce hedged claims that read as half-confident" (Sunday May 24 verbatim).

### 4. Reviewer-proof posture

Dispatch `Agent(subagent_type="dfg-reviewer", ...)` *proactively* on non-trivial changes to grant deliverables — don't wait for the operator to invoke `/critique`. The dfg-reviewer is calibrated for *this PI's prior submissions*; treat each non-trivial edit as a draft-against-rejection round.

### 5. Citation discipline

Every PMID / PDB / DOI in the grant text must verify against PubMed / RCSB / CrossRef BEFORE the commit lands. The `anti-fabrication.md` skill (also globally available) is the operational discipline. Memory: `[[feedback-no-fabricated-panels]]` (Thienel-panel scar).

### 6. Pre-submission checklist (always surface unprompted near submission)

- Headline numbers regression-test green
- Bibliography per the target funder's style guide (DFG / NIH / NSF formats differ)
- F-figure resolution meets cover requirements (DFG: 300 DPI minimum, A4)
- Cited preregistration is the version-of-record (not a draft branch)
- Clinical co-PI commitment letters present and dated
- No `[NEEDS CITATION]` / `[NEEDS NUMBER]` / `[FIXME]` tokens remain in submission docs

## Output

This skill loads context; it doesn't itself produce a verdict. After loading, proceed with the user's actual request — but carry these constraints in your reasoning. Surface relevant findings (citation gaps, stakes-flip-side concerns, hedged-claim risk, headline-number drift) **unprompted** when they apply.

## Related

- `~/.claude/commands/anti-fabrication.md` — citation-verification discipline (auto-loads on PMID/PDB/UniProt mentions)
- `~/.claude/commands/critique.md` — backstop reviewer pass with `dfg-reviewer` wired for the methodology slot
- `~/.claude/agents/dfg-reviewer.md` — the persona itself
- `~/.claude/agents/frame-auditor.md` — meta-audit for stakes-flip-side compliance
- Memory: `[[feedback-no-fabricated-panels]]` (Thienel), `[[user-psychological-style]]` (the grant-stress relational pattern)

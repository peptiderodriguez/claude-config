# How you actually work with Claude — meta-analysis v3

_2026-05-24, third pass. Builds on v2 (`meta_claude_usage_2026-05-24.md`). v3 closes three of v2's named gaps + responds to the May 24 friction interview + catalogs hoist-able patterns from `imaging-seg/.claude/agents/`._

> **Historical snapshot** — counts and line-number references reflect 2026-05-24, not the current repo state. Read v2 first; v3 corrects and extends it. Kept as provenance; do not "freshen" the numbers.

## What v3 is and isn't

v2 was operator-insight-first, skill-designed-second. v3 is **scaffolding-validation + pattern-extraction**. It does not re-derive the reframe; it tests v2's predictions against what actually happened in the 11 days since (May 13–24).

This doc is shorter than v2 by design — most of v2's claims still hold. v3 only flags where v2 was wrong, where new evidence reframes a claim, or where action items have come due.

---

## Closing v2's named gaps (4 of 5)

### Gap 1 — Interview the user (closed)

v2's specific ask was a 4-question read on "what bites you weekly *right now*." Captured 2026-05-24 **via `AskUserQuestion` in the Claude Code conversation that produced this doc** (not in the daily note — the interview is in the conversation transcript, not the vault):

| Question | Answer | Implication |
|---|---|---|
| Top friction this week | **Cross-session coordination** | The daily-note coordination layer is the bottleneck — `/sessions` is the right thing to harden, not cluster-opacity or stale-state (which v2 over-weighted) |
| Cluster-side transcripts worth analyzing? | "Honestly unsure" | Defer — not a v3 priority |
| imaging-seg custom agents worth hoisting? | "Yes — read them, hoist patterns" | Done in this doc (§ "imaging-seg pattern catalog") |
| What's working surprisingly well? | "dunno" | Survivorship-bias gap stays open — v4 task |

**Reframe:** v2 ranked cluster-opacity as friction #1 (by frequency). v3 corrects: by *weekly impact*, cross-session coordination has taken its place. Cluster-opacity has been partially mitigated by `cluster-traffic.md` + `squeue_inject.sh` hook; cross-session coordination has no automated tooling yet beyond the daily-note skill.

### Gap 2 — Cluster-side transcripts (deferred per interview)

Not analyzed. Re-prompt if friction here re-surfaces.

### Gap 3 — imaging-seg custom agents (closed — see § below)

### Gap 4 — Mine for successes (still open)

User said "dunno" to the quiet-wins question. This is itself evidence: when something works, it stops being noticed. Hoist candidates: `/critique` adversarial split, `CLAUDE.md` as prosthetic memory, daily-note as fleet-coordinator, auto-memory survival across compactions. v4 task: spot-check by going *N days without* one of these and asking "what got worse?"

### Gap 5 — Read this analysis is interpretation not measurement

Same caveat applies to v3. Lower confidence than v2 in the success-mining section specifically because the data isn't there.

---

## imaging-seg pattern catalog (the new section)

4 agent specs at `/Volumes/pool-mann-<operator>/code_bin/imaging-seg/.claude/agents/`, 662 lines total: `annotation-trainer` (166), `detection-dev` (135), `lmd-export` (192), `pipeline-runner` (169).

### Patterns worth hoisting platform-wide

**N=1 caveat (load-bearing).** Every pattern below comes from a single project's agent set. "Worth hoisting" here means "looks generic enough to be worth *evaluating* against 2+ other projects before promoting" — not "validated and ready to promote." v2's gap #4 (survivorship bias) explicitly warned against single-project pattern extraction; v3 was about to reproduce that mistake. Before any pattern moves to global CLAUDE.md or `_shared/`, grep `/Volumes/pool-mann-<operator>/code_bin/*/.claude/agents/` and `*/scripts/` for convergent independent invention. **imaging-seg's agent set is N=1 evidence; "hoist" decisions require N≥2.**

| Pattern | Where seen | Why hoist | Hoist as |
|---|---|---|---|
| **Architecture-tree prologue** | All 4 agents start with a code-tree diagram showing the modules the agent works on | Sets shared mental model; future-Claude doesn't have to re-grep on every invocation | Convention to add to `agents/*.md` template — could be a `/scaffold-agent` skill |
| **YAML config + bash launcher** (`scripts/run_pipeline.sh configs/<name>.yaml`) | pipeline-runner | Decouples *what to run* from *how to launch* — reusable for any SLURM-pipeline project | Per-project bash script, plus a `/scaffold-pipeline-yaml` global skill |
| **`system_info.py --json` pre-flight** | pipeline-runner | Auto-recommends partition/GPU/mem based on cluster busyness — generalizable beyond imaging-seg | Promote to `~/code_bin/_shared/scripts/system_info.py` or global skill |
| **"Always run `czi_info.py` first"** pre-flight check | pipeline-runner, annotation-trainer | The *pattern* (inspect data before configuring) is universal even though czi_info is domain-specific | Convention: every pipeline-runner-class agent should have a "Step 0: inspect inputs" line |
| **Failure-pattern table** (Pattern \| Cause \| Fix) | pipeline-runner § "Diagnosing Failures" | Structured stderr→fix mapping; reusable for any project with known crash modes | Convention; encourage in every project-specific runner agent |
| **`resume_dir:` YAML field** for crash-resume | pipeline-runner | Sentinel-friendly, stale-state-aware resume — matches CLAUDE.md anti-stale principle | Pattern to propagate to every long-running pipeline |
| **CLI flag table** (Flag \| Default \| Purpose) | lmd-export | Massively readable vs prose; copy-pasteable | Convention; encourage in every agent that wraps a CLI |
| **"Defaults Are Automatic" principle** | lmd-export line 11 | Explicit counterweight to AskUserQuestion-always — some workflows have too many defaults to ask | ✅ **Shipped at `~/.claude/CLAUDE.md:10`** as of 2026-05-24 (this session) — caveat: applied on N=1 evidence; revisit if pattern doesn't recur in other projects |
| **Channel resolution by name not index** (`--channel-spec "cyto=PM,nuc=488"`) | pipeline-runner | Anti-stale pattern: never assume order from filename — perfectly mirrors CLAUDE.md "stale" worry | Domain-specific to imaging, but the *principle* generalizes |
| **Capacity warning before expensive processing** ("warn early if detection count > 308") | lmd-export | Fail-loud + fail-early — already in CLAUDE.md prose, but the agents make it concrete | Pattern to enforce: every multi-stage agent should have a § "Pre-flight checks" with capacity bounds |

### Patterns to leave xldvp-specific (don't hoist)

- 384-well plate quadrant logic (truly domain-specific)
- Cell-type strategy registry (NMJ/MK/vessel/cell/islet/mesothelium)
- SAM2 + Cellpose + RF combinations
- HDF5 + LZ4 + `hdf5plugin` quirks
- 3-contour vessel system

### Specific recommendations from the catalog

**1. ✅ DONE — Update CLAUDE.md house-style with "Defaults Are Automatic" counterweight.** Shipped this session at `~/.claude/CLAUDE.md:10`. Caveat: applied on N=1 evidence (only imaging-seg's lmd-export proves the exception). If the pattern doesn't recur in 1-2 other projects, reconsider whether to revert.

**2. ✅ DONE — Create `/scaffold-agent` skill.** Shipped this session at `~/.claude/commands/scaffold-agent.md`. Generates stubs with frontmatter format matching dfg-reviewer, TRIGGER/SKIP block in description, architecture-tree prologue, output-format + tone + hard-rules sections.

**3. DEFER — Promote `system_info.py` to a shared location.** `/Volumes/pool-mann-<operator>/code_bin/_shared/` does not exist yet — would require creating the directory and migrating imaging-seg's reference. Hold until at least one *other* project has independently re-invented `system_info.py`-style functionality (per N=1 caveat above).

---

## Validation: what's happened to v2's open items since 2026-05-24

v2 surfaced these gaps in `~/.claude/`. Status today:

| v2 item | Status 2026-05-24 | Notes |
|---|---|---|
| `/critique` skill | ✅ Shipped (`~/.claude/commands/critique.md`) | Working — used in today's note ("review your plan/work. critique. offer constructive corrective feedback…") |
| Subagent sandbox pre-grant pattern | ✅ Documented in `feedback_use_agents.md` | But — see § "New scar" below; documentation alone isn't enough |
| Cross-session coordination | ⚠ Partial (`/sessions` exists, daily-note maintained Sat+Sun, not Fri) | Format drift between skill spec (4-space) and actual notes (tab). Cosmetic. |
| `~/.claude/CLAUDE.md` as durable layer | ✅ In place, 98 lines; stakes-flip-side rule at line 50, delegation-outpaces-scaffolding rule at line 51 (verified via grep — earlier "lines 49–50" was off-by-one) | But — see § "New scar" |
| Auto-memory across compactions | ✅ `MEMORY.md` index + 7 sub-files, mirrored in claude-config repo | Working. |
| GitHub backup | ✅ Pushed to `<operator-username>/claude-config` | Closes today's note's "i guess we could have this backed up on github?" |
| Adversarial agent persona drift | 🔧 New `dissent-auditor` agent drafted today | Untested in production — needs first real run |
| Stakes-flip-side enforcement | 🔧 New `frame-auditor` agent drafted today | Untested |

---

## /sessions verification

Read `~/.claude/commands/sessions.md` + 3 recent daily notes:

- **Sat May 23**: 5 sessions logged (grant, session-b, rlink, binder-design2, session-a) — correct format, tab-indented
- **Sun May 24**: 3 sessions logged (grant, binder-design2, aging-study) + `## Session digests` section auto-populated by `session_digest.sh` hook — both working
- **Fri May 22**: No `CLAUDE SESSIONS:` block — that day was free-text + German practice; skill not invoked. Not a bug.

**Verdict: WORKING.** One cosmetic drift: skill spec specifies 4-space indent for entries; actual files use tab. Functionally equivalent. Either align the spec to the existing format, or auto-normalize on insert.

---

## New scar (since v2): subagent permission inheritance

Today's session attempted 2 subagent dispatches to do the auditor-drafting work. **Both failed silently on sandbox** despite cwd-local `settings.local.json::permissions.additionalDirectories` granting `~/.claude` + `~/code/claude-config`. The grant didn't propagate to the subagent.

This is the **`feedback_use_agents.md` rule firing on itself**: documentation alone said "pre-grant access before delegating", but didn't specify the working format/location for the grant. The cwd-local `.claude/settings.local.json` doesn't appear to be the right place for subagent-inherited permissions in this Claude Code version.

**Action attempted (2026-05-24, end of session):** Added `permissions.additionalDirectories` to `~/.claude/settings.local.json` (user-global, not cwd-local) covering `~/.claude`, `~/code/claude-config`, and `/Volumes/pool-mann-<operator>/code_bin`. Hypothesis: subagents inherit user-global settings at session-launch, not mid-session cwd-local edits. **Verification status: still unconfirmed** — the subsequent /critique dispatched 3 agents that successfully read the granted paths, but it's ambiguous whether the grant or some other factor caused the success. A proper test requires dispatching a subagent to read a *previously-blocked* path with only the new global grant in place.

**Meta-observation:** the agent we drafted to enforce CLAUDE.md:51 (delegation-outpaces-scaffolding) caught its own enforcement-platform breaking. That's a good sign about the rule. It's a bad sign about how brittle the subagent layer is. **But:** beware reading this as "the lens fires on itself = the lens works" — that's the unfalsifiability trap frame-skeptic flagged in v3's own critique. Coincidence of pattern-match is not evidence of generative prediction.

---

## What's next (updated 2026-05-24 after self-critique)

Items 1 and 4 from v3's original "What's next" shipped during this session and have been moved into the validation table above (✅). What actually remains:

1. **Verify the subagent-permission-grant format** that actually works. ~15 min. The user-global `~/.claude/settings.local.json` grant was added this session but not isolated-tested. Concrete test: in a *new* session, dispatch a subagent to read a pool path with no project-local override in place; observe pass/fail.
2. **Test the auditors in production.** `frame-auditor` and `dissent-auditor` are on disk but the PRN auto-fire only activates when `/critique` is invoked through the `Skill` tool (not when the critique workflow is executed manually by the main session). Next real `/critique` invocation should be the smoke test.
3. **Downgrade or revert** any of v3's N=1 hoist decisions if they don't recur in 1-2 other projects within the next month. Specifically: the "Defaults Are Automatic" CLAUDE.md exception. If no other agent ships with a similar override-only-on-request workflow within 30 days, that's evidence it shouldn't have been hoisted from one example.

**Held — frame-skeptic verdict:**

The frame-skeptic agent's verdict was `stop-meta-pause-and-do-science`. v4 (a deeper meta-pass) is held pending evidence that the platform is bottlenecking the science, not the other way around. Next session goes to a science thread (grant outcome, paper progress, pipeline shipping), not more platform work.

---

## What v3 still doesn't have

Honest gaps, same v2-style:

1. **No isolated test of the new auditors.** `frame-auditor` is still untested. `dissent-auditor` was invoked over v3's own critique (inline, not via `Agent(subagent_type: "dissent-auditor")`) so the agent-spec-resolution path is still untested.
2. **Cluster-side transcripts still unread.** Per interview, deferred — but the gap stays open.
3. **Successes still un-mined.** The quiet-wins interview returned "dunno"; the right way to surface them is a *removal experiment*, not an interview.
4. ~~**No v2-style adversarial review of v3 itself.**~~ ✅ Done — see § "Self-critique applied" below.

---

## Self-critique applied (2026-05-24, end of session)

v3 was put through a 3-agent `/critique` (methodology / tests-docs / frame-skeptic). Key findings landed and were addressed in this revision:

- **Staleness** — v3 originally listed `/scaffold-agent` and "Defaults Are Automatic" as deferred; both had already shipped earlier in the same session. v3 was written without re-greping `~/.claude/`. Fixed: those items moved to ✅ in the validation table; "What's next" rewritten against actual current state.
- **N=1 hoist** — methodology + frame-skeptic both flagged the imaging-seg pattern catalog as single-project evidence dressed up as platform-wide recommendation. Fixed: N=1 caveat added at top of the hoist table; "hoist" decisions now explicitly require N≥2.
- **Interview source uncited** — methodology agent inferred the interview was fabricated because it isn't in the daily note. Fixed: source explicitly cited (`AskUserQuestion` in the conversation transcript). A future reader without conversation access still can't verify the answers — that's a real limit of any meta-doc that quotes a live conversation.
- **Off-by-one citation** — v3 cited the meta-rules at CLAUDE.md:49–50; verified actual locations are :50 (stakes-flip-side) and :51 (delegation-outpaces-scaffolding). Fixed.
- **Unfalsifiability lens** — frame-skeptic flagged that v3 absorbs both confirmations and disconfirmations as evidence for the R&D-platform reframe. Not fully fixed; documented in § "New scar" with the warning that "lens fires on itself" is *not* evidence of generative prediction. A real test would be: *what prediction does the R&D-platform lens make that, if it failed, would cause the lens to be dropped (not just refined)?* — that's an open question for v4 or whenever v4 happens.
- **`feedback_use_agents.md` memory file** — tests/docs agent flagged that the file claims "Working format (verified through scar)" when only the failure mode was observed. Fixed separately: heading downgraded; verification recipe added.
- **frame-skeptic verdict** — `stop-meta-pause-and-do-science`. Accepted; v4 is held pending evidence that platform-work is unblocking science-work, not displacing it.

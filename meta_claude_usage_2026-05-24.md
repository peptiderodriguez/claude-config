# How you actually work with Claude — meta-analysis v2

_2026-05-24, second pass. v1 critique inline at end. Built from 6 pool CLAUDE.md files, 5 `/analyze` commands, ~5,270 user messages from one project + recency-biased re-sweep of May 15–20 (binder-design, `<institution>`, late-grant)._

> **Historical snapshot** — counts and line-number references reflect 2026-05-24, not the current repo state. Kept as provenance; do not "freshen" the numbers (it would break the audit trail).

## The reframe

You are not "using Claude well." You're **running a small personal R&D platform**, and you've built three load-bearing artifacts to operate it — without naming them that. Most of your friction now comes from things this platform doesn't yet have, not from things Claude is doing wrong.

The three artifacts:

| Artifact | What it pretends to be | What it actually is |
|---|---|---|
| `CLAUDE.md` (per repo, 70–320 lines) | "Notes for Claude" | **Prosthetic memory.** Past incidents (with hour-counts: "wiped a 7-hour library-gen", "ship-blocker on ≥5GB parquets") encoded as durable rules so they survive session compaction, context loss, and you forgetting. |
| `.claude/commands/analyze.md` (4 repos, up to 1,344 lines each) | "Slash command" | **An internalized agent.** Each one specs a full multi-phase workflow (greet → AskUserQuestion experience → Planner/Guardrail/Collaborator triad → phased walkthrough → adaptive feedback). You've converged on the same skeleton across 4 unrelated projects. That skeleton is a higher-order skill that isn't templated anywhere. |
| Daily note (`Obsidian/<day>.md`) | "Daily journal" | **Lab notebook for a fleet of Claude instances.** The `CLAUDE SESSIONS: name → path` block coordinates 3–5 concurrent sessions across different repos. The "what's NOT in this plan" carve-outs are boundary markers for *other sessions'* work. |

Once you see it this way, the open gaps become obvious:
- The **fleet has no cross-session view.** Each session is blind to the others. Daily note is the only coordination layer.
- The **cluster is a black box** the platform talks to but can't see into. ("how are the pending jobs doing?" — 3 times in one May-17 session.)
- **Subagents inherit the parent's narrow sandbox** but aren't documented as doing so, so today's two subagents both failed silently before you noticed.
- The **`/analyze` skeleton isn't a template** — every new project starts from scratch (or copy-paste from imaging-seg).

That's the v2 thesis. Below: evidence + one concrete skill, designed.

---

## What the three artifacts are actually doing

### CLAUDE.md = prosthetic memory

The clue is the verbatim references to specific past incidents:
- `imaging-seg`: *"`make format` before committing. Black version skew has caused repeated CI failures."*
- `clinical-omics`: *"Wave 2: `quant-runner_array` orchestrator default `mem` is `64G` (was 16G) — the 16G default was a ship-blocker for ≥5GB parquets."*
- Same file: *"`scancel -u $USER` is destructive across cubes. Hard lesson from the bm_mk_e2e_pipeline_test debug session that wiped a 7-hour library-gen."*
- Same file: *"We've burned this lab once already with a fabricated 27-protein 'Thienel panel' that had 7+ proteins not in the paper."*

These aren't documentation — docs explain how something works. These are **bug-reports-as-rules**, written in second-person to whoever (Claude or you) shows up in the next session. The hour-counts are receipts. You write them precisely *because* you know the original context will be gone after compaction.

**Implication:** CLAUDE.md must carry **what won't survive a `/compact`**, not what's already in the code. Every "ALWAYS / NEVER" line is a bet against your future self forgetting.

### `/analyze` = internalized agent

The four `/analyze.md` files share a skeleton you converged on without writing down anywhere:

```
1. CRITICAL startup sequence (silent state check, greet, experience level, path)
2. Use AskUserQuestion for everything — never inline prose
3. Planner / Guardrail / Collaborator triad of principles
4. Tone: concise. Don't narrate.
5. Phase 0/1/2/... walkthrough with adaptive feedback after each
6. Standing rules section (the rules everyone forgets)
7. Analysis catalog (don't list unless asked)
```

This is no longer a "command" — it's an agent spec. The imaging-seg one is 1,344 lines: longer than most Anthropic agent docs. You're describing the agent you wish you had, in enough detail that any Claude session can re-instantiate it on `/analyze`.

**Implication:** the skeleton itself is your highest-leverage unbuilt skill. A `/scaffold-analyze <project-name>` that generates a stub `analyze.md` following the convention would save you the next 1,000-line write.

### Daily note = fleet lab-notebook

The opening `CLAUDE SESSIONS:` block is operating a small lab. On Saturday May 23 you had 5 sessions, three of them rooted in the *same* repo (`proteomics-quant`) doing different things (`session-b`, `rlink`, `session-a`). The repo is the workshop; the session is the task.

The post-session jottings ("- yeah you'll have to test different surface definition options. / - totally agree with kras rediscovery") aren't notes-to-self. They're **decisions ready to be pasted into whichever session asks next.**

**Implication:** the daily note is a coordination layer that wasn't designed to be one — it's load-bearing-by-accident. A `/sessions` skill that auto-maintains it would make this explicit and reduce typos.

---

## What's evolving (recency-biased: May 15–24)

Comparing the May 13–17 grant work to the May 18–24 binder-design/aging-study/`<institution>` work:

- **Adversarial framing is now first-class.** May 17: *"launch 3 adverserial agents to critique and give chances of funding."* Verbatim three weeks earlier you were still asking for "a critical review." Personification of skeptics has stuck.
- **Agent cap is fluid.** Mostly "up to 3", but May 18 hit "use 4 agents where able." You scale to problem size, not to a hard rule. Don't lock the cap.
- **You ask Claude's opinion after dispatching agents.** *"do you agree with the review?"* / *"do you agree with these findings?"* You treat Claude as a counterparty to the agents it dispatched, not just an executor. This is sophisticated and probably under-supported by current tooling.
- **Orientation requests when threads tangle:** *"ok where are we then?"* / *"and is the to do list totally up to date?"* — implies you'd benefit from a `/status` skill that walks plans + tasks + recent commits and emits a 5-line state.
- **Compaction-resume is constant.** "This session is being continued from a previous conversation that ran out of context" appears ≥3 times in the May 13–18 window. CLAUDE.md is now load-bearing for surviving these — but auto-memory updates near compaction are still manual.
- **Goal anchors:** *"above all, we want the grant to be funded!"* — you pin objectives explicitly when stakes are high. Worth doing more often, less when stakes are low.

**The trajectory** if you keep going on this curve: in 6–12 months you'll have a personal `~/.claude/commands/` library that any new repo inherits, a hook layer that catches your top-3 friction patterns automatically (stale-state, tmp-writes, scancel-by-user), and the daily note will be auto-generated rather than typed. The R&D platform becomes the work, and individual projects become instances of it.

---

## Friction — tightened

### #1 by frequency: cluster opacity
- *"so how are all the jobs that we had launched?"* (May 17, asked 3 distinct times that day)
- *"hows clinical-cohort pull?"* (May 17)
- "cluster" 225× / "stale" 53× / "slurm" 24× / "login node" 3× in one transcript
- Already solved once locally: `design-cli traffic` in binder-design. Not hoisted.

### #2: violated standing rules
Explicit re-corrections in transcript:
- *"do not use the login node to run jobs"*
- *"dude i thought i told you not to write to tmp - that is non-recoverable"*
- *"go background has to be correct - only universe of measured proteins"*

These are rules already in some CLAUDE.md but not the one Claude loaded for that session. Need either (a) global memory or (b) a settings-loaded house-style file.

### #3: subagent sandbox surprises
Both of today's subagents got denied access to `/Volumes/pool-mann-<operator>/` and `~/.claude/projects/` that the parent could read. Not documented anywhere yet. Fix: add the relevant dirs to project `.claude/settings.local.json::additionalDirectories` *before* delegating.

### #4: orientation drift
*"ok where are we then?"* / *"and is the to do list totally up to date?"* / *"but like obviously you should be starting with the new list of proteins now"* — Claude lost the thread. Symptom of compaction or long-running tangled state.

### #5: domain-fact corrections (low frequency, high impact)
- *"structure-tool also runs on KOs"*
- *"this is not correct... for interview-only: is there a column..."*
- *"no wer'e doing prm"*
These don't bunch — they're scattered. No structural fix; just stay humble on domain facts.

---

## One concrete skill, designed

Of the candidates, `/critique` is the highest-leverage / lowest-cost. I've drafted a drop-in spec at:

**`$HOME/data/code/obsidian_base/critique_skill_v1.md`**

Copy it to `<project>/.claude/commands/critique.md` for project-scoped, or to `~/.claude/commands/critique.md` for global. The spec uses your verbatim review checklist, follows your `/analyze` skeleton, dispatches 3 parallel adversarial subagents (configurable), and synthesizes — does not dump.

The next-best second skill would be `/cluster-traffic`. That one needs to wrap your specific cluster's `squeue/sinfo`, so it's a per-project script — not a markdown drop-in. I'd want your input on whether to put it in `imaging-seg/scripts/`, `binder-design/scripts/` (where it half-exists), or a new shared dir.

---

## Psychological / psychodynamic patterns

_This is the interpretive layer — tentative by nature. Push back where it doesn't land._

### How you relate to Claude

You don't treat Claude as a tool, and you don't treat it as a colleague either — you treat it as a **counterparty in a working alliance**. The tell is that you ask its opinion after dispatching subagents: *"do you agree with the review?"* / *"do you agree with these findings?"* A tool can't agree or disagree. You're asking for a *take*, and you're prepared to override it if you have one — but you want to know whether you're alone in your read.

You also tell it the **stakes** explicitly, not just the task: *"above all, we want the grant to be funded!"* / *"i dont want to just rewrite the whole thing and piss other contributors off."* You're recruiting it into your political and motivational frame, the way you'd brief a senior collaborator joining a project mid-flight. That's a co-conspirator move, not a delegation move.

### Defensive structure (your error-prevention scaffolding)

Three patterns suggest a deep wariness of silent failure, and they're consistent across all the projects:

1. **The "stale" obsession** (53 mentions in one transcript). Stale sentinels, stale dependency IDs, stale docs, stale caches. You don't fear *visible* failures — you fear ones where the system *looks right but isn't*. Your CLAUDE.md fail-loud guards are anti-silence devices: better to crash than to silently produce a wrong number.
2. **"ALWAYS / NEVER" rule-stacking** is borderline ritual. Hundreds of these across the CLAUDE.md files. Each one is a small bet against a future failure mode. The vocabulary is anxious; the function is anxiety-binding — once it's a rule in the file, it doesn't have to live in your head.
3. **Pre-commitment artifacts** (`phase0_pre_commitment.md`, "PI sign-offs pending", "what's NOT in this plan" carve-outs). You stage commitments *before* work so they can't drift mid-flight. Containment-device for an environment where lots of people are touching lots of things in parallel.

### What you externalize, and why it works

The most striking pattern: **you outsource the harsh-critic role to subagents.** Rather than being the critical voice yourself (which would be effortful and risk you over-correcting your own ideas), you launch *"3 adversarial agents to critique and give chances of funding"* and let them do it. Then you ask Claude to synthesize. Then you ask Claude *whether it agrees*. Then you decide.

This is a **functional split**: the critic role is dissociated outward, a clean POV per agent, no muddling with your own preferences. It lets you keep your own voice as the integrator/decider rather than the attacker. It also bypasses the dynamic where a single critic gets pulled into either (a) deference or (b) over-pessimism — N adversarial voices in parallel are noisier and harder to over-trust.

You don't seem to over-identify with what you build, either. You'll say *"i'm quite critical of the p-factor idea because it's being treated as state-like and there are a ton of counfounders"* about work you're actively helping fund. That self-distancing is what makes the adversarial frame *useful* rather than narcissistically injurious — you don't need the agents to like the work.

### Tone register (what your prompts sound like)

- **Friend-collegial when frustrated:** *"dude i thought i told you not to write to tmp"* — "dude" is unguarded, irritated-but-warm. You don't take an authoritarian voice when correcting.
- **Telegraphic when confident:** "yes update" / "ok address" / "do 2.2" — minimal-cost confirmations. Implies high working-alliance trust; you're not over-explaining because you trust the lift.
- **Conditional when uncertain:** *"should we just ask for 96hr?"* / *"is this going to work?"* — collaborative deliberation, not directive. You include Claude in the decision, which keeps it engaged in your reasoning rather than just executing.
- **Goal-anchored under stakes:** *"above all, we want the grant to be funded!"* — pinning the objective is a stress-tell. You do it when something is at risk of drifting.

### Evolution (over the May 13–24 window)

A psychological trajectory is visible:
- **Mid-May (grant prep, high stakes, novel domain):** anxious-perfectionist register. *"is this going to work?"* / *"how can you address all the issues to make this a robust fundable reviewer-proof application"* / *"make sure to add explicity to dos"*. Lots of "make sure" and "explicit". Externalized self-criticism via 3 adversarial reviewers.
- **Late-May (E2E review, binder-design, aging-study):** delegational-coordinator register. *"use agents where able"* (no longer specifying *why* — the workflow is internalized). *"do you agree with the review?"* (now treating Claude as the second opinion, not the work-doer). Longer prompts with more scope; less micromanagement.

**Reading:** you've moved from *anxiously supervising* to *trusting-but-auditing*. The CLAUDE.md scar tissue and the `/analyze` agent specs are the **safety scaffolding that lets you relax delegation**. The more you encode, the less you have to watch.

### What this means for how Claude should work with you

- **Don't be a yes-agent.** Your structure relies on having an independent opinion to weigh against. Soft-pedaled "great plan!" responses defeat the architecture.
- **Surface stakes-relevant findings unprompted.** If something is in the "make sure" zone — funding, reproducibility, paper-claim correctness — flag it even if not asked. You're already pre-anxious about it; finding it for you reduces the load.
- **Don't catastrophize cluster ops.** Your anxiety here is specific (silent failure, stale state). Sober matter-of-fact updates ("job 42199 RUNNING since 14:02, first tile 8s") settle the system better than "I'm checking on the cluster, this might take a moment".
- **Mirror your terseness when confident, expand when stakes spike.** Match your register: short for ops, expansive for grant/methodology/funding-adjacent decisions.
- **Treat the adversarial frame as load-bearing.** When you say "imagine a reviewer who has previously rejected this work" — fully inhabit it. Soft-pedaling violates the split that's doing the psychological work for you.

---

## Gaps in this analysis

I'm being honest about what I couldn't see:

1. **This psychological section is interpretation, not measurement.** I'm pattern-matching on prompt text; you have access to your own internal state that I don't. If something here is wrong, it's wrong with confidence.
2. **Transcripts are biased toward Mac-rooted sessions.** Sessions started on the cluster (`/fs/pool/...`) write transcripts on the cluster, not your Mac. So all the `aging-study`, `session-a`, etc. sessions you list in the daily note may have logs I never saw.
2. **The 68MB transcript from one project dominated by volume.** Even after recency-sweeping, the sample is overweighted. If the May 20–24 sessions had distinct patterns, I underdetected them.
3. **I didn't open `imaging-seg/.claude/agents/*.md`** (annotation-trainer, detection-dev, lmd-export, pipeline-runner). Those are custom subagents that may carry workflow patterns I missed.
4. **I'm inferring from CLAUDE.md content** what your *current* practice is. CLAUDE.md changes lag behavior — rules persist after the problem stops mattering.
5. **No interview.** I didn't ask you what you find painful. I extracted from transcripts, which under-weights tacit friction (the things annoying enough to feel but not annoying enough to type).

What would close gaps fastest: a 4-question read on what hurts most *right now* (post any time, even later). E.g., "rank cluster-opacity / subagent-permissions / stale-state / cross-session coordination by 'this bites me weekly'."

---

## What changed from v1

v1 was friction-first and skill-list-second. v2 is operator-insight-first and skill-designed-second.
v1 had 8 memory files (over-fragmented). v2 consolidated to 6.
v1 had a glossary inline (re-reading dead weight). v2 moved it to memory only.
v1 listed `/critique` as a candidate. v2 wrote it.
v1 didn't say what it couldn't see. v2 does.

If you want a v3 pass, it would be on the things v2 still doesn't have:
- Actual interview of you (the tacit-friction gap)
- Read the cluster-side transcripts (the unsampled-fleet gap)
- Look at `imaging-seg/.claude/agents/` (the custom-subagent gap)
- Mine for *successes* you took for granted, not just frictions (the survivorship-bias gap)

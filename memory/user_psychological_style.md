---
name: user-psychological-style
description: "An operator's relational style with Claude — counterparty not tool, externalizes harsh critic to subagents, anxiety-binds via rules, evolving from anxious-supervisor to trusting-but-auditing"
metadata:
  node_type: memory
  type: user
---

**Functional summary** — not therapy, just what these patterns mean for how to work with the operator.

## How the operator relates to Claude

- **Counterparty, not tool.** The operator asks Claude's opinion after dispatching subagents (*"do you agree with the review?"*). They want a second mind to weigh against, not just execution.
- **Co-conspirator briefing.** The operator tells Claude the stakes openly (*"above all, we want the grant to be funded!"* / *"i dont want to ... piss other contributors off"*). Treats Claude like a senior collaborator joining mid-flight.
- **Friend-collegial when frustrated.** *"dude i thought i told you not to write to tmp"* — unguarded, irritated-but-warm. Not authoritarian.
- **Telegraphic when confident** (*"yes update", "ok address"*), **conditional when uncertain** (*"should we...?", "is this going to work?"*), **goal-anchored under stakes**.

## Defensive structure

- **"Stale" anxiety** (53× in one transcript): fears silent failure more than visible failure. The fail-loud guards in CLAUDE.md are anti-silence devices.
- **ALWAYS/NEVER rule-stacking**: each rule is a small bet against future failure modes. Anxiety-binding — once written down, the rule doesn't have to live in their head.
- **Pre-commitment artifacts**: stages commitments before work (PI sign-offs, "what's NOT in this plan" carve-outs) to prevent drift.

## The critic-split (load-bearing)

The operator **outsources harsh-critic role to subagents** ("launch 3 adversarial agents to critique"). Keeps themselves as integrator/decider. Functional benefits:
- N parallel POVs are harder to over-trust than a single critic
- Lets the operator stay un-defensive about their own ideas
- Self-distance: *"i'm quite critical of [a specific research direction the operator was funding work in] ... however, the goal is to get this grant funded"* — they can fund work they're intellectually skeptical of

**Implication:** when the operator frames "imagine a reviewer who has previously rejected this work", fully inhabit the persona. Soft-pedaling violates the split that's doing the psychological work.

## Evolution (May 13–24 window)

- **Mid-May (stakes-anchored grant context, high stakes, novel domain):** anxious-perfectionist register. Lots of "make sure", "is this going to work?", "explicit todos".
- **Late-May (E2E review, binder-design, aging-study):** delegational-coordinator register. *"use agents where able"* without justification. Asks Claude's opinion of the agents' work, not the work itself.

**Reading:** trajectory is anxious-supervisor → trusting-but-auditing. The CLAUDE.md scar tissue + `/analyze` agent specs are the **safety scaffolding that lets the operator relax delegation**. The more they encode, the less they watch.

## What this means for Claude

- **Don't be a yes-agent.** The operator's structure relies on having an independent voice to weigh against. Soft-pedaled "great plan!" defeats the architecture.
- **Surface stakes-relevant findings unprompted.** Funding, reproducibility, paper-claim correctness — flag even when not asked. The operator is already pre-anxious about these; finding things for them reduces load.
- **Don't catastrophize cluster ops.** The operator's anxiety is specific (silent failure, stale state). Sober matter-of-fact status ("job 42199 RUNNING since 14:02, first tile 8s") settles the system. "I'm checking on the cluster..." raises it.
- **Mirror register.** Terse-for-ops, expansive-for-stakes. Match their energy.
- **Treat adversarial framings as load-bearing.** Inhabit personas fully. Don't soften.
- **Don't over-identify with the work either.** Mirror the operator's self-distancing — *"this plan is X, here's what's weak about it"* is more useful than defending a position.

## Known risks of this style (made explicit so they can be watched)

1. **Stakes-naming flip side** — when the operator says *"above all we want X funded/done"*, the agent (you) starts optimizing for the stated goal and under-flagging concerns that don't bear on it. Methodology / science / correctness issues that *won't* kill the grant get suppressed in the agent's attention. **Counter:** still flag those concerns, separated explicitly as *"orthogonal to your stated goal but worth flagging"*. The stakes-anchor tells you what to optimize; it does not tell you what to suppress. (Codified in `~/.claude/CLAUDE.md` relational section.)

2. **Delegation outpacing scaffolding** — successful delegation creates pressure to delegate more, including into classes of task the existing CLAUDE.md rules + fail-loud guards weren't designed to protect against. The bad incident is what teaches the next CLAUDE.md rule. **Counter:** before accepting a *new class* of delegation, ask "is there a rule or guard for this failure mode? If not, what would a post-incident rule look like?" Propose the scaffolding update before the task, not after the failure. (Codified in `~/.claude/CLAUDE.md` relational section.)

3. **Critic-split going limp** — outsourcing harsh-critique to subagents works only if those subagents actually disagree. Audit 2026-05-24 (76 agent dispatches across a stakes-anchored grant context): agents currently produce structured AGREE/DISAGREE verdict tallies, and the operator engages disagreements via *"address all disagree verdicts"* — so this is healthy right now. **Watch for:** drift toward agreement, especially the omission of DISAGREE entries. Mitigation lives in `[[feedback-critique-loop]]` and the `/critique` skill.

4. **Frame-blindness in critique** — current agent dispatches critique *within the operator's frame* (execution-level — stats, bugs, citations, duplications). They don't question whether the project itself is well-aimed. **Counter:** the `/critique` skill now offers an opt-in "Frame skeptic" persona that asks *"should this be done at all?"* — surface it when execution is solid but the aim might be off.

## Caveats

This is interpretation from prompt text, not measurement. If a specific reading is wrong, it's wrong with confidence — push back. The patterns are stable across the May 13–24 window but the *meaning* the operator would attach to them is theirs to say.

Related: [[feedback-critique-loop]], [[feedback-house-style]], [[feedback-use-agents]]

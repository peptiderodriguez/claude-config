---
name: process-onboard-methodology
description: Methodology for bootstrapping a personal Claude Code R&D platform — discovery → reframe → install → audit → meta-critique. Distilled from the 2026-05-24 onboarding spiral. Companion to /onboard skill.
metadata: 
  node_type: memory
  type: project
  originSessionId: a5e7d312-de62-4697-a680-4de8f458852a
---

This is the *rationale and lessons-learned* document for the `/onboard` skill at `~/.claude/commands/onboard.md`. The skill is the executable; this is why each phase exists and what to watch for.

## What the methodology is for

Bootstrapping a coherent personal platform when a user has been working with Claude across multiple projects long enough to have accumulated:
- Multiple per-project CLAUDE.md files (varying quality)
- Ad-hoc slash commands repeated across projects
- Recurring frictions that haven't been encoded as rules
- A daily-notes / journaling habit that touches Claude work
- Maybe parallel sessions

The deliverable is: global CLAUDE.md, global skills with TRIGGER clauses, hooks for mechanical enforcement, durable memory, version-controlled backup repo.

## Phase rationale (why each step exists)

**Phase 1 (Discovery)** — opinions before evidence produces flattery. Sample real artifacts. Recency-bias is the single most important calibration: largest transcript usually wins by volume, but most-recent behavior wins on relevance. Sort by mtime.

**Phase 2 (Operator reframe)** — the user knows what they typed; they don't always know what they've *built*. Naming the unconscious convergence patterns (e.g., "you have 4 `/analyze` commands sharing a skeleton — that skeleton is a higher-order skill") creates leverage that wasn't visible before. This is the most insight-dense phase.

**Phase 3 (Friction inventory)** — counts and verbatim quotes only. Vague observations are useless. The pattern: any phrase typed 5+ times is a skill candidate; any verbatim correction is a rule candidate; any "ALWAYS/NEVER" in CLAUDE.md is a past scar worth hoisting to global.

**Phase 4 (Tiered candidates)** — never list without designing one. Tier 1 (strong-evidence/low-cost) gets a concrete spec; Tier 3 (speculative) stays a name.

**Phase 5 (Self-critique)** — apply the user's own quality gate to your work. v1 is always too narrative, too friction-first, too fragmented. v2 should be willing to delete v1's structure.

**Phase 6 (Install)** — the gravitational pull is toward "we should..." documents. Resist. Move every recommendation to "I did this; here's where it lives; here's how to verify". Designs without artifacts decay within days.

**Phase 6.5 (Project-CLAUDE.md global-pointer block)** — once global infrastructure exists (CLAUDE.md, skills, agents, hooks), each project's own CLAUDE.md should carry a short "Global Claude Code setup" pointer block near the top. Three sections:
1. *What's auto-loaded globally* — brief catalog of skills/agents/hooks/memory so Claude in that project session knows they exist without re-deriving
2. *Source of truth* — link to the claude-config repo
3. *Project-relevant rules from the meta-analysis* — the subset of cross-cutting rules that bite hardest *in this specific project* (don't repeat global; surface the project-specific intersection)

Do NOT repeat global rules verbatim — that defeats the layering. Do tell the project where to look + which slices matter most here. Add only to projects where you actively work; skip dormant ones. The block should be ~25-35 lines.

**Phase 6.6 (Tips → tools translation)** — after the install lands, the user often asks for "high-leverage tips for how to interact better." Those tips become tools via one of three mechanisms; pick by tip shape:

| Tip shape | Mechanism | Why |
|---|---|---|
| *"Do X when context warrants"* (context judgment needed; can over-/under-apply) | CLAUDE.md instruction | Flexible, model-driven, costs ~tokens/session. SKIP clauses essential to prevent over-fire. |
| *"When user does Y, react with Z"* (deterministic pattern) | UserPromptSubmit / Pre-or-PostToolUse hook | Mechanical, can't be forgotten, costs a process spawn per event. Pipe-test patterns against realistic typed inputs (apostrophes optional, typos, slang) before committing. |
| *"Workflow A→B→C should be invocable"* | Skill at `~/.claude/commands/` | Discoverable via TRIGGER, named as `/foo`, can be batched + composed. |

The right answer is often hybrid (some tips become CLAUDE.md instructions, some become hooks). After installing automation, **pipe-test every hook with BOTH positive and negative cases**. The "didn't" vs "didnt" apostrophe miss is a representative example — real prompts are informal, your regex must accommodate. False-positive negatives ("interesting question, let me think") are as important as false-negative positives.

Document each tip's mechanism in CLAUDE.md (`## Surprise capture (mechanical reminder)` style) so future sessions know *how* the behavior is enforced, not just *that* it should happen — otherwise the next maintainer (often future-you) won't know whether to edit the prompt, the hook, or both.

**Phase 7 (Audit)** — the critic-split (subagents do harsh critique) only works if agents are still disagreeing. Verify with transcript grep. Also: agents almost always critique *within* the user's frame. Adding a "frame skeptic" persona that questions the frame itself is usually a real gap.

**Phase 8 (Meta-meta)** — one pass only. Identifies what you missed (almost always: one-sided analysis, untested artifacts, compaction-resume not addressed, cross-session coordination still manual, memory hygiene unaddressed). Pick the highest-leverage gap, design it concretely. Then stop. Meta-analysis without resolution becomes avoidance.

## Meta-lessons (in priority order)

1. **Recency bias must be explicit.** Without it the analysis describes the user from 6 months ago.
2. **CLAUDE.md is scar tissue.** Every "Wave 2 hardening" line is a past incident converted to a rule. Reading CLAUDE.md chronologically is reading the user's learning curve with the system.
3. **Front-load TRIGGER clauses** in skill descriptions. The skill listing truncates at ~100 chars. If the trigger is buried, the skill is undiscoverable.
4. **Subagent sandbox is silent.** Failures show up as "I need permission", not exceptions. Pre-grant access in the project's `settings.local.json::additionalDirectories` before delegating cross-system research.
5. **The user's "address what you agree with" filter is a meta-protocol.** Apply it to your own recommendations. Don't be a yes-agent on your own work.
6. **Install as you go.** Every "we should..." has to become "I did...". The pull toward documentation-without-action is strong; resist it.
7. **The user's stated goal can silence orthogonal concerns.** When they say "above all, X" — optimize for X but still flag orthogonal methodology/correctness issues, separated as *"orthogonal to your goal but worth flagging"*.
8. **Delegation outpacing scaffolding is the next-failure-mode pattern.** When the user succeeds at delegating, they delegate more, including into classes the existing CLAUDE.md doesn't protect. The bad incident is what teaches the next rule. Counter by asking "is there a rule for this failure mode?" before accepting a new class of delegation.
9. **Compaction-resume is the most-frequent unaddressed friction.** ≥3 events per week is normal for active users. PostCompact hook + `/orient` skill is the standard answer.
10. **Cross-session coordination is hardest.** Multi-session users coordinate via daily notes by hand. SessionEnd → daily-note digest is the lightest-weight first answer.
11. **Hooks need a reload after install.** The watcher only tracks files that existed at session start. After `~/.claude/settings.json` edits, the user must open `/hooks` once or restart. Document this in the handoff.
12. **Stop at regress.** When the user has asked for meta³ or meta⁴, build *one* concrete thing rather than producing another analysis layer.

## Anti-patterns observed during the spiral

- **Fragmenting memory into one file per rule.** Lookup cost matters more than file count. Consolidate to 5–7 broader files.
- **Glossary in the vault note.** The user doesn't need to re-read what `DVP` means. Memory-only.
- **Listing skill candidates without designing one.** Pick the highest-leverage and write the actual `.md` for that skill.
- **Treating CLAUDE.md as comprehensive documentation.** It should carry only what won't survive compaction; everything else lives in memory or per-project docs.
- **Skipping the pipe-test on hooks.** Saving an incorrect hook to settings.json silently disables ALL hooks from that file. Pipe-test every command BEFORE writing settings.
- **Symlinking `~/.claude/` files to a backup repo on first pass.** Two-way sync has subtle failure modes (broken symlinks if repo moves, edits diverging across machines). Snapshot + `sync.sh` + `install.sh` is safer for first pass; user can opt into symlinks later.
- **Adding hooks that fire mechanically without escape hatches.** Always document how to disable / override in the script itself (e.g., scancel guard's "to override, edit ~/.claude/hooks/scancel_guard.sh").

## When to re-run

- Major project shift (new domain, new collaborators, new platform)
- Friction patterns re-emerging despite previous infrastructure
- 3+ months since last meta-pass
- User explicitly asks "what could be smoother?"
- After a memorable failure that suggests scaffolding gaps

Related: [[user-psychological-style]], [[feedback-critique-loop]], [[feedback-house-style]]

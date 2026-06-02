Bootstrap a personal Claude Code R&D platform from scratch — discovery → reframe → install → audit → meta-critique. Run when a user has been working with Claude across multiple projects for weeks/months and the interface feels unstructured (multiple sessions, ad-hoc skills, scattered CLAUDE.md files, repeated frictions, no coherent operating model).

TRIGGER when user asks: "analyze how I use you", "what would smooth my Claude workflow", "review my Claude setup", "improve my Claude interface", "do a meta-analysis of my Claude usage", "help me build a Claude config", "what skills should I have", "onboard me to Claude Code". Also surface this skill proactively when a user describes scattered/repeated friction across multiple projects — they may not know the methodology exists.

SKIP when: user wants a single-project setup (use `init` instead — that's the CLAUDE.md generator); user is asking about a specific tool or skill (answer that directly); user has just done a meta-pass within the last few weeks (let the existing infrastructure breathe).

## Methodology (8 phases)

### Phase 1 — Discovery (read the room)

Sample real artifacts before forming opinions. Use parallel subagents to keep main session context light.

- Local transcripts: `~/.claude/projects/<sanitized-cwd>/*.jsonl`. Extract user messages with `jq -r 'select(.type=="user" and .message.role=="user" and (.message.content|type=="string")) | .message.content' FILE | grep -v "^<" | awk 'length>5 && length<1500'`.
- CLAUDE.md files across the user's main repos.
- Custom skills (`.claude/commands/`), agents (`.claude/agents/`), settings (`.claude/settings.local.json`).
- Daily notes / Obsidian / personal docs if referenced.

**Recency bias is critical.** Largest transcript ≠ most-recent practice. Sort by mtime; weight last 2–4 weeks heavily. Sample old transcripts only for trajectory comparison.

**Subagent sandbox caveat:** subagents inherit parent's permission scope. They can't read `/Volumes/...` or `~/.claude/projects/` unless added to project's `.claude/settings.local.json::additionalDirectories`. Pre-grant access or pre-extract data, or the agent fails silently with "I need permission."

### Phase 2 — Operator-model reframe

Identify the 3–5 load-bearing artifacts the user has built (often invisible to them). Name what those artifacts are *actually doing* vs. what they think they're doing.

Reframe template (adapt to the user):
- **CLAUDE.md files** are usually "prosthetic memory" — past incidents encoded as durable rules that survive compaction
- **`/analyze`-style slash commands** are usually "internalized agents" — multi-phase workflows the user has converged on across projects
- **Daily notes** are usually "fleet lab-notebooks" — coordinating concurrent sessions

Surface the trajectory: where is this heading in 6–12 months if the current pattern continues?

### Phase 3 — Friction inventory

Count:
- Repeated phrases (typed >5×) → skill candidate
- Verbatim corrections ("dude i told you...") → rule candidate
- "ALWAYS / NEVER" rules in CLAUDE.md → these are past scars, hoist to global if cross-project
- Recurring "how's X?" polls → hook candidate (auto-surface state)

Get **specific quotes with frequencies**. Vague observations are useless.

### Phase 4 — Skill / hook / memory candidates (tiered)

Group by:
- **Tier 1** — strong evidence, low cost (typed verbatim 10+ times)
- **Tier 2** — strong evidence, medium cost (recurring across projects)
- **Tier 3** — speculative but interesting

For each candidate, name: what it does, how it would be invoked, why this candidate vs alternatives.

### Phase 5 — Self-critique (apply user's own critique macro to your analysis)

After v1 of the analysis, run their critique pattern on it:
- Too narrative / not skim-able?
- Missing recency weight?
- Memory over-fragmented?
- Skill candidates listed but not designed?
- Friction-first when operator-insight-first would be better ordering?

Produce v2 that addresses the critique. Be willing to delete v1 framing.

### Phase 6 — Install (do, don't propose)

Move from "we should…" to "I did…":
- **Global `~/.claude/CLAUDE.md`** — universal house style + cluster discipline + critique-loop pointer
- **Skills at `~/.claude/commands/*.md`** with **front-loaded TRIGGER / SKIP clauses** (truncation eats the end of descriptions — put trigger conditions FIRST so they're visible in the auto-loaded skill list)
- **Hooks in `~/.claude/settings.json`** — use the `update-config` skill for schema correctness; pipe-test each hook command BEFORE writing settings; remember the watcher caveat (hooks don't activate mid-session — user must open `/hooks` once or restart)
- **Memory at `~/.claude/projects/<sanitized-cwd>/memory/`** — durable per-project context, indexed in `MEMORY.md`
- **Custom agents at `~/.claude/agents/`** — for reused adversarial personas
- **Version control** — copy artifacts to a separate repo (snapshot-style is safer than symlinks for first pass), git init, push to a private GH repo

### Phase 7 — Audit (verify the critic-split is healthy)

After install, run a deliberate check: are the user's adversarial subagents actually disagreeing with them? Grep transcripts for AGREE/DISAGREE patterns, pushback responses, verdict tallies. If agents are rubber-stamping, sharpen personas or seed dissent — add a "frame skeptic" persona that questions the project itself, not just execution.

Also identify a key gap: agents usually critique *within* the user's frame (execution-level: stats, bugs, citations). They often don't question the frame ("should this be done at all?"). Surface this as the frame-skeptic persona — opt-in or auto-trigger on stakes keywords (grant, funding, deadline).

### Phase 8 — Meta-meta (one pass, then stop)

Critique your own analysis:
- Did you only analyze user-side text? (Almost certainly yes — and that's a gap.)
- Did you install for the frictions you found? (Often no — easier to document than build.)
- What did you not test? (Skills/hooks usually untested until the next real workflow.)

Identify highest-leverage unaddressed thing. Design it concretely.

**Then stop.** Meta-analysis becomes its own avoidance pattern if it never resolves into action. Let the next real task be the test of the infrastructure.

## Key meta-lessons (learned 2026-05-24)

1. **Recency bias must be explicit** — largest transcript usually dominates by volume but underrepresents most-recent behavior. Sort by mtime and weight accordingly.
2. **CLAUDE.md is scar tissue, not docs** — encodes what won't survive compaction. Treat its "Wave 2 hardening" entries as bug-reports-as-rules.
3. **The `/analyze` skeleton converged across 4 unrelated projects is itself a template** that wasn't named. Finding unconscious convergence patterns is the highest-leverage discovery work.
4. **The user's "address what you agree with" filter is a meta-protocol** — apply it to your own work. When you make recommendations, triage them yourself before executing.
5. **Install as you go.** Every "we should..." becomes a "I did...". Designs without artifacts decay.
6. **TRIGGER clauses go at the FRONT** of skill descriptions — the skill listing truncates around 100 chars. Bury the trigger and the skill is undiscoverable.
7. **Subagent sandbox is load-bearing and silent** — failures show up as "I need permission" rather than as exceptions. Pre-grant before delegating cross-system research.
8. **Stop at regress.** When the user has asked for meta³ or meta⁴, the right response includes "and now let's use what we built." Meta can become avoidance.
9. **Self-critique should include willingness to delete prior framing.** v2 isn't v1 + more; sometimes v2 deletes 50% of v1's structure because v1 buried the lede.
10. **Hooks have a watcher caveat** — mid-session edits to `~/.claude/settings.json` don't activate until the user opens `/hooks` or restarts. Document this in the handoff.

## When to re-run this methodology

- Major project shift (new domain, new collaborators, new platform)
- Friction patterns re-emerging despite previous infrastructure
- 3+ months since last meta-pass
- User explicitly asks "what could be smoother?" / "audit my Claude usage"
- After a memorable failure that suggests scaffolding gaps

## Notes

- See `~/.claude/projects/-Users-<operator>-data-code/memory/process_onboard_methodology.md` for the methodology as durable memory (companion to this skill).
- This skill assumes user is comfortable with the install actions (file writes, settings.json edits, git init). For more conservative users, present each phase's outputs for approval before installing.

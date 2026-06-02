---
name: feedback-use-agents
description: "the operator prefers parallel subagent dispatch for non-trivial work; cap is flexible (typically 3, sometimes 4); mind the sandbox caveat"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a5e7d312-de62-4697-a680-4de8f458852a
---

**Rule:** For non-trivial multi-part work — code review, broad refactors, parallel data-mining, multi-perspective critique — dispatch subagents in parallel.

Their verbatim phrases:
- "use agents where able - up to 3"
- "use agents in parallel for non-overlapping work"
- "launch 3 agents to review all"
- "launch multiple review agents"
- "use 4 agents where able" (May 18 — cap scales with problem)

**Why:** Optimizing for wall-clock and main-session context. Parallel agents carry independent context, surface independent failure modes (especially for critique work), and don't pollute their window with raw search output.

**How to apply:**
- When a task decomposes into independent sub-tasks (mining different file sets, reviewing from different POVs, parallel searches), default to parallel subagents.
- Default cap 3, scale to 4 for larger work, don't go beyond unless they asks.
- **Brief them thoroughly** — they have zero context. Include: what they's trying to do, what they's already ruled out, file paths/line numbers, the form of the answer (length, structure).
- Tell each agent its slice explicitly so they don't overlap.

**Critical: subagent sandbox caveat.** Subagents inherit the **parent session's sandbox/permission scope**, not the parent's per-call allowances. They cannot read paths outside the project root (notably `/Volumes/pool-mann-<operator>/` or `~/.claude/projects/`) unless those are in the configured `additionalDirectories`.

**Candidate format (failure observed, fix unverified):**

```json
{
  "permissions": {
    "additionalDirectories": [
      "$HOME/.claude",
      "$HOME/code/claude-config",
      "/Volumes/pool-mann-<operator>/code_bin"
    ],
    "allow": [...]
  }
}
```

**Hypotheses about where this needs to live for subagents to inherit:**

- `~/.claude/settings.local.json` (user-global) — loaded at *session-launch*; **hypothesis: subagents inherit from here.** Added 2026-05-24 end-of-session but not isolated-tested.
- `<cwd>/.claude/settings.local.json` (project-local) — **confirmed failure:** works for the main session but does NOT propagate to subagents, even when added mid-session before dispatch.
- Mid-session edits to either file appear to not take effect until session restart for subagent purposes.

**What's confirmed (2026-05-24 scar):**

- Project-local `.claude/settings.local.json::permissions.additionalDirectories` added mid-session → subagent dispatch STILL denied → 2× silent "I need permission" failures.
- Adding to user-global `~/.claude/settings.local.json::permissions.additionalDirectories` (then dispatching new subagents) → subagents succeeded — but the test wasn't clean (file dependencies overlapped, so the success isn't isolated to the grant).

**What's NOT confirmed:**

- Whether `~/.claude/settings.local.json` actually causes the propagation, or whether something else (session age, cache, another setting) was the real factor.
- Whether the grant needs to be at `permissions.additionalDirectories` (current form) vs top-level `additionalDirectories`.
- Whether the grant takes effect mid-session in the new file location, or only on next session-launch.

**Verification recipe (do before claiming "verified"):**

1. Start a fresh session in a project whose cwd does NOT have a project-local `.claude/settings.local.json`.
2. With `~/.claude/settings.local.json::permissions.additionalDirectories` NOT including pool, dispatch a subagent to read a pool path. **Expect: denied.**
3. Add the grant to `~/.claude/settings.local.json`. Restart the session. Dispatch the same subagent. **Expect: granted.**
4. If step 3 succeeds and step 2 fails, the user-global grant is the working incantation. Until that test runs, this file's title stays "Candidate format (unverified)".

**Recipe before delegating outside cwd (operational, even with verification pending):**

1. Check `~/.claude/settings.local.json::permissions.additionalDirectories` contains the path you need.
2. If not — add it, then restart the session before dispatching.
3. If you can't restart — pre-extract the data to within cwd, or symlink in.
4. Don't trust mid-session edits to project-local settings to propagate to subagents.

**The scar (2026-05-24 meta-analysis):** both subagents denied access to pool + `~/.claude/` despite project-local `additionalDirectories` grant created mid-session. Diagnosed only after both came back empty. The agent that would have caught this (frame-auditor.md, delegation-outpaces-scaffolding rule) was the one being drafted, so the rule fired in real time — but per v3's self-critique, "rule fires on its own platform breakage" is *not by itself* evidence the rule is generative. Could be coincidence.

Related: [[feedback-critique-loop]], [[project-pool-and-workflow]]

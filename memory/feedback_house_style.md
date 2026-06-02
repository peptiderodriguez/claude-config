---
name: feedback-house-style
description: "the operator's interaction conventions — AskUserQuestion always, plan mode first, terse tone, numbered-reply coupling, never write to /tmp"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a5e7d312-de62-4697-a680-4de8f458852a
---

**Rules — apply across all projects:**

1. **`AskUserQuestion` for every prompt.** Never list options or solicit input as inline chat text. Free-text answers (paths, names, custom values) go through the auto "Other" field with 1-2 example options provided. Batch up to 4 independent questions in one call. Hard-coded into every project's `/analyze` command.

2. **Enter plan mode first** for any implementation task. From `imaging-seg` CLAUDE.md: *"Always enter plan mode first for implementation tasks."*

3. **Terse tone, no narration.** Don't preamble what you're about to do. Show commands briefly, then run. A good interaction "feels like a knowledgeable colleague walking you through, not a textbook." No long lists of options unless asked.

4. **Numbered replies couple to your prior numbering.** When they answers a numbered plan with "1. ok 2. ok address 3. ...", the numbers refer to your previous message's items. If you renumber between turns, you break the coupling. Either keep numbering stable or restate the item.

5. **Never write to `/tmp`.** Verbatim correction in May 16 transcript: *"dude i thought i told you not to write to tmp - that is non-recoverable."* Persist scripts under `<project>/scripts/` or `<dataset>/scripts/`. Logs under `_shared/slurm_logs/`. Outputs that vanish on reboot are non-debuggable.

6. **At ~15% context remaining: update auto-memory, sync docs, commit uncommitted work.** Tell the user you're doing it. From `imaging-seg` CLAUDE.md: *"When continuing a session (context compacted): read memory files first."* Compaction-resume is frequent (≥3 cases in May 13-18 window).

7. **Treat them as a counterparty after dispatching agents.** When they asks *"do you agree with the review?"* / *"do you agree with these findings?"*, give your own opinion — not a re-summary. They's checking whether you have an independent take on the work the subagents did.

**Why:** Each rule is in a CLAUDE.md somewhere already; consolidating here so they survive into projects that don't have their own CLAUDE.md yet, and so a single global update propagates.

**How to apply:** Default to all of the above unless the project's local CLAUDE.md explicitly overrides.

Related: [[feedback-critique-loop]], [[feedback-use-agents]], [[feedback-slurm-discipline]]

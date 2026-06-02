# How auto-firing works

The point of this config is that discipline fires *mechanically* — you don't have to remember the rule. Skills auto-fire on phrase patterns; hooks fire on tool events. Five worked examples:

??? example "1 — \"how are the jobs?\" → mechanical state-injection"
    User: *"how are the jobs going?"*

    Hook chain (UserPromptSubmit):

    1. `squeue_inject.sh` runs `squeue -u $USER` and injects the current job table as context.
    2. `re_derive_state_inject.sh` detects the status phrasing and injects: *"RE-DERIVE STATE FROM DISK — don't quote from a stale summary. squeue / sentinel mtime / 4-state diagnosis."*

    Claude answers grounded in live disk state, not its own prior message.

??? example "2 — Agent tries to write `/tmp/scratch.py` → hard block"
    Tool call: `Write(file_path="/tmp/scratch.py", ...)`

    `tmp_write_guard.sh` (PreToolUse, Write matcher) returns `permissionDecision: "deny"` citing the scar (*"non-recoverable"*). The write fails loudly; Claude redirects to `<project>/scripts/`.

??? example "3 — \"review the migration plan\" → /critique auto-fires"
    User: *"review the migration plan for issues / bugs / inefficiencies"*

    - The TRIGGER clause on `commands/critique.md` matches "review" + the verbatim checklist.
    - The skill dispatches 3 parallel adversarial agents (methodology / engineering / tests-docs).
    - Grant context auto-adds the Frame-skeptic persona.
    - Step 5.5 dispatches `dissent-auditor` to check the personas didn't converge.
    - Synthesis: blockers + convergent concerns + persona-specific findings + "what they agreed was fine" + Claude's independent take.

??? example "4 — Edit to a grant doc → headline-numbers regression check"
    Tool call: `Edit(file_path=".../grant-repo/biology_for_grant.md", ...)`

    `headline_numbers_check.sh` (PostToolUse, Edit matcher):

    1. Walks up to the repo root.
    2. Reads `<repo>/.claude/headline_numbers_check.yaml`, finds `trigger_paths` matching the edited file.
    3. Runs the project's headline-numbers regression test.
    4. If a locked number drifted, emits a loud warning telling Claude to re-derive from the canonical CSV rather than silently re-edit the test to match.

??? example "5 — Subagent briefing references an unmounted path → preflight warning"
    Tool call: `Task(prompt="Read /fs/<pool>/<project>/CLAUDE.md and report")`

    `subagent_sandbox_preflight.sh` (PreToolUse, Task matcher):

    - Scans the prompt for absolute paths under `/Volumes/`, `/fs/`, `/tmp/`, `~/.claude/projects/`.
    - Checks each against *this* cwd's `.claude/settings.local.json::additionalDirectories`.
    - Uncovered path → warns that the subagent will fail silently with "I need permission," and lists the three fixes (add the prefix to the cwd-local settings, pre-extract the data inline, or scope the agent to readable paths).

See the full [Hooks catalog](../catalog/hooks.md) for every hook and its trigger event.

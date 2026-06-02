Maintain the daily-note `CLAUDE SESSIONS:` block in the operator's Obsidian vault — append a new session entry on start, remove on end, or just show today's current list.

TRIGGER when user asks: "what sessions are running?", "what sessions do I have?", "show my Claude sessions", "log this session", "add this to the daily note", "update sessions list", "what am I working on today?". Also trigger proactively at session start in a project that lives under `/Volumes/pool-mann-<operator>/code_bin/` or `/Users/<operator>/data/code/` — offer to log the session.

SKIP when: not running on the operator's machine (no `/Users/<operator>/data/code/obsidian_base/` directory); the daily note already has this session+path logged; the user is in a one-off ephemeral cwd (e.g. `/tmp`, `~/Downloads`).

## Sequence

1. **Resolve today's note.** Format: `/Users/<operator>/data/code/obsidian_base/<DayOfWeek MMM DD YYYY>.md` (e.g. `Sunday May 24 2026.md`). Compute from `date +'%A %B %d %Y'` (strip leading 0 from day if present). If the file doesn't exist, create it with an empty `- CLAUDE SESSIONS:` block at the top.

2. **Determine the session name.** AskUserQuestion: *"Session name for this Claude Code session?"* — provide 2-3 suggestions based on cwd (basename of cwd, last component of pool path, or a short task label) + Other for free text. Names should be short, tmux-style: `grant`, `binder-design2`, `aging-study`, etc.

3. **Determine the path to log.** Use `$PWD`. If under `/Volumes/pool-mann-<operator>/`, normalize to the `/fs/pool/pool-mann-<operator>/` form (their daily notes use the HPC form — that's the canonical reference). Show both and let them confirm.

4. **Edit the daily note.** Find the `- CLAUDE SESSIONS:` block. Insert under it: `    - <session-name>: <path>`. If the same session-name already exists with a different path, ask whether to update or add as new (e.g. `grant2`).

5. **Confirm to the user** in one line: `Logged: grant → /fs/pool/pool-mann-<operator>/code_bin/grant-repo`.

## End-of-session variant

If user says "end session", "I'm done with this session", "remove from daily note", or similar: ask which session-name to remove, then strip its line from the block. Confirm in one line.

## Show-only variant

If user asks "what sessions am I running?" or "show today's sessions": just `cat` the `CLAUDE SESSIONS:` block from today's note (and yesterday's if today is empty). Don't prompt — just show.

## Notes

- The block format the operator uses is YAML-flavored markdown bullet:
  ```
  - CLAUDE SESSIONS:
      - grant: /fs/pool/pool-mann-<operator>/code_bin/grant-repo
      - aging-study: /fs/pool/pool-mann-<operator>/code_bin/imaging-seg
      - binder-design2: /fs/pool/pool-mann-<operator>/code_bin/binder-design
  ```
- Same repo can host multiple task-scoped sessions (e.g. `session-b` + `rlink` + `session-a` all in `proteomics-quant`). Don't reject a duplicate path; check the name.
- This skill replaces manual book-keeping. The daily note is the operator's inter-session working memory — it must stay accurate or it becomes worse than nothing.
- Don't auto-remove on session end unless the user explicitly asks — sessions sometimes pause and resume.

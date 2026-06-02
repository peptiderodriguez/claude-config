# Memory (9)

Durable cross-session facts live in `memory/*.md`, indexed by `memory/MEMORY.md`. Each file holds one durable fact or pattern, linked to others with `[[wikilinks]]`.

!!! info "How memory loads"
    Claude keys durable memory to the **sanitized cwd**: `~/.claude/projects/<sanitized-cwd>/memory/`. The index loads when you start a session whose cwd matches the installed memory directory (the operator's is `~/data/code`; `install.sh` derives it from your `$HOME`). Rules, skills, hooks, and agents are cwd-independent and always load.

| File | Holds |
|---|---|
| `user_psychological_style` | Relational stance; trajectory anxious-supervisor → trusting-but-auditing |
| `feedback_house_style` | Interaction conventions: AskUserQuestion, plan-mode-first, terse, never `/tmp` |
| `feedback_critique_loop` | The full review checklist + adversarial-subagent macro |
| `feedback_use_agents` | Default-to-parallel; the subagent sandbox-inheritance caveat |
| `feedback_slurm_discipline` | No login node; `scancel` by job-id; stale-state hygiene; proactive `squeue` |
| `feedback_no_fabricated_panels` | PDF-grep before citing gene lists "from paper X" (the panel scar) |
| `project_pool_and_workflow` | `/Volumes`↔`/fs` symmetry, repo map, multi-session + daily-note coordination |
| `stop_parsing_restructure_the_substrate` | When the N-th bug-fix spawns the next edge case, fix the representation |
| `process_onboard_methodology` | Rationale + meta-lessons companion to the `/onboard` skill |

Because these are personal, [pruning memory](../adapt/index.md) is the first thing to do when you fork. Browse the files at `https://github.com/peptiderodriguez/claude-config/tree/main/memory`.

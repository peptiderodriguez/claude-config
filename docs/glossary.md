# Glossary

Terms used throughout this repo that assume context. Most come from the operator's HPC/proteomics world; you can ignore the domain-specific ones if you're adapting only the general tiers.

| Term | Meaning |
|---|---|
| **the operator** | The repo's author / primary user. The config and memory are written in the third person about them. If you adopt this, that's you. |
| **scar / scar-tissue** | A rule that exists because of a specific past incident, not as generic advice. The whole `CLAUDE.md` is "scar-tissue only" — see [Why scar-tissue rules](philosophy/index.md). |
| **flywheel (not pipeline)** | A driving philosophy: prefer closed loops where outputs feed back as inputs (data → adapters → fixtures → predictions → wet-lab → data) over one-shot A→B→C pipelines. |
| **TRIGGER clause** | The line at the top of a skill/agent file listing the phrases or conditions that make it auto-fire (e.g. `/critique` fires on "review"). |
| **`/onboard` vs `/analyze`** | Two "build-your-own" skills, easily confused. **`/onboard`** mines *your* Claude usage to build a *config* like this repo. **`/analyze`** is a *per-project* interactive front-door that guides a user through *that project's pipeline* — you generate one per project (e.g. via the `scaffold-analyze` skill), it isn't a single shipped command. |
| **hook** | A shell script wired to a Claude Code event in `settings.json` (UserPromptSubmit, PreToolUse, PostToolUse, PostCompact, SessionEnd) that runs automatically — see the [Hooks catalog](catalog/hooks.md). |
| **memory** | Durable cross-session facts in `memory/*.md`, loaded by cwd — see the [Memory catalog](catalog/memory.md). |
| **vault mode** | A mode of the `/orient` skill: when run from the Obsidian notes vault (not a code repo), it surfaces the *sibling* Claude sessions you're coordinating instead of one repo's state. |
| **sentinel** | A marker file (e.g. `.quant-runner_done`, `_complete.json`) that signals a long job finished. The rules insist sentinels be written only *after* success, and checked against input mtimes ("stale sentinel"). |
| **`additionalDirectories`** | A Claude Code `settings.local.json` permission field listing paths a session (and its subagents) may read outside the cwd. Subagents don't inherit the user-global one — see the subagent sandbox hook. |
| **pool** | The lab's shared network storage, mounted at `/Volumes/pool-mann-<operator>/` on Mac and `/fs/pool/pool-mann-<operator>/` on the cluster. |
| **SLURM / sbatch / squeue / scancel** | The HPC job scheduler and its submit / queue-query / cancel commands. Several hooks guard these (e.g. block `scancel -u $USER`). |
| **headline numbers** | Locked published/grant figures kept in a project source-of-truth file; a hook re-runs a regression when a file that feeds them is edited, to catch silent drift. |
| **DFG / NIH / NSF** | Research funding agencies. `grant-work-mode` and the `dfg-reviewer` agent target grant-submission work. |
| **PI** | Principal Investigator — the lab head. |
| **binder-design / imaging-seg / clinical-omics / grant-repo / proteomics-quant** | Generic stand-in codenames for the operator's other project repos, cited as the source of various rules/patterns. Not part of this repo. |

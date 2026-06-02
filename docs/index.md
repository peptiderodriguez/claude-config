# claude-config

Personal [Claude Code](https://claude.com/claude-code) configuration for cluster-scale R&D work: global rules, custom skills with auto-fire TRIGGERs, custom agents, mechanical-enforcement hooks, durable memory, and the meta-analyses that produced them.

It installs into `~/.claude/` and **auto-fires the right discipline at the right time** across every session — so you don't have to remember the rule.

!!! warning "Snapshot, not a framework"
    This is *one researcher's* config, captured as a snapshot (sync explicitly with `./sync.sh`). It's a worked example to learn from and adapt — not a turnkey product. The memory and rules encode personal, domain-specific (proteomics / HPC) context.

!!! info "\"the operator\""
    Throughout these docs, **"the operator"** = the repo's author / primary user; the config is written in the third person about them. If you adopt this, that's you.

## What it gives you

- **11 global skills** with TRIGGER clauses — fire automatically when their phrase patterns appear in your prompt.
- **3 custom agents** — adversarial review (`dfg-reviewer`), CLAUDE.md-compliance audit (`frame-auditor`), dissent meta-check (`dissent-auditor`).
- **14 hooks** — mechanically enforce rules (block destructive commands, inject state on status questions, scar-anchored pre-flight checks).
- **Durable memory** across sessions for patterns that don't fit the global `CLAUDE.md`.
- **Portable building blocks** — drop the anti-rot tier into a fresh repo in minutes (see [Building blocks](adapt/building-blocks.md)).

## Inventory at a glance

| Component | Count | Where |
|---|---:|---|
| Global rules | 1 | `CLAUDE.md` |
| Skills | 11 | `commands/*.md` |
| Hooks | 14 | `hooks/*.sh` + `settings.json` |
| Agents | 3 | `agents/*.md` |
| Memory files | 11 (+ index) | `memory/*.md` |
| Helper scripts | 3 | `scripts/` (incl. the anonymization filter) |

## Install

=== "Mac / Linux"

    ```bash
    git clone <repo-url> ~/code/claude-config
    cd ~/code/claude-config
    ./install.sh        # copies into ~/.claude/, backs up existing files
    ```
    Then reload the hook watcher: type `/hooks` in Claude Code, or restart the session.

=== "Cluster / HPC"

    See the [Cluster install runbook](install/cluster.md) — it covers the `jq` dependency, JSON validation, and per-project `additionalDirectories` wiring.

## Read next

- [Why scar-tissue rules](philosophy/index.md) — the idea that every rule traces to a real incident.
- [How auto-firing works](philosophy/auto-firing.md) — five worked examples of hooks + skills firing.
- [Catalog](catalog/skills.md) — browse the skills, hooks, agents, and memory.
- [Make it yours](adapt/index.md) — fork it without inheriting someone else's brain.

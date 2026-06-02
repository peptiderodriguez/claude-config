# Build your own: the `/onboard` meta-analysis

This whole repo wasn't designed top-down — it was **mined** from how the operator already worked, using a repeatable methodology. That methodology is the `/onboard` skill (it auto-fires on *"analyze how I use you"* / *"audit my Claude setup"* — the "`/analyze`-style" meta-analysis). Run it to bootstrap *your* config the same way.

!!! tip "When to run it"
    You've worked with Claude across several projects for weeks+, and the setup feels unstructured — scattered `CLAUDE.md` files, ad-hoc skills, the same frictions recurring. Also: a major project shift, friction re-emerging despite prior fixes, 3+ months since the last pass, or after a memorable failure. **Skip** for single-project setup (use `/init` instead) or if you just did a meta-pass.

## The 8 phases

1. **Discovery** — sample real artifacts before forming opinions: your transcripts (`~/.claude/projects/<cwd>/*.jsonl`), `CLAUDE.md` files, existing skills/agents/settings, daily notes. Use parallel subagents to keep context light. **Weight the last 2–4 weeks heavily** — the largest transcript isn't the most current practice.
2. **Operator-model reframe** — name the 3–5 load-bearing artifacts you've built and what they're *actually* doing (CLAUDE.md = prosthetic memory; `/analyze`-style commands = internalized agents; daily notes = fleet lab-notebook). Project where it's heading in 6–12 months.
3. **Friction inventory** — count, with specific quotes + frequencies: phrases typed >5× (skill candidates), verbatim corrections (rule candidates), recurring "how's X?" polls (hook candidates).
4. **Tiered candidates** — group skill/hook/memory ideas by evidence × cost (Tier 1 strong+cheap → Tier 3 speculative). Design each, don't just list it.
5. **Self-critique** — run your own critique macro on the v1 analysis (too narrative? missing recency? candidates listed-not-designed?). Produce a v2 willing to delete v1 framing.
6. **Install (do, don't propose)** — write the global `CLAUDE.md`, skills (TRIGGER clause **first** — listings truncate ~100 chars), hooks (pipe-test before wiring; reload the watcher), memory, agents; then version-control it (snapshot repo + git).
7. **Audit the critic-split** — check your adversarial agents actually *disagree* with you; if they rubber-stamp, sharpen personas or add a frame-skeptic that questions the project itself, not just execution.
8. **Meta-meta (one pass, then stop)** — critique your own analysis, pick the highest-leverage gap, build it — then **stop**. Meta-analysis becomes avoidance if it never resolves into action.

## Then let the next real task test it

The output is a `~/.claude/` like this repo: rules + skills + hooks + memory + agents, under version control. Don't keep meta-analyzing — the next real workflow is the test.

See the [`/onboard` skill source](https://github.com/peptiderodriguez/claude-config/blob/main/commands/onboard.md) for the full methodology and the [Provenance](../provenance.md) page for the worked example that produced *this* config.

Bootstrap a new Claude Code agent spec with the conventions the operator has converged on across `dfg-reviewer`, `frame-auditor`, `dissent-auditor`, and the `xldvp_seg/.claude/agents/` set (annotation-trainer, detection-dev, lmd-export, pipeline-runner). Writes a stub to `~/.claude/agents/<name>.md` (global) or `<project>/.claude/agents/<name>.md` (project-scoped).

TRIGGER when user asks: "create a new agent", "draft an agent for X", "scaffold an agent", "make a subagent that …", "add an agent for the Y workflow". Also TRIGGER when user is hand-writing a long agent spec and would benefit from the template (offer once: "want me to scaffold this with the canonical sections?").

SKIP when: the user is editing an existing agent (use Edit instead); the request is for a one-off Agent dispatch in this conversation (just dispatch directly, no spec file needed).

## Sequence

1. **Gather inputs** via a single batched `AskUserQuestion`:
   - **Agent name** — short kebab-case (e.g. `vessel-pipeline-runner`)
   - **One-line purpose** — what the agent does, who invokes it
   - **Scope** — global (`~/.claude/agents/`) or project (`<cwd>/.claude/agents/`)
   - **Model** — sonnet (default) / opus / haiku
   - **Workflow shape** — linear-steps (like lmd-export) / debug-decision-tree (like detection-dev) / audit-and-verdict (like dfg-reviewer / frame-auditor)

2. **Ask TRIGGER + SKIP conditions** as a second batched question:
   - When should this fire proactively (TRIGGER)?
   - When should it explicitly NOT fire (SKIP)?

3. **Generate the stub** with these canonical sections (omit ones that don't apply for the chosen workflow shape):

   ```markdown
   ---
   description: <one-line purpose>.

   TRIGGER <conditions>.

   SKIP <conditions>.
   ---

   You are <role>.

   ## Architecture overview     ← include when agent works on a code tree
   ```
   <ascii tree of the modules this agent touches>
   ```

   ## Input                     ← include when agent takes structured input
   <what to expect: filepath, JSON shape, transcript window, etc.>

   ## Sequence                  ← for linear-workflow agents
   1. Step name. What to do.
   2. ...

   ## Decision tree             ← for debug agents (alternative to Sequence)
   | Symptom | Cause | Fix |

   ## Output format             ← always include
   <markdown schema: word budget, required headings, citation format>

   ## Tone
   <one paragraph: register, examples of what to mirror>

   ## Hard rules
   - <bullet list of don'ts>
   ```

4. **Write the file** to the resolved path. Confirm in one line: `Scaffolded: ~/.claude/agents/<name>.md (N lines). Edit to fill in the workflow.`

5. **Reminder** to add the new agent name to `~/code/claude-config/sync.sh` if it should be captured into the repo on next sync. (Currently sync.sh globs `agents/*.md` so this is automatic — but commands/ has a hardcoded list and may need updating if you also created a paired skill.)

## Conventions baked in

These come from auditing the 7 existing agents:

- **Frontmatter** has `description` only (Claude Code agents auto-pick model from the spec; explicit `model:` and `tools:` lines are optional and only needed when overriding).
- **TRIGGER and SKIP are part of the description block** — they're not separate sections. This lets the main Claude model see them at agent-discovery time.
- **Architecture trees go at the top** so future-Claude has the mental model before reading the workflow.
- **CLI flag tables** use the format `| Flag | Default | Purpose |` (see lmd-export.md).
- **Failure-pattern tables** use the format `| Pattern | Cause | Fix |` (see pipeline-runner.md).
- **Output sections** specify a word budget (≤300 or ≤400 words is the typical convention).
- **Tone sections** are short — one paragraph — and mirror the operator's house style (terse, no narration, no over-explaining).

## Tone of the scaffolded stub

The generated stub should be terse. Comments in `<...>` are placeholders for the user to fill in — don't generate placeholder prose like "Lorem ipsum" or "TODO: describe the workflow." Leave the angle-bracket marker so the user sees exactly where to type.

## Hard rules

- Don't write the workflow body — only the structure. The user fills it in.
- Don't overwrite an existing agent file without explicit confirmation.
- Don't add the new agent to `sync.sh` automatically — `agents/*.md` is already globbed there. (Update if user paired the agent with a new slash-command skill, since commands/ uses a hardcoded list.)

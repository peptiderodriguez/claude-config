# Agents (3)

Custom subagent specs in `agents/*.md`, used by the `/critique` skill and invokable directly.

| Agent | Persona / job | Invocation |
|---|---|---|
| `dfg-reviewer` | Adversarial DFG/NIH/NSF grant reviewer who previously denied this group funding. Exacting, not cruel. | Used by `/critique` in grant context; or `Agent(subagent_type="dfg-reviewer", …)` |
| `frame-auditor` | Audits a transcript against the `CLAUDE.md` meta-rules (stakes-flip-side, delegation-outpacing-scaffolding). Catches drift the user hasn't named yet. | Auto-fire from `session_end_audit.sh` when stakes-pin tokens are detected; or directly |
| `dissent-auditor` | Checks whether N parallel critique agents converged or stayed independent. Fires at `/critique` step 5.5. | Used by `/critique`; or directly when "have the personas converged?" |

!!! note "Registration caveat"
    Custom agents may not appear as `subagent_type` options out of the box. If `Agent(subagent_type="dfg-reviewer", …)` returns "agent type not found", invoke `subagent_type="general-purpose"` with the agent's prompt body embedded inline.

Browse the specs at `https://github.com/peptiderodriguez/claude-config/tree/main/agents`.

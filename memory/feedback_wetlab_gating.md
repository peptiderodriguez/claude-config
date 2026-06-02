---
name: feedback-wetlab-gating
description: "Don't push the operator toward wet-lab / expensive irreversible real-world steps until the computational pipeline is verified working"
metadata:
  node_type: memory
  type: feedback
---

**Rule:** Treat wet-lab (or any expensive, irreversible real-world step — ordering DNA, running an assay, committing reagents) as the *last* gate, downstream of a verified-green pipeline. Do not recommend or tee up a bench step while the computational pipeline that produces its inputs is broken or unverified.

**Why:** Operator (binder-design, 2026-06): *"i refuse to go into the lab and do experiments when our pipeline is so plainly not working. it will be difficult to process the data and do the analysis and experiments even in the best of circumstances."* Wet-lab effort is irreplaceable and slow; sending the operator to the bench on a broken pipeline wastes the scarcest resource to validate the cheapest-to-fix layer.

**How to apply:**
- Before recommending a wet-lab / order / assay step, confirm the producing pipeline is green: regression tests + end-to-end smoke + the relevant fail-closed gate.
- If it isn't green, name *that* as the blocker and fix it first — don't hedge the bench step with caveats.
- The order is: pipeline correct → results trustworthy (re-derived from disk) → *then* commit real-world resources.
- Couples to the flywheel: a wet-lab cycle launched on a broken pipeline doesn't feed clean data back in — it poisons the loop.

Related: [[feedback-slurm-discipline]]

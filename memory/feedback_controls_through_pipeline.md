---
name: feedback-controls-through-pipeline
description: "Positive/negative controls must run through the SAME standard pipeline as the samples — generated de novo, never special-cased or hand-built"
metadata:
  node_type: memory
  type: feedback
---

**Rule:** A positive or negative control must be produced by the *same* pipeline, with the *same* settings, as the real samples — generated de novo, not hand-assembled or special-cased. A control built by a bespoke shortcut validates the shortcut, not the pipeline the samples actually go through.

**Why:** Operator correction (binder-design, 2026-06): *"why would you do it this way? we need a real positive control — DE NOVO — as we will run with all our other proteins. so we need a solution that will give us the positive control with the standard pipeline."* A control that bypasses the production path proves nothing about the production path — and a green control on a bespoke route hides a broken pipeline.

**How to apply:**
- When asked for a positive/negative control, route it through the standard pipeline end-to-end, not a one-off script.
- Refuse the convenient hand-built control even when it's faster — that's a `correct-over-expeditious` shortcut.
- If the standard pipeline *can't* produce the control, that's a pipeline gap to fix, not to bypass — surface it as the blocker.
- Generalizes beyond binders: any benchmark/calibration/known-truth case should be emitted by the same machinery as the unknowns it calibrates.

Related: [[feedback-no-fabricated-panels]]

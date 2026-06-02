---
name: stop-parsing-restructure-the-substrate
description: "When a bug-fix saga keeps spawning edge cases, the parser is the wrong abstraction — find the structured representation that makes the bug-class impossible. Verified across minibinder citation_audit (free-form prose → DataFrame manifest) and SIFTS residue numbering (linear-offset → per-segment map)."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: efeaff81-e566-461c-9d34-16e1384a7c52
---

When the third or fourth fix in a row to the same module keeps creating new edge cases, the bug is NOT in any specific line — it's in the **substrate**. You're trying to parse / regex / heuristically extract from data that's only ambiguous because the *shape* of the data is wrong. The fix is to **stop parsing**, and instead build a structured representation that makes the ambiguity impossible by construction.

**Why:** the operator has the receipts for this pattern across at least 3 incidents:

1. **Citation audit (the canonical example).** Verbatim from `/Volumes/pool-mann-<operator>/code_bin/minibinder/src/perturb_phos/citation_table.py:1-34`: *"The original citation gate tried to PARSE which `Author Year Journal` triple bound to which `PMID` out of free-form prose. That binding is inherently ambiguous in prose (adjacent citations, line-wraps, 'resolves to X' correction notes), so the regex extractor leaked 'cross-bleed' false-positives and — worse — leniency added to suppress them opened a fab-detection HOLE. Every fix spawned the next edge case. The fix is to stop parsing. A citation's identity is STRUCTURED DATA, not text proximity."* Replacement: a 7-column DataFrame at `data/citations.csv` (`pmid, first_author, year, journal, fixture, used_in, status`) — the audit becomes a table join. Demotion = a column value, not a prose marker. The fab-detection-hole closed in one move.

2. **Residue numbering / SIFTS.** Old: linear-offset between PDB author residue numbers and UniProt-canonical, computed lazily per call. Cherezov 2007 β2AR Y308=7.43 had a silent 8-residue offset that propagated into multiple fixtures. New representation: a per-segment SIFTS map keyed by PDB chain, materialized as canonical state. The off-by-N bug-class became unrepresentable.

3. **Per-target chain extraction.** Old: hand-symlinked `target.pdb` for each new target (the F-17 LCB1 hack). Each new target spawned a per-target maintenance burden. New representation: declarative `target.chain_extract` schema, the universal `select_target_chain` extractor reads from it. Every target uses the same code path; the per-target branch class is gone.

**How to apply:** When you find yourself writing the Nth patch in the same module — or proposing a leniency rule to suppress a regex false-positive — stop. Ask: *"What's the underlying ambiguity? What representation would make this ambiguity impossible?"* Usually the answer is a structured table (DataFrame, schema, registry) keyed on the thing the parser was trying to extract. One substrate refactor beats N patches, AND it usually closes a corresponding fab/leniency hole on the other side.

**Anti-pattern detection (catch yourself):**
- "Just one more case to handle"
- "Add this to the allowlist / ignore list / leniency rule"
- "Special-case for X, then we'll figure out the general fix later"
- Patch N+1 looks similar in shape to patch N

If any of these fire 2+ times in the same module, the substrate is wrong. Go up one level.

**Cross-project evidence:**
- minibinder: `src/perturb_phos/citation_table.py:1-34` (the verbatim rationale), `data/citations.csv` (the structured manifest), `scripts/audit_citation_table.py` (the new gate), `docs/representation_refactors.md:8` (the meta-doc)
- minibinder: `docs/findings_long_interface_phase0_2026-05-28.md` (the long-interface shape category — substrate refactor for pocket-less protein surfaces)
- xldvp_seg: `extract_positions_um` canonical extractor — replaced per-strategy position parsing
- ehr_proteomics_analysis: `_io_helpers.safe_write_tsv` — single helper enforces non-empty-required-rows invariant rather than each writer checking inline

**Caveat — when substrate-refactor is the WRONG move.** The 3 incidents above are selection-on-the-dependent-variable (only successes recorded). Substrate refactor is wrong when: (a) the bug truly IS one-off (a typo, a stale path, a missed config) and there's no class — patching is fine; (b) the substrate refactor invalidates expensive calibration / regression-test data that the project has already paid for (this is anti-flywheel; see global CLAUDE.md "Flywheel, not pipeline"); (c) the cost of the substrate refactor exceeds the cost of N patches over the bug's expected remaining lifetime (e.g., the module is being retired). Heuristic: substrate refactor earns its keep when N (expected patches) ≥ 3 AND there's no flywheel cost AND the new substrate can be tested for round-trip equivalence with the old. If any of these fail, patch.

Related: `[[feedback-no-fabricated-panels]]` (the citation scar this substrate move closed), `[[feedback-use-agents]]` (one-fix-at-a-time delegation vs substrate-level delegation).

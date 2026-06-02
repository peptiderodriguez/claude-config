---
name: anti-fabrication
description: When writing or auditing any artifact containing citable claims (PMIDs, PDB IDs, UniProt accessions, vendor catalog numbers, protocol parameters, drug doses, gene/protein sequences, URLs), enforce the discipline that every claim either (a) traces to a verified primary source with a working URL + access date OR (b) carries an explicit `[NEEDS X — check Y at Z]` curator handoff. Refuse to invent citations to fill gaps.
trigger: When the user asks to verify claims, audit a fixture, build a bench protocol, write a procurement doc, build a citation_audit block, ship a generalization fixture, or any time an artifact will contain claims that look citable. Also invoke proactively whenever drafting protocol steps, fixture residue lists, vendor catalog references, or PMID citations. NEVER skip this when the user warns about fabrication or invokes /anti-fabrication.
---

# Anti-fabrication skill

The single rule: **never assert a citable claim without an independently verified primary source.** If you can't verify, you don't assert — you mark with a concrete handoff.

## When this rule applies

Any artifact containing claims that look citable. The recurring failure modes that triggered this discipline:

| Source of error | How it manifests |
|---|---|
| Training-data hallucination | PMID numerals invented from a fluent template; resolve to unrelated papers |
| Stale prior knowledge | UniProt accession was correct in 2020, now reassigned to a paralog |
| Vendor URL drift | Citation points at an Addgene route that 404s; the depositor's plasmid moved |
| Sister-protein confusion | PDB ID names the right family but the wrong member (CXCR4 vs HTR2A; PTPN6 vs PTPN11) |
| "Common knowledge" | Asserting cycle parameters / cell densities / doubling times without vendor source — drift over revisions |
| Convenient match | Closing a `[NEEDS CITATION]` marker by finding a PMID that *looks like* it matches the existing residue list — circular calibration |
| User-supplied claim | A PMID / PDB / accession the *user* hands you is asserted unchecked because it came from a human — but user-supplied citations fail identically. Whole operator-supplied briefs have resolved, en masse, to unrelated papers / wrong protein families |

## The contract

For every claim that names:
- **A PMID** (e.g., `PMID:9219684`)
- **A PDB ID** (e.g., `5P21`)
- **A UniProt accession** (e.g., `Q06124`)
- **A vendor catalog ID** (e.g., `Takara 631341`, `Addgene 60955`, `Sigma D1515`)
- **A drug dose × cell × time** (e.g., `EGF 100 ng/mL HEK293T 15 min`)
- **A vendor protocol parameter** (e.g., Lipofectamine 3000 6-well: 2 µg DNA + 5 µL reagent)
- **A residue range** (e.g., "BRD4 BD1 spans residues 44-168")
- **A sequence** (e.g., a binder CDS, a vector backbone)
- **A URL** (especially vendor / database / preprint URLs)

You MUST do one of:

### A. Verify before asserting

1. **Fetch the primary source** (PubMed REST, RCSB REST, UniProt REST, the vendor's protocol PDF, the actual paper)
2. **Confirm the content matches the claim** — not just that the URL returns 200, but that the PAGE IS ABOUT WHAT YOU CITED. The 6/7 wrong HRAS PMIDs all returned 200; they just pointed at unrelated papers.
3. **Record the access date** alongside the URL so future drift is auditable
4. **Add a citation reference** in the artifact's standard format (`[REF-KEY §section]` or `provenance.citation_audit` block)

### B. Mark unverified with a CONCRETE handoff

If you can't verify (no network access, vendor PDF gated, sequence not on disk, no time):

1. **Do NOT assert the claim** as if verified
2. **Add an explicit handoff marker**: `[NEEDS PROTOCOL SOURCE — check Y at Z]` where Y names the specific document AND Z names where the operator/curator finds it (e.g., "the cryovial-specific Product Information Sheet shipped with the line", or "ATCC product page at <URL>", not just `[VERIFY]`)
3. **Demote the claim** out of the load-bearing path if possible (move it to `provenance.unverified_candidates` blocks per the F3 cleanup pattern, so the rediscovery test / regression test does NOT scored against unverified claims)
4. **Document what would need to be true** for the claim to verify (the minimum evidence)

### C. Preserve protocol flow

When auditing a step-by-step protocol (bench SOP, workflow), DO NOT strip the unverified step — the tech still needs the step to flow. Instead:

- **The step itself stays in the body** so the workflow remains continuous
- **The unverified parameters carry inline `[NEEDS PROTOCOL SOURCE]` markers** with the specific source the operator should pull
- **A `[BENCH STAFF CHECK]` appendix per module** can summarize what needs operator verification before running

Removing the step entirely would break the workflow — that's worse than keeping a flagged-but-flowing step.

## The five verification primitives (use these)

| Claim type | Verification primitive | Tool |
|---|---|---|
| PMID | Fetch `https://pubmed.ncbi.nlm.nih.gov/<id>/` + confirm title/authors/year match the claim | `WebFetch` or `Bash curl` |
| PDB ID | Fetch `https://data.rcsb.org/rest/v1/core/entry/<id>` + confirm structure title + ligands + chains match | `Bash curl` |
| UniProt accession | Fetch `https://rest.uniprot.org/uniprotkb/<acc>.json` + confirm gene name + organism + length match | `Bash curl` |
| Vendor catalog ID | Fetch the vendor's product page; confirm the product matches the cited use | `WebFetch` |
| Vendor protocol parameter | Fetch the vendor's protocol PDF (or product insert); confirm the parameter matches the cited revision | `WebFetch` |

When a verification primitive can't be exercised (no HTTPS, sandbox-blocked, gated content), the claim goes to category B above.

## The refusal pattern

When asked to assert a claim you can't verify, the response shape is:

> "I can't verify `<claim>` against a primary source from here — the vendor's protocol PDF is gated behind a sign-in / I have no outbound HTTPS to <site> / the cited PMID returns 404. Marking it as `[NEEDS PROTOCOL SOURCE — check Y at Z]` rather than asserting it. The curator handoff names <specific document> at <specific URL>."

NEVER:
- "Should be ~X based on my training" → if you can't verify, you don't know.
- "Standard practice is X" → no such thing as standard without a published source.
- "Most labs use X" → if you can't cite the labs, you can't cite the practice.
- "X is typical for Y" → ditto.

## Output formats

### For fixtures (ground_truth.yaml files):

```yaml
provenance:
  prepared_by: <author>
  prepared_utc: <ISO date>
  citation_audit:
    evidence:
      - claim_id: P01_switch_II_GEF_GAP_face
        citation_type: pmid
        citation_id: PMID:9219684
        verified: true
        verification_method: pubmed_lookup
        verified_utc: 2026-05-25
        snippet: "Scheffzek et al. 1997 Science 277:333 — Ras-RasGAP complex (1WQ1)"
      - claim_id: P01_switch_I_effector_binding
        citation_type: pmid
        citation_id: PMID:9419338
        verified: false
        needs_action: |
          Task-brief PMID resolved to "SOCS box paper" (Hilton 1998), NOT the
          claimed Pacold PI3K:HRAS paper. Curator should re-source from
          one of: 1HE8 (PI3K:HRAS cocrystal), 4G0N (RAF-RBD:HRAS cocrystal),
          or 121P (canonical H-Ras·GppNHp 1.5Å).
  unverified_candidates:
    good_patch_candidates:
      - id: P01_switch_I_effector_binding
        # entire patch text retained for curator review
        residues: [32, 33, ..., 40]
        actionable_handoff:
          curator_task: |
            Pull one of the suggested PDBs; extract Switch-I contact
            residues at 5 Å heavy-atom distance to the bound effector.
          suggested_pdb_ids: [1HE8, 4G0N, 121P]
          minimum_evidence: |
            PMID that demonstrates the residue list is the published
            effector-contact face; PDB IDs whose primary literature
            cites those exact residues.
```

### For bench protocols:

```markdown
**Procedure:**
1. Linearise the bridge backbone by PCR:
   - 25 µL Q5 2X Master Mix [NEB-M0492 §3] [URL VERIFIED 2026-05-25]
   - 2.5 µL forward primer (10 µM stock) [NEB-M0492 §3]
   - 35 cycles: 98°C 10s, 65°C 30s, 72°C 90s/kb [NEEDS PROTOCOL SOURCE — verify against NEB M0492 current product manual at the bench BEFORE running; the 35-cycle count is operator-side guidance, not a vendor-canonical value]

[BENCH STAFF CHECK before running Module 3A]
- NEB M0492 protocol page (your shipped product insert) — confirm cycling parameters match what's printed above
- Q5 buffer composition for your lot
```

### For procurement docs:

```markdown
| Drug | Vendor | Cat | Dose for HEK293T | PMID for dose |
|---|---|---|---|---|
| EGF (recombinant human) | PeproTech | AF-100-15 [URL VERIFIED 2026-05-25] | 100 ng/mL, 15 min [NEEDS CITATION — Olsen et al. 2006 Cell 127:635 reported this dose for HEK293; verify before purchase] |
```

## Forward-promised behaviors when this skill is active

1. **Pre-write search**: before asserting any citable claim, you check whether the claim is already in a citation_audit block somewhere in the project. If so, copy the citation from there with its `verified_utc` and `verification_method`. Don't re-verify what's already verified.

2. **Reject "trust me"**: if a user prompt asks you to "just write the protocol" or "make something reasonable", you respect that for non-citable scaffolding text BUT for any citable claim within the same text, you apply the contract above. You don't quietly invent citations to make a doc look complete.

3. **Cite the version that's true today**: when citing a vendor protocol or document, prefer the URL with `[URL VERIFIED <ISO date>]` so future drift is auditable. Where the document has a revision number (e.g. "Pub. No. MAN0009872 Rev. 4.0"), include it.

4. **Output a citation_audit block as standard**: when shipping any new fixture, doc, or protocol artifact that contains 3+ citable claims, end the artifact with a citation_audit block in the format above. This is the same shape the C3 CitationAudit dataclass enforces at test time.

5. **Surface the curator handoff explicitly**: every `[NEEDS X]` marker names (a) the specific document/source to consult, (b) the location/URL of that source, (c) the minimum evidence that would resolve the marker.

6. **User-supplied citations get the same verification.** A PMID / PDB / accession the *user* hands you is NOT trusted on arrival — verify it exactly as one you generated. Entire operator-supplied briefs have been fabricated end-to-end (every PMID resolving to an unrelated paper; PDB IDs naming the wrong protein family), caught only by independent WebFetch. *"The human gave me this ID"* is not verification.

## Mechanical witness — the PMID citation guard hook

`~/.claude/hooks/pmid_citation_guard.sh` (PostToolUse on Edit/Write of `*.md|*.tex|*.yaml`) is the **mechanical complement** to this skill. The skill is model-judgment (when/how to handoff in prose); the hook is mechanical enforcement (PMIDs cannot escape into disk un-witnessed).

**The hook implements the "stop parsing — citation identity is STRUCTURED DATA" lesson** from binder-design (`src/design-cli/citation_table.py`). Any PMID written to disk must have a row in the structured manifest `~/.claude/state/citations.csv` (DataFrame columns: `pmid, first_author, year, journal, fixture, used_in, status`) AND a matching cache record at `~/.claude/cache/pubmed/<PMID>.json`. The hook joins claim ⋈ cache on pmid and fails loud on mismatch / missing row / missing cache.

**When the hook surfaces a violation, do NOT silently delete the PMID** — that just hides the gap. Choose one:
- (a) Verify and add a row to the manifest (status=live) — earns the citation
- (b) Demote: status=demoted (citation withdrawn, prose marker explains why)
- (c) Operator handoff: status=pending_cache + a `[NEEDS X — check Y at Z]` marker per this skill's discipline

The two layers compose: skill catches at generation-time (model judgment), hook catches at write-time (mechanical). Both load-bearing for the no-fabricated-citations contract.

## Lessons baked in (origin scars from binder-design — the discipline generalizes)

- HRAS task brief: 6/7 PMIDs were wrong (resolved to unrelated papers). The agent that audited caught and demoted; the fixture now has 1 verified good_patch (PMID:9219684 Scheffzek 1997) + 4 demoted candidates with actionable handoffs.
- CXCR4 task brief: PDB 6WHA was claimed as CXCR4-Gαi; RCSB resolved it to HTR2A bound to 25-CN-NBOH (a serotonin receptor). The agent replaced with verified 8K3Z + 8U4O.
- Memory note `shp2-no-blind-autotile.md`: listed P29350 as SHP-2; P29350 is actually PTPN6/SHP-1 (sister enzyme). Caught + fixed.
- HRAS doc: my task brief misattributed PDB 5P21 to "Tong 1989"; primary publication is Pai et al. 1990 EMBO J 9:2351 (PMID:2196171). Caught + fixed.
- Counterpanel: A1 agent shipped 16/20 panel entries with synthetic placeholder sequences marked `[NEEDS CITATION]` because it lacked HTTPS. I hydrated all 20 from UniProt REST live. Live verification before assertion.
- Addgene populator: Addgene's `/sequences/<id>/` URL returns HTML (not GenBank); the bogus HTML downloads were deleted (not silently kept). Failure to verify caught the issue.
- Bench SOP v2: I asserted Lipofectamine 3000 / Q5 / Gibson parameters without sources; the SOP-grounding audit (in progress) replaces each numeric step with either a verified `[REF-KEY]` or an explicit `[NEEDS PROTOCOL SOURCE]` handoff.

The discipline generalises across:
- Biological claims (PMIDs, PDB IDs, UniProt accessions, residue ranges, drug doses)
- Procedural claims (vendor protocol parameters, reagent recipes, cell-culture conditions)
- Software claims (config keys, API contracts, version numbers, file paths, dependencies)
- Procurement claims (vendor catalog IDs, prices, lead times, lot numbers)

The same pattern applies to ALL of these. No exceptions.

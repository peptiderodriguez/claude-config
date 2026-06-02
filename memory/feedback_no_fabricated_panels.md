---
name: feedback-no-fabricated-panels
description: "When citing a gene/protein panel as \"from paper X\", grep the actual paper text first — never compose from background biology under a paper's banner"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a5e7d312-de62-4697-a680-4de8f458852a
---

**Rule:** Reference panels (gene lists, protein sets, biomarker tiers attributed to a publication) must be PDF-grep-verified before being cited as "from paper X". Don't compose panels from related literature and claim them as one paper's.

**Why:** Verbatim from `ehr_proteomics_analysis/.claude/commands/analyze.md`: *"We've burned this lab once already with a fabricated 27-protein 'Thienel panel' that had 7+ proteins not in the paper. If the user shares a PDF, extract its text and grep before claiming any gene is 'from the paper'."*

This bit them hard enough that PDF text extraction is now wired into Phase 0 of the analyze command — when the user shares a paper, the agent extracts text via `fitz`, saves it alongside the dataset, and greps before any panel claim.

**How to apply:**
- If asked to assemble a panel/list from literature, request the source paper(s) first.
- Extract text (`fitz` for PDFs) into a workdir, then `grep` each candidate gene/protein against the actual text.
- Tier-annotate every entry with its paper role: `paper-verified`, `background biology / not in paper`, etc.
- Surface mismatches *before* writing the panel — don't ship a panel containing unverified entries.
- This applies across projects, not just `ehr_proteomics_analysis` — anywhere literature-grounded panels are needed (minibinder hit interpretation, rlink2026 biomarker selection, grant-prep panels).

Related: [[feedback-critique-loop]]

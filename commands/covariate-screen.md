---
name: covariate-screen
description: Cross-sectional clinical-covariate screen — given a feature × sample matrix (proteome / transcriptome / count matrix / any DataFrame) and a samplemap of arbitrary covariates, surface which covariates move the data and therefore must be adjusted for (or pre-corrected) in downstream differential analysis. Outputs a ranked covariate × PC association table, a confounding-with-test-variable sanity check, an optional Geyer plasma-QC scoring pass for proteomics, and a cross-sectional clinical-association screen ruled by the "single-feature nominal-p is not actionable" guard.
trigger: Auto-fire when the user says any of: "correlate X to clinical covariates", "what covariates should I adjust for", "is plate a confound", "covariate × PC screen", "Geyer panel", "Geyer scoring", "cross-sectional clinical-association screen", "is this confounded with [variable]", "should I correct for [plate / batch / injection_order / MS_date]", or any variant of "run a covariate sweep before DE". Also fire proactively when the user is about to launch a differential-expression / linear-model run on a multi-covariate samplemap and hasn't done a confound audit.
skip: Single-covariate targeted tests where the answer is "just test X vs Y"; pure-bioinformatics questions with no samplemap; already invoked this turn; cohort is n < 20 (the screen is statistically meaningless at small n — recommend the user collect descriptive plots instead).
---

# Covariate-screen skill

The single rule: **before you run differential analysis on a cohort with a non-trivial samplemap, you screen every covariate for proteome-wide signal and audit which ones confound the test variable.** Skipping this is how plate effects get reported as biology.

## Sequence

Phases 0–7. Phase 1.5 (Geyer) only fires when the matrix is plasma/CSF proteomics; Phase 5 only fires when a test variable was named in Phase 0.

## Phase 0 — Setup

**AskUserQuestion (batched, single call):**
- *"Path to the feature × sample matrix"* — accepts: parquet (DIA-NN report.parquet auto-detected; pivots `Run × Protein.Group / Gene / feature_id`), wide TSV (rows = features, columns = samples), long TSV (3 cols: sample, feature_id, value — auto-pivoted), count-matrix `.mtx` + `barcodes` + `features` (single-cell convention), or a pickled pandas DataFrame.
- *"Path to samplemap TSV"* — column 1 `sample` matches matrix columns; remaining columns are arbitrary covariates.
- *"Output dir"* — default `<matrix-dir>/covariate_screen/`.
- *"Which samplemap column is your test variable (will be excluded from the recommendation)?"* — `["None — survey only"]` + Other for the column name.
- *"Matrix type?"* — `["plasma / serum proteomics", "tissue / PBMC proteomics", "transcriptomics", "single-cell counts", "other (no QC panel)"]`. Determines whether Phase 1.5 runs.

## Phase 1 — Build the feature × sample matrix

Pluggable loader. For each input type, the contract is the same: produce a `mat` DataFrame with `feature_id` index and `sample` columns, in log2 space, NaN for missing.

```python
def load_matrix(path, kind):
    if kind == "diann_parquet":
        df = pd.read_parquet(path, columns=["Run", "Protein.Group", "Precursor.Quantity"])
        m = (df.groupby(["Run","Protein.Group"])["Precursor.Quantity"].sum()
               .unstack("Run").replace(0, np.nan))
        return np.log2(m).rename_axis("feature_id")
    if kind == "wide_tsv":  return np.log2(pd.read_csv(path, sep="\t", index_col=0).replace(0, np.nan)).rename_axis("feature_id")
    if kind == "long_tsv":
        df = pd.read_csv(path, sep="\t")
        f, s, v = df.columns[:3]
        return np.log2(df.pivot(index=f, columns=s, values=v).replace(0, np.nan)).rename_axis("feature_id")
    if kind == "counts_mtx": ...   # scipy.io.mmread + log1p
    if kind == "dataframe":  return path  # already a DataFrame
```

**Filter to features with ≥70% completeness across samples.** Drop contaminant rows (proteomics: any `feature_id` starting with `CON__`; the cRAP keratin/trypsin/LysC/serum prefixes routinely dominate weak proteomes). Fill remaining NaN with per-feature median **(PCA-only imputation — the downstream DE itself never imputes).** Standardize per feature (z-score across samples) before PCA.

## Phase 1.5 — Geyer plasma-QC scoring (proteomics, plasma/CSF only)

Skip unless `kind ∈ {plasma proteomics, csf proteomics}`. Without it, hemolysis / platelet-activation / ex-vivo-coagulation artifacts ride into the test variable and look like biology. Most insidiously, the **erythrocyte panel overlaps the sex hemoglobin signal**, so a real sex effect can be amplified or faked by hemolysis variance.

Use the canonical implementation when available (`from clinical-omics.contamination import score_contamination, flag_contaminated_samples; from clinical-omics.contamination_panels import GEYER_2019_PANELS`) — it ships the paper-verified 37 erythrocyte / 30 platelet / 32 coagulation genes with **directional** signs (FGA/FGB/F2/SERPINC1 *fall* with activation while PPBP/PF4/CLU/KNG1 *rise* — an unsigned mean would silently cancel the signal). When the package isn't on path, vendor `GEYER_2019_PANELS` inline (it's dataset-independent) and score directionally:

```python
# per panel: z-score of per-sample mean of (intensity * direction_sign)
for panel, spec in GEYER_2019_PANELS.items():
    present = [g for g in spec["geyer_2019"] if g in gmat.index]
    signs = np.array([spec["direction"][g] for g in present]).reshape(-1,1)
    qc[f"{panel}_z"] = scipy.stats.zscore((gmat.loc[present].values * signs).mean(axis=0))
qc["flag_severe"]  = (qc.filter(like="_z") > 3).any(axis=1)
qc["flag_suspect"] = (qc.filter(like="_z") > 2).any(axis=1)
```

**Default behaviour: DROP samples with any panel z > 3** from `mat`, re-run downstream phases on the cleaned subset. Surface what was dropped + per-panel z so the user can reverse (e.g., true RBC-disease cohort where high HBA1/HBB is biology). **Suspect (z > 2): don't auto-drop**, add per-panel z as a covariate in Phase 5/6 designs. **Special check:** if Phase 6 finds HBA1/HBB associating with sex, the severe-drop should already have neutralized it; if a strong HBA/HBB-sex association *still* survives the drop, it's real biology — if it disappears, the original "sex hit" was hemolysis tracking the sampling cadence.

For non-plasma matrices (serum has different coagulation activation; PBMC/tissue isn't plasma), skip the phase.

## Phase 2 — PCA

Top 10 PCs via `sklearn.decomposition.PCA(n_components=10)`. Report per-PC variance explained (PC1 typically 20–40% on plasma DIA after standardization).

## Phase 3 — Covariate vs PCs + per-feature univariate

Auto-classify samplemap columns. **Numeric** if `pd.to_numeric(.., errors='coerce')` succeeds for ≥80% of values. **Categorical** otherwise (2–10 levels fine; skip if >50 levels — it's an ID column like `sample`, `subject_id`, `kit_id`).

For each (covariate, PC): Pearson R² for numeric, η² from one-way ANOVA for categorical. For each covariate, count **per-feature univariate associations at p<0.001** (catches covariates whose effect doesn't load onto the top 10 PCs).

## Phase 4 — Recommend (with two sanity checks)

**Sample-size guard.** If `n_samples < 40`, the BH-q threshold is unreliable (BH has low power below ~40 and the per-feature p-distribution gets lumpy); fall back to the `max_signal ≥ 0.05` PC criterion only and emit a warning in `RECOMMENDATION.md` that the per-feature arm is suppressed. If `n_samples < 20` the skip rule in the frontmatter already refuses the screen entirely.

Rank covariates by `max(R² or η²) across top PCs`. Flag for adjustment when EITHER `max_signal ≥ 0.05` on any top PC OR `n_features_BH_q<.05 ≥ K`, where `K = max(5, 0.01 × n_total_features)` (a small absolute floor plus a 1%-of-features ceiling so the rule scales with panel size). **Use BH-FDR per covariate** on the per-feature univariate p-values from Phase 3 — raw `p<.001` counts are NOT safe under typical omics feature-feature correlation (ρ≈0.3 yields effective n_independent ~500–1000, so the null tail produces 30–50 nominal hits with no real signal — flags noise as confounds on every n≥30 cohort). **Exclude the test variable** the user identified in Phase 0.

**Adjust explicitly when they survive:**
- **Technical confounders that must always be in the model when they show signal** — plate / batch / injection_order / MS_date / instrument. Not biology; will silently inflate or deflate effects.
- **Biological covariates not auto-controlled by the design** — diagnosis subtype, BMI, medication class, treatment duration.

**Don't double-correct paired designs** (cross-references the global CLAUDE.md rule). Paired designs — `subject_id` present, each subject contributes both arms — auto-control for any covariate constant within a subject (age, sex, genotype, baseline diagnosis). Adding them as fixed effects is redundant and steals degrees of freedom.

**Before recommending a covariate, run TWO sanity checks:**

1. **Confounding-with-test-variable check.** For each technical covariate you're about to recommend, test whether it correlates with the user's test variable (per-condition mean of the covariate; chi-square / one-way ANOVA of covariate vs test). **If correlated, residualizing for that covariate will strip the signal you want to detect.** Example: `injection_n` mean 42 in arm-A vs 33 in arm-B → plate-loading was systematically different between arms; correcting removes real signal. Do NOT correct; flag the confound for interpretation.
2. **Paired-design covariate co-location check.** For paired contrasts, for every flagged technical covariate test whether each subject's two samples share the same level (same plate, same MS_date). Report `n_same / n_total` **per cohort** — sub-cohorts can differ dramatically (one arm randomized across plates while another confined to one plate).

## Phase 5 — (Optional) Corrected paired DE + uncorrected sanity comparison

Skip unless a test variable was named AND at least one technical covariate passed both Phase 4 sanity checks.

Residualize `mat` for the surviving technical covariate(s) only (plate enters as one-hot dummies, drop first level; numerics enter linearly). **Do NOT include any covariate that failed the Phase 4 confounding check.** Then run the paired test per cohort on residuals AND on the uncorrected matrix; both go in the output:

| Pattern | Diagnosis |
|---|---|
| Corrected ≈ uncorrected, both have hits | correction is a wash; signal is robust to plate |
| Corrected has hits, uncorrected doesn't | plate was masking signal — correction worked |
| Uncorrected has hits, corrected doesn't | hits were plate artifacts (or over-correction — re-check Phase 4) |
| Both empty | signal genuinely weak; no correction will resurrect it — caveat the design |

Belt-and-suspenders: re-filter `CON__` in output tables in case anyone fed an unfiltered matrix.

## Phase 6 — Cross-sectional clinical-association screen

The test-variable DE (Phase 5) tests one contrast. Even when null, the same dataset often carries real **cross-sectional** associations — which features track with the *other* clinical variables (continuous severity scores, diagnosis subtypes, age, sex, BMI, medication-class booleans). Run this in addition to Phase 5.

Per clinical variable: (1) collapse to one row per patient (mean log2 across the subject's samples); (2) build the design adaptively — `plate` dummies, per-cohort `injection_n`, `sex_n` and `age` IF populated ≥70%, EXCLUDE any covariate correlated with this clinical variable (re-apply Phase 4 confounding check per analysis — `interview_year` shouldn't be a covariate for `age_at_draw`); (3) per-feature regression — `statsmodels.OLS(y ~ test + covariates)` for continuous, residualize then one-way ANOVA for categorical; BH per analysis; (4) **biology coherence check** — are the top nominal hits a *coherent family* (multiple serpins, multiple complement, multiple HLA, multiple hemoglobins) or scattered noise?

**Single-feature nominal-p hits are not actionable.** Don't claim a hit unless it survives BH at q<0.05 OR sits inside a **pre-specified** pathway / gene-set tested by a formal enrichment statistic (CAMERA, fgsea, hypergeometric, ROAST) with multiple-testing correction across the pathway list. The pathway must be named *before* looking at the per-feature ranking — *"I noticed multiple serpins in the top hits"* is post-hoc set definition (GSEA-without-the-test) and is NOT actionable. Established biology (hemoglobin / sex; ApoH+cystatin C+complement / age) should reproduce as a positive control via the pre-specified arm.

## Phase 7 — Output

- `covariate_pc_associations.tsv` — covariate × PC matrix sorted by max signal, with `n_features_p<.001`
- `pc_explained_variance.tsv`
- `pcs_with_metadata.tsv` — per-sample PC scores joined with samplemap
- `geyer_qc.tsv` (when Phase 1.5 fired)
- `paired_de/<cohort>__{corrected,uncorrected}.tsv` (when Phase 5 fired)
- `clinical_assoc/<cohort>__<var>.tsv` per (cohort × clinical variable)
- `RECOMMENDATION.md` — threshold-passing covariates + paired-design caveats + flagged confounds

## Standing rules

- **No imputation in the DE.** Median-fill in Phase 1 is for PCA only. The recommendation never suggests imputing.
- **Run locally** for typical scale (few hundred features × few hundred samples — seconds). Escalate to Slurm only if parquet >5 GB or n_samples >2000.
- **Categorical >50 levels → skip** (it's an ID column).
- **Standardize before PCA** so high-abundance features (albumin, Ig, ribosomal mRNAs) don't dominate PC1.
- **Use AskUserQuestion** for every prompt — never inline prose.
- **Don't double-correct paired designs** — covariates constant within subject are already absorbed (see global CLAUDE.md "Don't double-correct" rule).

## Related

- `~/.claude/commands/anti-fabrication.md` — applies to any cited panel composition (Geyer 2019 panel members must trace to Table EV2)
- Global CLAUDE.md "Don't double-correct paired designs" rule — Phase 4 cross-references it
- Project-local instance: `/Volumes/pool-mann-<operator>/code_bin/clinical-omics/.claude/commands/clinical_eda.md` (DIA-NN-specific source this generalises)

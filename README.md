# Preventive Medicine Analysis Demo

[![R workflow CI](https://github.com/peixibao/preventive-medicine-analysis-demo/actions/workflows/r-check.yml/badge.svg)](https://github.com/peixibao/preventive-medicine-analysis-demo/actions/workflows/r-check.yml)

**A reproducible R demonstration of preventive-health research design, joint behavioral exposure analysis, and cardiometabolic risk-marker assessment using entirely synthetic data.**

This project simulates a cross-sectional sample of adults and links sedentary behavior to a constructed composite of adverse cardiometabolic markers. It shows how to translate a preventive-health question into explicit endpoint definitions, descriptive summaries, multivariable models, standardized estimates, sensitivity analyses, and reproducible outputs. It is a **statistical programming and methods demonstration**, not a completed study of real participants.

## At a glance

- **Study design:** synthetic cross-sectional analysis; 800 simulated adults, 21 variables; reproducible generator with seed 2026.
- **Exposures:** daily sitting duration and frequency of interruptions to sitting.
- **Primary outcome:** at least two of four simulated adverse markers: elevated glycemia, elevated systolic blood pressure, high triglycerides, and low HDL cholesterol. **This is not a diagnosis of metabolic syndrome.**
- **Analytical methods:** robust-variance modified Poisson regression for prevalence ratios, four-category joint exposure analysis, marginal standardization, exploratory multiplicative interaction, secondary biomarker models with BH-FDR adjustment, and sensitivity analyses.
- **Deliverables:** 12 CSV result tables, four figures in both PNG and PDF, a data dictionary, an analysis plan, session information, and CI-based execution checks.

## Research question and design

**Illustrative question:** How are sitting time and sitting-break frequency, separately and jointly, associated with the prevalence of multiple adverse cardiometabolic markers?

The synthetic data generator deliberately introduces correlated demographic, lifestyle, and biomarker features. Some exposure–outcome relationships are built into the simulation. Consequently, the numerical findings demonstrate analysis mechanics and **must not be interpreted as population evidence or clinically estimated effects**.

For the joint analysis, four groups are defined using **illustrative, nonvalidated** thresholds: sitting time ≥8 hours/day and sitting interruptions <3 per hour, with *lower sitting + frequent breaks* as the reference. Continuous exposures remain continuous in the primary regression models.

## Analytical workflow

1. **Generate and validate synthetic data** — correlated lifestyle/metabolic variables, four binary risk markers, a composite outcome, modest missingness in selected covariates, and a machine-readable data dictionary.
2. **Describe the cohort** — overall and outcome-stratified Table 1, individual marker prevalence, marker counts, and per-variable missingness.
3. **Estimate prevalence ratios** — modified Poisson generalized linear models with HC0 sandwich standard errors. Models progress from both exposures without additional covariates (M0) to age/sex (M1), lifestyle covariates (M2), and additional BMI adjustment (M3).
4. **Evaluate joint exposure patterns** — four-group descriptive prevalence, adjusted prevalence ratios, covariate-standardized model-based prevalences, and exploratory multiplicative interaction.
5. **Explore continuous biomarkers** — adjusted linear regressions for fasting glucose, triglycerides, HDL cholesterol, and systolic blood pressure; BH false-discovery-rate adjustment across eight exposure–biomarker comparisons.
6. **Assess sensitivity** — alternative composite thresholds (≥1 and ≥3 markers), nonsmoker-only analyses, and complete-case sample coverage.
7. **Generate reproducible results** — tabular CSV outputs, four publication-style figures (PNG and PDF), and R session information.

BMI may be on the pathway between behaviors and cardiometabolic markers, so M3 is explicitly **exploratory** rather than automatically the preferred causal model. All regression comparisons are associational.

## Illustrative outputs

In the **generated synthetic sample**, 148/800 (18.5%) meet the constructed primary outcome (≥2 adverse markers). The descriptive joint-exposure prevalence ranges from **5.6%** in the lower-sitting/frequent-breaks group to **32.8%** in the higher-sitting/infrequent-breaks group. These differences are features of the simulated data and its assumptions; they do not establish real-world associations.

### Joint exposure: descriptive prevalence

[![Synthetic prevalence across joint sedentary-behavior groups](output/figures/fig1_joint_prevalence.png)](output/figures/fig1_joint_prevalence.pdf)

### Adjusted joint exposure: prevalence ratios

[![Adjusted prevalence ratios for joint exposure categories](output/figures/fig2_adjusted_joint_PR.png)](output/figures/fig2_adjusted_joint_PR.pdf)

Further figures: [adjusted biomarker coefficients](output/figures/fig3_biomarker_coefficients.png) · [risk-marker count distribution](output/figures/fig4_marker_count.png).

Selected machine-readable results:
- [Baseline characteristics](output/tables/table1_baseline.csv)
- [Modified Poisson models (M0–M3)](output/tables/modified_poisson_models.csv)
- [Joint exposure estimates](output/tables/joint_exposure_results.csv)
- [Interaction model](output/tables/joint_interaction_test.csv)
- [Secondary biomarker regression and BH-FDR](output/tables/secondary_biomarker_models.csv)
- [Sensitivity analyses](output/tables/sensitivity_outcome_thresholds.csv)
- [Model diagnostics](output/tables/model_diagnostics.csv)

## Reproduce locally

**Requirements:** R (4.1+ recommended); RStudio is optional. Install dependencies once:

```r
install.packages(c("MASS", "dplyr", "readr", "tibble", "sandwich", "ggplot2"))
```

Clone or download this repository. From R or RStudio, run:

```r
source("run_all.R")
```

`run_all.R` locates the project root, checks package availability, executes all numbered scripts in order, and writes data to `data/` and results to `output/`. The generator uses a fixed random seed; the public inputs and generated outputs contain **no real patient, participant, institutional, or unpublished research data**.

An automated [GitHub Actions workflow](.github/workflows/r-check.yml) also runs on pushes and pull requests, installing R dependencies, sourcing the analysis pipeline, and checking that selected deliverables exist and the generated dataset has 800 rows, 21 columns, and unique IDs. Passing CI confirms those execution checks, **not scientific validity**.

## Repository map

```text
README.md                          Project guide
ANALYSIS_PLAN.md                   Definitions, modeling choices, limitations
run_all.R                          Full pipeline entry point
scripts/
  00_check_packages.R              Dependency validation
  00_analysis_helpers.R            Shared model and I/O utilities
  01_generate_synthetic_data.R     Reproducible synthetic data + dictionary
  02_descriptive_analysis.R        Table 1, prevalence, missingness
  03_regression_models.R           Modified Poisson and biomarker regressions
  04_joint_exposure_analysis.R     Joint groups and standardization
  05_sensitivity_analysis.R        Thresholds, restriction, sample coverage
  06_figures.R                     Four figures, each PNG and PDF
data/                               Generated CSVs and metadata
output/tables/                      Generated tables
output/figures/                     Generated figures
output/session_info.txt             Recorded R environment
.github/workflows/r-check.yml       Continuous integration checks
```

## Interpretation and limitations

- **Simulation only.** The generator imposes some associations, and every estimate, interval, and p-value is conditional on artificial modeling choices. No results are generalizable to patients or populations.
- **Composite endpoints.** The four-marker outcome is an illustrative construct, **not clinical metabolic syndrome**. Behavior cutoffs and some marker definitions are chosen for demonstration.
- **Cross-sectional design.** The results cannot establish temporality or causality. Residual confounding and the placement of BMI in the adjustment set matter.
- **Missingness.** M2/M3 are complete-case analyses (717/800 observations in the tracked run); estimates can change with missing-data assumptions.
- **Modified Poisson diagnostics.** Fitted means exceed 1 for some individuals in adjusted models (including 16 in M3 in the tracked run). Those fitted means must **not** be interpreted as valid individual probabilities. See [diagnostics](output/tables/model_diagnostics.csv) and the [analysis plan](ANALYSIS_PLAN.md).
- **Exploration and multiple comparisons.** Joint interaction and secondary biomarker analyses are exploratory; FDR adjustment is applied to the eight secondary exposure–biomarker tests, not to every analysis in the repository.

## How this complements the other R demonstrations

- [**Epidemiology Analysis Demo**](https://github.com/peixibao/epidemiology-analysis-demo): general epidemiologic regression, nonlinear associations (splines), effect modification, and subgroup analyses.
- [**Survey & Psychometrics Analysis Demo**](https://github.com/peixibao/survey-psychometrics-analysis-demo): questionnaire response-quality checks, factorability, exploratory factor analysis, reliability, item co-occurrence, and clustering.
- **This repository:** preventive-health endpoint construction, joint sedentary-behavior exposures, cardiometabolic biomarker interpretation, standardized prevalence estimates, and an automated end-to-end workflow.

All three repositories are **synthetic-data programming demonstrations**. They are separate from empirical research projects and should be described accordingly in an academic CV.

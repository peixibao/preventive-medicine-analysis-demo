# Preventive Medicine Analysis Demo

Reproducible analysis of **entirely synthetic** clinical and behavioral health data in R.

This project illustrates how modifiable lifestyle exposures, cardiometabolic biomarkers, and clinically interpretable *risk markers* can be integrated into a preventive-medicine workflow. The simulated data have no connection to patient records or unpublished research data. Parameter values and thresholds were selected for illustration; none of the findings are real-world clinical estimates.

## Research question

How are daily sitting time and the frequency of sitting interruptions jointly associated with the prevalence of multiple adverse cardiometabolic markers in a simulated cross-sectional sample of adults?

### Outcome and exposures

- **Primary binary outcome:** two or more of four simulated adverse markers: elevated glycemia, elevated systolic blood pressure, high triglycerides, or low HDL. This composite is *not* a clinical diagnosis of metabolic syndrome.
- **Continuous exposures:** sitting hours per day and interruptions per sitting hour.
- **Joint exposure:** sitting time `>=8` hours/day versus lower; break frequency `<3` per hour versus more frequent, resulting in four categories. These are illustrative thresholds, not evidence-based clinical cutoffs.
- **Secondary biomarker outcomes:** fasting glucose, triglycerides, HDL cholesterol, systolic blood pressure.

## Methods

The generator creates 800 participants with correlated latent lifestyle/metabolic propensities and correlated biomarker residuals, then introduces modest covariate missingness. Analyses include overall/outcome-stratified descriptive statistics, missing-data profiles, modified Poisson prevalence-ratio models with robust (HC0) variance, joint-exposure contrasts, standardized model-based prevalences, an exploratory multiplicative interaction, secondary multivariable linear regressions with BH FDR across eight exposure–biomarker tests, and sensitivity analyses.

Covariate sets are progressively adjusted: unadjusted exposures (M0); age/sex (M1); additional smoking, physical activity, sleep and diet (M2); BMI added (M3, exploratory because adiposity may mediate associations). These analyses are **associational, not causal**. The generating model intentionally embeds some of the associations that the analysis later estimates.

## Reproduce the full workflow

Use R (version 4.1+ recommended) and install missing packages if needed:

```r
install.packages(c("MASS", "dplyr", "readr", "tibble", "sandwich", "ggplot2"))
```

Open the repository as an RStudio Project, then run:

```r
source("run_all.R")
```

`run_all.R` checks dependencies and executes the entire pipeline in order. It locates its own project directory, so sourcing by absolute path is also supported.

## Repository structure

```text
run_all.R
scripts/
  00_check_packages.R
  00_analysis_helpers.R
  01_generate_synthetic_data.R
  02_descriptive_analysis.R
  03_regression_models.R
  04_joint_exposure_analysis.R
  05_sensitivity_analysis.R
  06_figures.R
data/
  README.md
  synthetic_preventive_health.csv       # generated
  data_dictionary.csv                   # generated
output/
  README.md
  tables/                               # generated CSV tables
  figures/                              # generated PNG and PDF figures
  session_info.txt                      # generated
ANALYSIS_PLAN.md
```

The analysis plan documents simulated definitions, analysis decisions and limitations. The entry point reconstructs the generated dataset, tables and figures from the seed-controlled generator.

## Joint Exposure Analysis

The joint-exposure analysis compares four combinations of sedentary time and interruption patterns and reports descriptive prevalence, adjusted prevalence ratios and standardized model-based prevalence. The interaction test is exploratory and is evaluated on the multiplicative prevalence-ratio scale.

## Interpretation and limitations

This repository is a demonstration of reproducible analysis mechanics and transparent statistical implementation. All observations were generated artificially; the prevalence estimates, p-values and confidence intervals are specific to the simulation and carry **no evidentiary weight about real patients or populations**. Missingness, confounding and associations reflect modeling choices, not validated epidemiologic relationships. See `ANALYSIS_PLAN.md` for full details.

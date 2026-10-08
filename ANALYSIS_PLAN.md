# Preventive Medicine Analysis Demo — Analysis Plan

## Scope

An entirely **synthetic, cross-sectional** demonstration of a reproducible preventive-health workflow. Its data-generating parameters were constructed for a methods exercise. The data do not represent a real population, do not estimate real clinical effects, and contain no participant/patient records. The generating mechanism deliberately embeds exposure–biomarker associations; downstream estimates therefore reflect the simulation design.

## Inputs and endpoints

The existing `scripts/01_generate_synthetic_data.R` is the generator for 800 synthetic adults and 21 fields. The primary illustrative outcome is `multiple_risk_markers`, indicating two or more of four constructed markers: elevated glycemia, elevated systolic blood pressure, high triglycerides, and low HDL. It is **not a diagnosis of metabolic syndrome**, and no metabolic-syndrome diagnostic criteria are asserted.

The continuous exposures of interest are self-reported sitting hours per day and breaks per sitting hour. For the joint-exposure demonstration only, the **illustrative, preselected** cutoffs are sitting `>=8` hours/day and breaks `<3` per hour, forming four groups. These cutoffs are not validated clinical thresholds. The reference is lower sitting plus frequent breaks.

## Analyses

- `02_descriptive_analysis.R`: overall and outcome-stratified Table 1, risk-marker distribution, marker prevalence, per-variable missingness. Descriptive group differences carry no significance testing.
- `03_regression_models.R`: modified Poisson GLMs with HC0 sandwich variance estimate cross-sectional **prevalence ratios** for sitting hours and break frequency. M0 includes the two exposures; M1 adds age/sex; M2 adds smoking, activity, sleep, diet; M3 additionally adjusts for BMI. BMI adjustment is exploratory because BMI can lie on an exposure–outcome pathway. Secondary linear associations with fasting glucose, triglycerides, HDL and systolic BP are exploratory; BH FDR is calculated across the 8 exposure–biomarker tests.
- `04_joint_exposure_analysis.R`: descriptive prevalence; adjusted group PRs; standardized model-based prevalence estimates averaged over the complete-case covariate distribution; exploratory multiplicative interaction test.
- `05_sensitivity_analysis.R`: thresholds of at least 1 and at least 3 adverse markers, nonsmoker-only analysis, complete-case coverage comparison. Small event counts make the >=3-marker contrast potentially unstable.
- `06_figures.R`: descriptive prevalence, group PR forest plot, biomarker coefficient plot, marker-count distribution; both PNG and PDF.

Models are descriptive associations in simulated cross-sectional data. Causal language is not appropriate. Robust variance for binary outcomes under a Poisson mean model is used for PR inference; predicted values over one, when present, are flagged in diagnostics. All missing-covariate regressions use complete-case analysis; synthetic missingness was intentionally introduced by the generator.

## Reproducibility

Install missing packages once: `install.packages(c("MASS", "dplyr", "readr", "tibble", "sandwich", "ggplot2"))`.

Open the project in RStudio, then `source("run_all.R")`. The script sets the working directory to its own location for the duration of the run, checks dependencies, executes all scripts, and saves data, tables, figures and `output/session_info.txt`. It aborts on an error instead of printing a false success message.

**Keep your existing `scripts/01_generate_synthetic_data.R`.** The supplement intentionally does not overwrite it.

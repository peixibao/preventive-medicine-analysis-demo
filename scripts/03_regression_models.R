# Main cross-sectional prevalence models and secondary biomarker regressions.
dat <- load_analysis_data()

formulas <- list(
  M0_unadjusted = multiple_risk_markers ~ sitting_hours + breaks_per_hour,
  M1_demographics = multiple_risk_markers ~ sitting_hours + breaks_per_hour + age + sex,
  M2_lifestyle = multiple_risk_markers ~ sitting_hours + breaks_per_hour +
    age + sex + current_smoker + mvpa_min_week + sleep_hours + diet_quality_score,
  M3_plus_BMI = multiple_risk_markers ~ sitting_hours + breaks_per_hour +
    age + sex + current_smoker + mvpa_min_week + sleep_hours + diet_quality_score + bmi
)

fits <- lapply(names(formulas), function(nm) {
  fit_modified_poisson(formulas[[nm]], dat, nm)
})
names(fits) <- names(formulas)

poisson_results <- dplyr::bind_rows(lapply(fits, `[[`, "results"))
save_table(poisson_results, "output/tables/modified_poisson_models.csv")

model_diagnostics <- dplyr::bind_rows(lapply(names(fits), function(nm) {
  f <- fits[[nm]]
  tibble::tibble(
    model = nm,
    n = nrow(f$data),
    events = sum(f$data$multiple_risk_markers == 1L),
    max_fitted_prevalence = f$max_fitted,
    n_fitted_over_one = f$n_over_one
  )
}))
save_table(model_diagnostics, "output/tables/model_diagnostics.csv")

# Interpret exponentiated Poisson coefficients as cross-sectional prevalence ratios.
# Biomarkers are exploratory secondary outcomes; classical LM confidence intervals.
biomarkers <- c("fasting_glucose", "triglycerides", "hdl", "sbp")
biomarker_models <- dplyr::bind_rows(lapply(biomarkers, function(outcome) {
  f <- stats::reformulate(
    c("sitting_hours", "breaks_per_hour", "age", "sex", "current_smoker",
      "mvpa_min_week", "sleep_hours", "diet_quality_score", "bmi"),
    response = outcome
  )
  fit_linear(f, dat, outcome)
})) |>
  dplyr::filter(term %in% c("sitting_hours", "breaks_per_hour")) |>
  dplyr::mutate(p_fdr_bh = stats::p.adjust(p_value, method = "BH"))
save_table(biomarker_models, "output/tables/secondary_biomarker_models.csv")

if (any(model_diagnostics$n_fitted_over_one > 0L)) {
  warning("Some fitted modified-Poisson means exceed 1; inspect model_diagnostics.csv")
}
message("Regression models completed (M0-M3; four exploratory biomarkers).")

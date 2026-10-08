# Outcome-threshold sensitivity and restriction to nonsmokers.
dat <- load_analysis_data()

adjustment <- c(
  "sitting_hours", "breaks_per_hour", "age", "sex", "current_smoker",
  "mvpa_min_week", "sleep_hours", "diet_quality_score", "bmi"
)
thresholds <- c("at_least_1_marker" = 1L, "at_least_3_markers" = 3L)

threshold_results <- dplyr::bind_rows(lapply(names(thresholds), function(label) {
  dat$alternative_outcome <- as.integer(dat$risk_marker_count >= thresholds[[label]])
  f <- stats::reformulate(adjustment, response = "alternative_outcome")
  n_events <- sum(dat$alternative_outcome)
  if (n_events < 20L) {
    warning(label, " has fewer than 20 events; results may be unstable")
  }
  fit_modified_poisson(f, dat, label)$results |>
    dplyr::filter(term %in% c("sitting_hours", "breaks_per_hour"))
}))
save_table(threshold_results, "output/tables/sensitivity_outcome_thresholds.csv")

nonsmoker_data <- dat[dat$current_smoker == "No", , drop = FALSE]
nonsmoker_formula <- multiple_risk_markers ~ sitting_hours + breaks_per_hour +
  age + sex + mvpa_min_week + sleep_hours + diet_quality_score + bmi
nonsmoker_results <- fit_modified_poisson(
  nonsmoker_formula, nonsmoker_data, "Nonsmokers only"
)$results |>
  dplyr::filter(term %in% c("sitting_hours", "breaks_per_hour"))
save_table(nonsmoker_results, "output/tables/sensitivity_nonsmokers.csv")

main_formula <- stats::reformulate(adjustment, response = "multiple_risk_markers")
complete_flag <- stats::complete.cases(dat[, all.vars(main_formula), drop = FALSE])
sample_coverage <- tibble::tibble(
  analysis_sample = c("Full synthetic sample", "Main-model complete cases", "Excluded by missing covariates"),
  n = c(nrow(dat), sum(complete_flag), sum(!complete_flag)),
  events = c(sum(dat$multiple_risk_markers),
             sum(dat$multiple_risk_markers[complete_flag]),
             sum(dat$multiple_risk_markers[!complete_flag]))
) |>
  dplyr::mutate(event_prevalence = ifelse(n > 0, events / n, NA_real_))
save_table(sample_coverage, "output/tables/sensitivity_sample_coverage.csv")

message("Sensitivity analyses completed (alternative marker thresholds; nonsmokers).")

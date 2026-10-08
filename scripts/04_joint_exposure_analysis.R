# Joint sedentary-time / sitting-break analysis; cutoffs are illustrative.
dat <- load_analysis_data()

joint_levels <- c(
  "Lower sitting + frequent breaks",
  "Lower sitting + infrequent breaks",
  "Higher sitting + frequent breaks",
  "Higher sitting + infrequent breaks"
)

dat <- dat |>
  dplyr::mutate(
    sitting_high = as.integer(sitting_hours >= 8),
    breaks_low = as.integer(breaks_per_hour < 3),
    joint_group = factor(
      dplyr::case_when(
        sitting_high == 0L & breaks_low == 0L ~ joint_levels[1],
        sitting_high == 0L & breaks_low == 1L ~ joint_levels[2],
        sitting_high == 1L & breaks_low == 0L ~ joint_levels[3],
        TRUE ~ joint_levels[4]
      ),
      levels = joint_levels
    )
  )

raw_summary <- dat |>
  dplyr::group_by(joint_group, .drop = FALSE) |>
  dplyr::summarise(
    n = dplyr::n(),
    cases = sum(multiple_risk_markers == 1L),
    raw_prevalence = cases / n,
    .groups = "drop"
  )
if (any(raw_summary$n < 15L)) {
  warning("At least one joint-exposure group contains <15 participants")
}

joint_formula <- multiple_risk_markers ~ joint_group + age + sex +
  current_smoker + mvpa_min_week + sleep_hours + diet_quality_score + bmi
joint_fit <- fit_modified_poisson(joint_formula, dat, "Joint exposure, adjusted")

coef_names <- paste0("joint_group", joint_levels[-1])
coef_rows <- match(coef_names, joint_fit$results$term)
if (anyNA(coef_rows)) stop("One or more joint-group coefficients are unavailable")

reference <- tibble::tibble(PR = 1, CI_low = 1, CI_high = 1, p_value = NA_real_)
adjusted <- dplyr::bind_rows(
  reference,
  joint_fit$results[coef_rows, c("PR", "CI_low", "CI_high", "p_value")]
)

# Marginal predictions averaged over the complete-case covariate distribution.
standardized <- vapply(joint_levels, function(group) {
  newdata <- joint_fit$data
  newdata$joint_group <- factor(rep(group, nrow(newdata)), levels = joint_levels)
  mean(stats::predict(joint_fit$model, newdata = newdata, type = "response"))
}, numeric(1))

joint_results <- dplyr::bind_cols(
  raw_summary,
  adjusted,
  tibble::tibble(
    standardized_prevalence = standardized,
    standardized_difference_pp = 100 * (standardized - standardized[1])
  )
)
save_table(joint_results, "output/tables/joint_exposure_results.csv")

# Multiplicative interaction in prevalence ratios, using robust Wald inference.
interaction_fit <- fit_modified_poisson(
  multiple_risk_markers ~ sitting_high * breaks_low + age + sex +
    current_smoker + mvpa_min_week + sleep_hours + diet_quality_score + bmi,
  dat,
  "Dichotomized interaction"
)
interaction_term <- interaction_fit$results |>
  dplyr::filter(term == "sitting_high:breaks_low") |>
  dplyr::mutate(
    sitting_cutoff_hours = 8,
    breaks_cutoff_per_hour = 3,
    interpretation = "Multiplicative prevalence-ratio interaction; exploratory"
  )
if (nrow(interaction_term) != 1L) stop("Interaction term not estimable")
save_table(interaction_term, "output/tables/joint_interaction_test.csv")

message("Joint exposure analysis completed (8 h/day and 3 breaks/hour cutoffs).")

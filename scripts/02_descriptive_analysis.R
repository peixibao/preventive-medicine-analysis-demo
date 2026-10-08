# Baseline descriptive tables, marker prevalence, and missing-data checks.
dat <- load_analysis_data()
ensure_dir("output/tables")

n_total <- nrow(dat)
n_group <- sum(dat$multiple_risk_markers == 1L)
group_data <- list(
  overall = dat,
  no_multiple_markers = dat[dat$multiple_risk_markers == 0L, , drop = FALSE],
  multiple_markers = dat[dat$multiple_risk_markers == 1L, , drop = FALSE]
)

mean_sd <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) < 2L) return("NA")
  sprintf("%.1f (%.1f)", mean(x), stats::sd(x))
}
median_iqr <- function(x) {
  x <- x[!is.na(x)]
  if (!length(x)) return("NA")
  q <- stats::quantile(x, c(.25, .75), names = FALSE)
  sprintf("%.1f [%.1f, %.1f]", stats::median(x), q[1], q[2])
}
count_pct <- function(x, level) {
  valid <- !is.na(x)
  if (!sum(valid)) return("NA")
  sprintf("%d (%.1f%%)", sum(x[valid] == level),
          100 * mean(x[valid] == level))
}

specs <- list(
  list("age", "Age, years", mean_sd),
  list("sex", "Male, n (%)", function(x) count_pct(x, "Male")),
  list("bmi", "BMI, kg/m2", mean_sd),
  list("current_smoker", "Current smoker, n (%)", function(x) count_pct(x, "Yes")),
  list("sleep_hours", "Sleep, hours/day", mean_sd),
  list("mvpa_min_week", "MVPA, min/week", median_iqr),
  list("sitting_hours", "Sitting time, hours/day", mean_sd),
  list("breaks_per_hour", "Sitting breaks, per hour", mean_sd),
  list("diet_quality_score", "Diet quality (simulated 0-100)", mean_sd),
  list("fasting_glucose", "Fasting glucose, mg/dL", mean_sd),
  list("hba1c", "HbA1c, %", mean_sd),
  list("triglycerides", "Triglycerides, mg/dL", median_iqr),
  list("hdl", "HDL cholesterol, mg/dL", mean_sd),
  list("sbp", "Systolic blood pressure, mmHg", mean_sd)
)

table1 <- dplyr::bind_rows(lapply(specs, function(s) {
  variable <- s[[1]]
  formatter <- s[[3]]
  tibble::tibble(
    characteristic = s[[2]],
    overall = formatter(group_data$overall[[variable]]),
    no_multiple_markers = formatter(group_data$no_multiple_markers[[variable]]),
    multiple_markers = formatter(group_data$multiple_markers[[variable]])
  )
}))
save_table(table1, "output/tables/table1_baseline.csv")

marker_vars <- c("elevated_glycemia", "elevated_sbp",
                 "high_triglycerides", "low_hdl", "multiple_risk_markers")
marker_labels <- c("Elevated glycemic marker", "Elevated SBP marker",
                   "Elevated triglycerides", "Low HDL", "Two or more markers")
marker_prevalence <- dplyr::bind_rows(lapply(seq_along(marker_vars), function(i) {
  x <- dat[[marker_vars[i]]]
  tibble::tibble(
    marker = marker_labels[i],
    n_available = sum(!is.na(x)),
    n_positive = sum(x == 1, na.rm = TRUE),
    percent = round(100 * mean(x == 1, na.rm = TRUE), 1)
  )
}))
save_table(marker_prevalence, "output/tables/marker_prevalence.csv")

risk_count <- tibble::tibble(
  risk_marker_count = 0:4,
  n = vapply(0:4, function(k) sum(dat$risk_marker_count == k), integer(1))
) |>
  dplyr::mutate(percent = round(100 * n / n_total, 1))
save_table(risk_count, "output/tables/risk_marker_distribution.csv")

missingness <- tibble::tibble(
  variable = names(dat),
  missing_n = vapply(dat, function(x) sum(is.na(x)), integer(1))
) |>
  dplyr::mutate(missing_percent = round(100 * missing_n / n_total, 2))
save_table(missingness, "output/tables/missingness.csv")

message(sprintf("Descriptives completed: N=%d; multiple markers=%d (%.1f%%).",
                n_total, n_group, 100 * n_group / n_total))

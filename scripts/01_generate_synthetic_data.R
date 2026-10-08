# ============================================================
# 01_generate_synthetic_data.R
# Synthetic adult preventive-health cohort with associated
# behavioral exposures and cardiometabolic marker profiles.
# No observations are derived from actual patients or cohorts.
# ============================================================

# All coefficients and thresholds are deliberately illustrative;
# observed associations in this synthetic cohort are imposed by
# its data-generating process, not estimated from real populations.
set.seed(2026L)
n <- 800L
clamp <- function(x, lower, upper) pmin(pmax(x, lower), upper)

# Correlated latent determinants of activity, metabolism, and sleep.
latent_cor <- matrix(c(
   1.00, -0.30,  0.20,
  -0.30,  1.00, -0.25,
   0.20, -0.25,  1.00
), nrow = 3L, byrow = TRUE)
stopifnot(min(eigen(latent_cor, symmetric = TRUE, only.values = TRUE)$values) > 0)
latent <- MASS::mvrnorm(n = n, mu = rep(0, 3), Sigma = latent_cor)
colnames(latent) <- c("activity", "metabolic", "sleep")
activity <- latent[, "activity"]
metabolic <- latent[, "metabolic"]
sleep_propensity <- latent[, "sleep"]

# Demographics and anthropometrics.
age <- as.integer(round(18 + 57 * stats::rbeta(n, 2.5, 2.2)))
sex <- sample(c("Female", "Male"), n, replace = TRUE, prob = c(.52, .48))
male <- as.integer(sex == "Male")
bmi <- round(clamp(
  23.5 + .045 * (age - 45) + .50 * male + 1.40 * metabolic -
    .40 * activity + stats::rnorm(n, 0, 2.3),
  16, 40
), 1)

# Modifiable lifestyle exposures (observed, prior to missingness).
sleep_hours <- round(clamp(
  6.9 + .45 * sleep_propensity - .015 * (age - 45) -
    .10 * (bmi - 23.5) + stats::rnorm(n, 0, .55),
  4.5, 9.5
), 1)

inactive_probability <- stats::plogis(
  -2.0 + .018 * (age - 45) + .06 * (bmi - 23.5) - .45 * activity
)
physically_inactive <- stats::rbinom(n, 1L, inactive_probability)
mvpa_min_week <- round(exp(
  log(155) + .35 * activity - .010 * (age - 45) -
    .025 * (bmi - 23.5) + stats::rnorm(n, 0, .48)
))
mvpa_min_week[physically_inactive == 1L] <- 0
mvpa_min_week <- clamp(mvpa_min_week, 0, 700)

sitting_hours <- round(
  3.5 + 8 * stats::plogis(
    .15 - .40 * activity + .015 * (age - 45) +
      .035 * (bmi - 23.5) + stats::rnorm(n, 0, .60)
  ), 1
)
breaks_per_hour <- round(
  .5 + 6 * stats::plogis(
    .30 + .25 * activity - .45 * (sitting_hours - 7) +
      stats::rnorm(n, 0, .70)
  ), 1
)
diet_quality_score <- round(
  100 * stats::plogis(
    .10 + .25 * activity + .20 * sleep_propensity -
      .25 * metabolic + stats::rnorm(n, 0, .80)
  ), 1
)
smoking_probability <- stats::plogis(
  -2.2 + .018 * (age - 45) + .80 * male - .20 * activity
)
current_smoker <- ifelse(stats::rbinom(n, 1L, smoking_probability) == 1L,
                         "Yes", "No")

# Correlated residuals of distinct metabolic biomarkers.
biomarker_cor <- matrix(c(
   1.00,  0.30, -0.20,  0.25,
   0.30,  1.00, -0.25,  0.20,
  -0.20, -0.25,  1.00, -0.15,
   0.25,  0.20, -0.15,  1.00
), nrow = 4L, byrow = TRUE)
stopifnot(min(eigen(biomarker_cor, symmetric = TRUE, only.values = TRUE)$values) > 0)
residual <- MASS::mvrnorm(n, mu = rep(0, 4), Sigma = biomarker_cor)
colnames(residual) <- c("glucose", "tg", "hdl", "sbp")

# Clinical measurements. Units are recorded in the data dictionary.
fasting_glucose <- round(
  91 + .22 * (age - 45) + .65 * (bmi - 23.5) +
    1.20 * (sitting_hours - 7) - .70 * (breaks_per_hour - 3) -
    .008 * (mvpa_min_week - 150) + 2 * metabolic + 6 * residual[, "glucose"],
  1
)
hba1c <- round(
  5.15 + .020 * (fasting_glucose - 90) + .025 * (bmi - 23.5) +
    .060 * metabolic + stats::rnorm(n, 0, .16),
  1
)
triglycerides <- round(exp(
  log(105) + .025 * (bmi - 23.5) + .030 * (sitting_hours - 7) -
    .012 * (breaks_per_hour - 3) - .0008 * (mvpa_min_week - 150) +
    .12 * metabolic + .22 * residual[, "tg"]
), 1)
hdl <- round(
  58 - .60 * (bmi - 23.5) - 6 * male - .50 * (sitting_hours - 7) +
    1.20 * (breaks_per_hour - 3) + .008 * (mvpa_min_week - 150) -
    2 * metabolic + 5 * residual[, "hdl"],
  1
)
sbp <- round(
  116 + .55 * (age - 45) + .60 * (bmi - 23.5) + male +
    .70 * (sitting_hours - 7) - .004 * (mvpa_min_week - 150) +
    1.50 * metabolic + 7 * residual[, "sbp"],
  1
)

# Clinical-style marker definitions used for exploratory demonstration.
# This composite must not be described as a clinical diagnosis.
synthetic_data <- tibble::tibble(
  id = sprintf("P%04d", seq_len(n)),
  age = age, sex = sex, bmi = bmi,
  sleep_hours = sleep_hours, mvpa_min_week = mvpa_min_week,
  sitting_hours = sitting_hours, breaks_per_hour = breaks_per_hour,
  diet_quality_score = diet_quality_score, current_smoker = current_smoker,
  fasting_glucose = fasting_glucose, hba1c = hba1c,
  triglycerides = triglycerides, hdl = hdl, sbp = sbp
) |>
  dplyr::mutate(
    elevated_glycemia = as.integer(fasting_glucose >= 100 | hba1c >= 5.7),
    elevated_sbp = as.integer(sbp >= 130),
    high_triglycerides = as.integer(triglycerides >= 150),
    low_hdl = as.integer(
      (sex == "Female" & hdl < 50) | (sex == "Male" & hdl < 40)
    ),
    risk_marker_count = elevated_glycemia + elevated_sbp +
      high_triglycerides + low_hdl,
    multiple_risk_markers = as.integer(risk_marker_count >= 2)
  )

# Modest informative missingness is confined to lifestyle covariates.
missing_mvpa <- stats::rbinom(n, 1L, stats::plogis(
  -3.4 + .015 * (age - 45) + .25 * (current_smoker == "Yes")
)) == 1L
missing_sleep <- stats::rbinom(n, 1L, stats::plogis(
  -3.6 + .020 * (age - 45) + .20 * metabolic
)) == 1L
missing_diet <- stats::rbinom(n, 1L, stats::plogis(
  -3.3 + .20 * (current_smoker == "Yes") + .15 * metabolic
)) == 1L
synthetic_data$mvpa_min_week[missing_mvpa] <- NA_real_
synthetic_data$sleep_hours[missing_sleep] <- NA_real_
synthetic_data$diet_quality_score[missing_diet] <- NA_real_

# Explicit integrity checks; fail early if the simulated cohort is invalid.
stopifnot(
  nrow(synthetic_data) == n,
  ncol(synthetic_data) == 21L,
  !anyNA(synthetic_data$id),
  !anyDuplicated(synthetic_data$id),
  all(synthetic_data$age >= 18L & synthetic_data$age <= 75L),
  all(synthetic_data$bmi >= 16 & synthetic_data$bmi <= 40),
  all(synthetic_data$sleep_hours >= 4.5 & synthetic_data$sleep_hours <= 9.5,
      na.rm = TRUE),
  all(synthetic_data$mvpa_min_week >= 0 & synthetic_data$mvpa_min_week <= 700,
      na.rm = TRUE),
  all(synthetic_data$risk_marker_count %in% 0:4),
  all(synthetic_data$multiple_risk_markers ==
        as.integer(synthetic_data$risk_marker_count >= 2)),
  all(synthetic_data$fasting_glucose > 0),
  all(synthetic_data$hba1c > 0),
  all(synthetic_data$triglycerides > 0),
  all(synthetic_data$hdl > 0),
  all(synthetic_data$sbp > 0)
)

# Machine-readable variable metadata; keeps definitions beside the data.
data_dictionary <- tibble::tribble(
  ~variable, ~description, ~unit,
  "id", "Synthetic participant identifier", NA_character_,
  "age", "Age", "years",
  "sex", "Sex", NA_character_,
  "bmi", "Body mass index", "kg/m^2",
  "sleep_hours", "Mean sleep duration", "hours/day",
  "mvpa_min_week", "Moderate-to-vigorous physical activity", "minutes/week",
  "sitting_hours", "Mean sitting duration", "hours/day",
  "breaks_per_hour", "Sitting interruptions", "breaks/hour",
  "diet_quality_score", "Simulated diet-quality indicator", "0-100",
  "current_smoker", "Current smoking status", "Yes/No",
  "fasting_glucose", "Fasting plasma glucose", "mg/dL",
  "hba1c", "Glycated hemoglobin", "%",
  "triglycerides", "Triglyceride concentration", "mg/dL",
  "hdl", "HDL cholesterol", "mg/dL",
  "sbp", "Systolic blood pressure", "mmHg",
  "elevated_glycemia", "Glycemic marker at/above illustrative threshold", "0/1",
  "elevated_sbp", "Systolic BP marker at/above illustrative threshold", "0/1",
  "high_triglycerides", "Triglyceride marker at/above illustrative threshold", "0/1",
  "low_hdl", "HDL marker below sex-specific illustrative threshold", "0/1",
  "risk_marker_count", "Sum of four binary adverse markers", "0-4",
  "multiple_risk_markers", "Two or more adverse markers", "0/1"
)
stopifnot(identical(data_dictionary$variable, names(synthetic_data)))

if (!dir.exists("data")) dir.create("data", recursive = TRUE)
readr::write_csv(synthetic_data, "data/synthetic_preventive_health.csv", na = "")
readr::write_csv(data_dictionary, "data/data_dictionary.csv", na = "")

message(sprintf(
  "Synthetic cohort generated: N=%d, variables=%d, multiple markers=%.1f%%.",
  nrow(synthetic_data), ncol(synthetic_data),
  100 * mean(synthetic_data$multiple_risk_markers)
))
message("Written: data/synthetic_preventive_health.csv and data/data_dictionary.csv")

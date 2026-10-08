# Shared I/O, input validation and regression utilities.

ensure_dir <- function(path) {
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  invisible(path)
}

save_table <- function(x, filename) {
  ensure_dir(dirname(filename))
  readr::write_csv(x, filename, na = "")
  message("Saved: ", filename)
  invisible(filename)
}

load_analysis_data <- function(path = "data/synthetic_preventive_health.csv") {
  if (!file.exists(path)) stop("Missing data file: ", path, call. = FALSE)
  dat <- readr::read_csv(path, show_col_types = FALSE)
  required <- c(
    "id", "age", "sex", "bmi", "current_smoker", "sleep_hours",
    "mvpa_min_week", "sitting_hours", "breaks_per_hour", "diet_quality_score",
    "fasting_glucose", "hba1c", "triglycerides", "hdl", "sbp",
    "elevated_glycemia", "elevated_sbp", "high_triglycerides", "low_hdl",
    "risk_marker_count", "multiple_risk_markers"
  )
  missing <- setdiff(required, names(dat))
  if (length(missing)) stop("Dataset missing columns: ", paste(missing, collapse = ", "))
  if (anyDuplicated(dat$id)) stop("Duplicate participant identifiers")
  if (!all(dat$multiple_risk_markers %in% c(0L, 1L))) {
    stop("Invalid binary outcome coding")
  }
  dat$sex <- factor(dat$sex, levels = c("Female", "Male"))
  dat$current_smoker <- factor(dat$current_smoker, levels = c("No", "Yes"))
  dat
}

complete_model_data <- function(formula, dat) {
  vars <- all.vars(formula)
  dat[stats::complete.cases(dat[, vars, drop = FALSE]), , drop = FALSE]
}

fit_modified_poisson <- function(formula, dat, model_name) {
  cc <- complete_model_data(formula, dat)
  outcome <- all.vars(formula)[1]
  if (nrow(cc) < 30L || length(unique(cc[[outcome]])) < 2L) {
    stop("Insufficient analyzable data for ", model_name, call. = FALSE)
  }
  fit <- stats::glm(formula, family = stats::poisson(link = "log"), data = cc)
  if (!isTRUE(fit$converged)) stop("Model did not converge: ", model_name)
  beta <- stats::coef(fit)
  V <- sandwich::vcovHC(fit, type = "HC0")
  se <- sqrt(diag(V))
  if (!all(is.finite(beta)) || !all(is.finite(se)) || any(se <= 0)) {
    stop("Non-finite or invalid coefficient/SE in ", model_name)
  }
  z <- beta / se
  out <- tibble::tibble(
    model = model_name,
    term = names(beta),
    PR = unname(exp(beta)),
    CI_low = unname(exp(beta - stats::qnorm(.975) * se)),
    CI_high = unname(exp(beta + stats::qnorm(.975) * se)),
    p_value = unname(2 * stats::pnorm(abs(z), lower.tail = FALSE)),
    n = nrow(cc),
    events = sum(cc[[outcome]] == 1L)
  )
  list(model = fit, data = cc, results = out,
       max_fitted = max(stats::fitted(fit)),
       n_over_one = sum(stats::fitted(fit) > 1))
}

fit_linear <- function(formula, dat, model_name) {
  cc <- complete_model_data(formula, dat)
  fit <- stats::lm(formula, data = cc)
  cf <- summary(fit)$coefficients
  ci <- stats::confint(fit, level = .95)
  tibble::tibble(
    outcome = model_name,
    term = rownames(cf),
    beta = unname(cf[, "Estimate"]),
    CI_low = unname(ci[, 1]),
    CI_high = unname(ci[, 2]),
    p_value = unname(cf[, "Pr(>|t|)"]),
    n = nrow(cc)
  )
}

# ============================================================
# run_all.R
# Rebuild synthetic data, descriptive tables, regression models,
# joint-exposure analyses, sensitivity analyses and figures.
# ============================================================

source_file <- sys.frame(1)$ofile
if (is.null(source_file) || !nzchar(source_file)) {
  stop("Run this entry point with source('run_all.R').", call. = FALSE)
}
project_root <- dirname(normalizePath(source_file, mustWork = TRUE))

run_pipeline <- function(root) {
  prior_wd <- setwd(root)
  on.exit(setwd(prior_wd), add = TRUE)

  dir.create("data", showWarnings = FALSE, recursive = TRUE)
  dir.create("output", showWarnings = FALSE, recursive = TRUE)

  workflow <- c(
    "scripts/00_check_packages.R",
    "scripts/00_analysis_helpers.R",
    "scripts/01_generate_synthetic_data.R",
    "scripts/02_descriptive_analysis.R",
    "scripts/03_regression_models.R",
    "scripts/04_joint_exposure_analysis.R",
    "scripts/05_sensitivity_analysis.R",
    "scripts/06_figures.R"
  )
  absent <- workflow[!file.exists(workflow)]
  if (length(absent)) {
    stop("Missing project scripts: ", paste(absent, collapse = ", "), call. = FALSE)
  }

  for (script in workflow) {
    message("\n--- Running ", script, " ---")
    source(script, local = TRUE, echo = FALSE)
  }

  writeLines(capture.output(sessionInfo()), "output/session_info.txt")
  message("\nComplete preventive-medicine workflow finished successfully.",
          "\nTables: output/tables/",
          "\nFigures: output/figures/",
          "\nSynthetic data: data/")
  invisible(TRUE)
}

run_pipeline(project_root)
rm(run_pipeline, project_root, source_file)

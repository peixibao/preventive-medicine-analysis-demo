# Dependency checks for the preventive-medicine workflow.
required_packages <- c("MASS", "dplyr", "readr", "tibble", "sandwich", "ggplot2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop("Missing R packages: ", paste(missing_packages, collapse = ", "),
       ". Install them before running run_all.R.", call. = FALSE)
}
message("All required packages are available.")

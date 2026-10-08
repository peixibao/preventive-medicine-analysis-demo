# Publication-style figures generated from analysis output tables.
ensure_dir("output/figures")

joint <- readr::read_csv("output/tables/joint_exposure_results.csv", show_col_types = FALSE)
biomarker <- readr::read_csv("output/tables/secondary_biomarker_models.csv", show_col_types = FALSE)
risk <- readr::read_csv("output/tables/risk_marker_distribution.csv", show_col_types = FALSE)

joint$joint_group <- factor(joint$joint_group, levels = joint$joint_group)
ci <- t(mapply(function(x, n) {
  stats::binom.test(x, n)$conf.int[1:2]
}, joint$cases, joint$n))
joint$raw_low <- ci[, 1]
joint$raw_high <- ci[, 2]

base_theme <- ggplot2::theme_classic(base_size = 12) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold"),
    plot.caption = ggplot2::element_text(color = "grey35"),
    axis.text = ggplot2::element_text(color = "grey15")
  )

p1 <- ggplot2::ggplot(joint, ggplot2::aes(x = joint_group, y = 100 * raw_prevalence)) +
  ggplot2::geom_col(fill = "#247D80", width = .68) +
  ggplot2::geom_errorbar(ggplot2::aes(ymin = 100 * raw_low, ymax = 100 * raw_high),
                         width = .13, linewidth = .55) +
  ggplot2::geom_text(ggplot2::aes(label = paste0("n=", n)), vjust = -1.0, size = 3.4) +
  ggplot2::scale_y_continuous(limits = c(0, min(100, max(100 * joint$raw_high) + 8)),
                               expand = ggplot2::expansion(mult = c(0, .03))) +
  ggplot2::labs(
    title = "Adverse metabolic markers across joint lifestyle groups",
    x = NULL, y = "Prevalence of >=2 markers (%)",
    caption = "Entirely synthetic data; exact binomial 95% CIs. Cutoffs are illustrative."
  ) + base_theme + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 22, hjust = 1))

# Reference group has PR=1 by definition; no interval needed on the reference.
joint$plot_low <- ifelse(joint$PR == 1 & is.na(joint$p_value), 1, joint$CI_low)
joint$plot_high <- ifelse(joint$PR == 1 & is.na(joint$p_value), 1, joint$CI_high)
p2 <- ggplot2::ggplot(joint, ggplot2::aes(x = PR, y = joint_group)) +
  ggplot2::geom_vline(xintercept = 1, linetype = "dashed", color = "grey45") +
  ggplot2::geom_segment(ggplot2::aes(x = plot_low, xend = plot_high,
                                     yend = joint_group), linewidth = .7, color = "#247D80") +
  ggplot2::geom_point(size = 2.8, color = "#247D80") +
  ggplot2::labs(
    title = "Adjusted prevalence ratios by joint exposure",
    x = "Prevalence ratio (95% robust CI)", y = NULL,
    caption = "Reference: lower sitting + frequent breaks. Synthetic cross-sectional data."
  ) + base_theme

biomarker$exposure <- dplyr::recode(biomarker$term,
                                   sitting_hours = "Sitting time (per hour/day)",
                                   breaks_per_hour = "Sitting breaks (per break/hour)")
biomarker$outcome <- dplyr::recode(biomarker$outcome,
                                   fasting_glucose = "Fasting glucose (mg/dL)",
                                   triglycerides = "Triglycerides (mg/dL)",
                                   hdl = "HDL cholesterol (mg/dL)",
                                   sbp = "Systolic BP (mmHg)")
p3 <- ggplot2::ggplot(biomarker, ggplot2::aes(y = exposure, x = beta)) +
  ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "grey45") +
  ggplot2::geom_segment(ggplot2::aes(x = CI_low, xend = CI_high, yend = exposure),
                        linewidth = .7, color = "#247D80") +
  ggplot2::geom_point(size = 2.6, color = "#247D80") +
  ggplot2::facet_wrap(~ outcome, scales = "free_x", ncol = 2) +
  ggplot2::labs(
    title = "Adjusted associations with cardiometabolic biomarkers",
    x = "Adjusted beta coefficient (95% CI)", y = NULL,
    caption = "Exploratory associations; outcome scales differ. Synthetic data only."
  ) + base_theme

p4 <- ggplot2::ggplot(risk, ggplot2::aes(x = factor(risk_marker_count), y = percent)) +
  ggplot2::geom_col(fill = "#247D80", width = .65) +
  ggplot2::labs(
    title = "Distribution of adverse cardiometabolic markers",
    x = "Number of adverse markers", y = "Synthetic participants (%)",
    caption = "Four binary marker definitions; simulated data only."
  ) + base_theme

plots <- list(
  fig1_joint_prevalence = list(plot = p1, width = 9.2, height = 5.8),
  fig2_adjusted_joint_PR = list(plot = p2, width = 8.7, height = 5.2),
  fig3_biomarker_coefficients = list(plot = p3, width = 10.4, height = 6.8),
  fig4_marker_count = list(plot = p4, width = 7.2, height = 4.8)
)
for (name in names(plots)) {
  spec <- plots[[name]]
  for (extension in c("png", "pdf")) {
    ggplot2::ggsave(
      file.path("output/figures", paste0(name, ".", extension)),
      plot = spec$plot,
      width = spec$width, height = spec$height, units = "in", dpi = 300,
      bg = "white"
    )
  }
}
message("Figures completed: four plots, each saved as PNG and PDF.")

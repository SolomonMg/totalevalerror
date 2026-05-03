#' Plotting methods for TEE objects
#'
#' `autoplot` methods are conditionally registered on package load when
#' `ggplot2` is available, via [vctrs::s3_register()]. All plot functions
#' return `ggplot` objects with no side effects, so users can compose
#' additional layers with `+`.
#'
#' @name tee_plots
#' @importFrom rlang .data
NULL

# ---- autoplot.tee_decomp -------------------------------------------------

#' @param object A TEE S3 object.
#' @param type Plot variant. For `tee_decomp`: "forest" (default), or
#'   "theta_ci". For `tee_dstudy`: "waterfall" (default) or "by_cat". For
#'   `tee_budget`: "frontier" (default) or "heatmap".
#' @param ... Forwarded to layer functions.
#' @rdname tee_plots
#' @export
autoplot.tee_decomp <- function(object, type = c("forest", "theta_ci"), ...) {
  require_ggplot2()
  type <- match.arg(type)
  switch(type, forest = forest_plot(object), theta_ci = theta_ci_plot(object))
}

forest_plot <- function(fit) {
  v <- fit$variance
  if (!"ci_lo_var" %in% names(v)) {
    v$ci_lo_var <- NA_real_
    v$ci_hi_var <- NA_real_
  }
  v <- v[order(-v$variance), ]
  v$tle_label <- factor(v$tle_label, levels = rev(v$tle_label))

  ggplot2::ggplot(v, ggplot2::aes(x = .data$variance, y = .data$tle_label,
                                   color = .data$tier)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$ci_lo_var,
                                         xmax = .data$ci_hi_var),
                            width = 0.2,
                            orientation = "y",
                            na.rm = TRUE) +
    ggplot2::scale_color_manual(values = c("model-side" = "#1a9850",
                                           "pipeline-side" = "#d73027")) +
    ggplot2::labs(x = "Variance", y = NULL, color = "Tier",
                  title = "TEE variance decomposition") +
    ggplot2::theme_minimal(base_size = 12)
}

theta_ci_plot <- function(fit) {
  ci <- tee_theta_ci(fit, level = 0.95)
  naive <- tee_naive_se(fit$design)
  z <- stats::qnorm(0.975)
  theta <- fit$meta$theta_hat
  df <- tibble::tibble(
    method   = c("naive", "TEE"),
    estimate = theta,
    ci_lo    = c(theta - z * naive$median_se, ci$ci_lo),
    ci_hi    = c(theta + z * naive$median_se, ci$ci_hi)
  )
  ggplot2::ggplot(df, ggplot2::aes(x = .data$method, y = .data$estimate,
                                    ymin = .data$ci_lo, ymax = .data$ci_hi)) +
    ggplot2::geom_pointrange(size = 0.6) +
    ggplot2::labs(x = NULL, y = "Theta-hat",
                  title = "95% CI on theta-hat: naive vs TEE") +
    ggplot2::theme_minimal(base_size = 12)
}

# ---- autoplot.tee_dstudy -------------------------------------------------

#' @rdname tee_plots
#' @export
autoplot.tee_dstudy <- function(object, type = c("waterfall", "by_cat"), ...) {
  require_ggplot2()
  type <- match.arg(type)
  switch(type, waterfall = waterfall_plot(object), by_cat = by_cat_plot(object))
}

waterfall_plot <- function(proj) {
  s <- proj$scenarios
  s$scenario <- factor(s$scenario, levels = rev(s$scenario))
  ggplot2::ggplot(s, ggplot2::aes(x = .data$reduction_pct, y = .data$scenario)) +
    ggplot2::geom_col(fill = "#1a9850", width = 0.7) +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f%%", .data$reduction_pct)),
                       hjust = -0.1, size = 3.4) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.15))) +
    ggplot2::labs(x = "Variance reduction vs baseline (%)", y = NULL,
                  title = "D-study waterfall") +
    ggplot2::theme_minimal(base_size = 12)
}

by_cat_plot <- function(proj) {
  if (is.null(proj$by)) {
    stop("`by_cat` plot requires a grouped tee_dstudy (use `by = category`).",
         call. = FALSE)
  }
  s <- proj$scenarios
  s$scenario <- factor(s$scenario, levels = rev(unique(s$scenario)))
  ggplot2::ggplot(s, ggplot2::aes(x = .data$reduction_pct, y = .data$scenario)) +
    ggplot2::geom_col(fill = "#1a9850", width = 0.7) +
    ggplot2::facet_wrap(stats::as.formula(paste("~", proj$by)), ncol = 1L) +
    ggplot2::labs(x = "Variance reduction vs baseline (%)", y = NULL,
                  title = sprintf("D-study waterfall by %s", proj$by)) +
    ggplot2::theme_minimal(base_size = 12)
}

# ---- autoplot.tee_budget -------------------------------------------------

#' @rdname tee_plots
#' @export
autoplot.tee_budget <- function(object, type = c("frontier", "heatmap"), ...) {
  require_ggplot2()
  type <- match.arg(type)
  switch(type, frontier = frontier_plot(object), heatmap = heatmap_plot(object))
}

frontier_plot <- function(alloc) {
  g <- alloc$grid
  ggplot2::ggplot(g, ggplot2::aes(x = .data$total_cost, y = .data$se_total,
                                   color = factor(.data$V), shape = factor(.data$R))) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::geom_point(data = alloc$optimum,
                        ggplot2::aes(x = .data$total_cost, y = .data$se_total),
                        inherit.aes = FALSE,
                        size = 5, shape = 1, color = "black") +
    ggplot2::labs(x = "Total cost", y = "Projected SE",
                  color = "V (prompts)", shape = "R (reps)",
                  title = "Budget frontier (open circle = optimum)") +
    ggplot2::theme_minimal(base_size = 12)
}

heatmap_plot <- function(alloc) {
  g <- alloc$grid
  ggplot2::ggplot(g, ggplot2::aes(x = factor(.data$V), y = factor(.data$R),
                                   fill = .data$se_total)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.4f", .data$se_total)),
                       size = 3) +
    ggplot2::scale_fill_viridis_c(option = "magma", direction = -1) +
    ggplot2::labs(x = "Prompt variants (V)", y = "Replications (R)",
                  fill = "SE",
                  title = "Projected SE across budget grid") +
    ggplot2::theme_minimal(base_size = 12)
}

# ---- internal helpers ----------------------------------------------------

require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required for plotting. Install with `install.packages(\"ggplot2\")`.",
         call. = FALSE)
  }
  invisible()
}

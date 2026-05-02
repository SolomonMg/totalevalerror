#' Corrected SE on theta-hat under a specific operational design
#'
#' Wraps the closed-form D-study formulas to compute the SE on `theta-hat`
#' under any combination of (`N`, `V`, `M`, `H`, `R`, `fix_judge`,
#' `fix_temperature`). Defaults to the fit's own pilot design.
#'
#' @param fit A `tee_decomp` object.
#' @param N,V,M,H,R Optional design overrides; default to the fit's own.
#' @param fix_temperature,fix_judge `TRUE` (operational, default), `FALSE`
#'   (averaged), or `NULL` (auto-detect from fit).
#' @param design_grid Optional tibble for vectorised SE computation. Each
#'   row should contain columns named like the scalar arguments.
#'
#' @return Numeric scalar (or tibble if `design_grid` is supplied).
#'
#' @examples
#' \dontrun{
#' tee_se(fit, N = 100, V = 5, M = 3, R = 8, fix_judge = FALSE)
#' tee_se(fit, design_grid = tibble::tibble(N = c(100, 200), V = 5, R = 3))
#' }
#' @export
tee_se <- function(fit,
                   N = NULL, V = NULL, M = NULL, H = NULL, R = NULL,
                   fix_temperature = TRUE, fix_judge = TRUE,
                   design_grid = NULL) {
  if (!inherits(fit, "tee_decomp")) {
    stop("`fit` must be a `tee_decomp` object.", call. = FALSE)
  }

  if (!is.null(design_grid)) {
    return(tee_se_grid(fit, design_grid))
  }

  baseline_se(fit, list(
    N = N, V = V, M = M, H = H, R = R,
    fix_judge = fix_judge,
    fix_temperature = fix_temperature
  ))
}

# Vectorised SE over a tibble of (N, V, M, H, R, fix_judge, fix_temperature).
tee_se_grid <- function(fit, grid) {
  if (!is.data.frame(grid)) {
    stop("`design_grid` must be a data frame.", call. = FALSE)
  }
  out <- grid
  out$se <- vapply(seq_len(nrow(grid)), function(i) {
    row <- grid[i, , drop = FALSE]
    baseline_se(fit, list(
      N = row$N %||% NULL,
      V = row$V %||% NULL,
      M = row$M %||% NULL,
      H = row$H %||% NULL,
      R = row$R %||% NULL,
      fix_judge       = row$fix_judge       %||% TRUE,
      fix_temperature = row$fix_temperature %||% TRUE
    ))
  }, numeric(1L))
  out
}

#' Naive standard error from a pilot
#'
#' Computes the SE that a researcher would report if they ignored the pipeline
#' factors entirely — collapse to a single configuration (one variant, one
#' judge, one temperature) and treat replicate-averaged item means as i.i.d.
#'
#' Returns the median naive SE across all observed configurations, and the
#' per-configuration values for inspection.
#'
#' @param design A `tee_design` object.
#' @param by Columns that index a configuration. Defaults to all faceting
#'   columns present in the design.
#'
#' @return A list with `median_se`, `per_config`, and `n_configs`.
#' @export
tee_naive_se <- function(design, by = NULL) {
  if (!inherits(design, "tee_design")) {
    stop("`design` must be a `tee_design` object.", call. = FALSE)
  }
  d <- design$data
  if (is.null(by)) {
    by <- intersect(c("variant_id", "judge_model", "sut_model", "temperature"),
                    names(d))
  }
  by <- by[by %in% names(d)]
  if (length(by) == 0L) {
    stop("No configuration columns found in design.", call. = FALSE)
  }

  # Within a configuration, average replicates per item; then SE is sd / sqrt(N).
  d_split <- split(d, d[, by, drop = FALSE], drop = TRUE)
  per_cfg <- lapply(d_split, function(sub) {
    item_means <- tapply(sub$outcome, sub$item_id, mean, na.rm = TRUE)
    item_means <- item_means[!is.na(item_means)]
    n <- length(item_means)
    if (n < 2L) return(NULL)
    tibble::tibble(
      n_items = n,
      mean    = mean(item_means),
      se      = stats::sd(item_means) / sqrt(n)
    )
  })
  per_cfg <- per_cfg[!vapply(per_cfg, is.null, logical(1L))]
  per_cfg <- dplyr::bind_rows(per_cfg, .id = "config")
  list(
    median_se  = stats::median(per_cfg$se, na.rm = TRUE),
    per_config = per_cfg,
    n_configs  = nrow(per_cfg)
  )
}

#' Compare naive SE to the TEE-corrected SE
#'
#' @param fit A `tee_decomp` object.
#' @param naive_se Output of [tee_naive_se()] or a numeric scalar.
#' @param theta_target Optional target mean for coverage assessment.
#' @param level Coverage level for the assessment, default 0.95.
#'
#' @return A list with `se_naive`, `se_tee`, `ratio`, `width_ratio`,
#'   `underestimate_pct`, and (optionally) `naive_covers`, `tee_covers`.
#' @export
tee_se_compare <- function(fit, naive_se, theta_target = NULL, level = 0.95) {
  se_naive <- if (is.list(naive_se)) naive_se$median_se else as.numeric(naive_se)
  se_tee   <- baseline_se(fit, NULL)
  ratio       <- se_naive / se_tee
  width_ratio <- ratio
  underestimate_pct <- 100 * (1 - width_ratio)

  out <- list(
    se_naive          = se_naive,
    se_tee            = se_tee,
    ratio             = ratio,
    width_ratio       = width_ratio,
    underestimate_pct = underestimate_pct
  )

  if (!is.null(theta_target)) {
    z <- stats::qnorm(1 - (1 - level) / 2)
    theta <- fit$meta$theta_hat
    out$naive_covers <- abs(theta - theta_target) <= z * se_naive
    out$tee_covers   <- abs(theta - theta_target) <= z * se_tee
  }
  out
}

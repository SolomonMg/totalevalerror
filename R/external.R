#' External-validity correlation against ground truth
#'
#' Computes Spearman and Kendall rank correlations between item-level
#' fitted values from a `tee_decomp` and a user-supplied ground-truth
#' column. Returns CIs via the Fisher transform (for Spearman) and via the
#' large-sample variance for Kendall's tau.
#'
#' Item-level fitted values are computed by averaging the model's fitted
#' values across all rows for each `item_id`, and joining to `ground_truth`
#' on `by`.
#'
#' @param fit A `tee_decomp` object.
#' @param ground_truth A data frame with at least `by` and a numeric
#'   `truth` column. Or a named numeric vector keyed by item_id.
#' @param by Column joining `fit$design$data` to `ground_truth`.
#' @param level CI coverage (default 0.95).
#'
#' @return A tibble with `metric` (`spearman` / `kendall`), `estimate`,
#'   `ci_lo`, `ci_hi`, and `n` (number of items joined).
#' @export
tee_external_corr <- function(fit, ground_truth,
                              by = "item_id",
                              level = 0.95) {
  if (!inherits(fit, "tee_decomp")) {
    stop("`fit` must be a `tee_decomp` object.", call. = FALSE)
  }

  fitted_vals <- stats::fitted(fit$model)
  d <- fit$design$data
  d$.fit <- fitted_vals
  item_means <- stats::aggregate(d$.fit, by = list(item_id = d[[by]]), FUN = mean)
  names(item_means) <- c(by, "fit_mean")

  if (is.numeric(ground_truth) && !is.null(names(ground_truth))) {
    ground_truth <- data.frame(
      item_id = names(ground_truth),
      truth   = unname(ground_truth),
      stringsAsFactors = FALSE
    )
    names(ground_truth)[1L] <- by
  }
  if (!is.data.frame(ground_truth) || !"truth" %in% names(ground_truth)) {
    stop("`ground_truth` must be a data frame with a `truth` column, or a named numeric vector.",
         call. = FALSE)
  }

  item_means[[by]] <- as.character(item_means[[by]])
  ground_truth[[by]] <- as.character(ground_truth[[by]])
  joined <- merge(item_means, ground_truth, by = by)
  if (nrow(joined) < 3L) {
    stop("Fewer than 3 items joined; cannot compute external correlation.",
         call. = FALSE)
  }

  z <- stats::qnorm(1 - (1 - level) / 2)
  n <- nrow(joined)

  rho <- stats::cor(joined$fit_mean, joined$truth, method = "spearman")
  rho_se <- 1 / sqrt(n - 3L)
  rho_ci <- tanh(atanh(rho) + c(-1, 1) * z * rho_se)

  tau <- stats::cor(joined$fit_mean, joined$truth, method = "kendall")
  tau_se <- sqrt(2 * (2 * n + 5) / (9 * n * (n - 1)))
  tau_ci <- tau + c(-1, 1) * z * tau_se

  tibble::tibble(
    metric   = c("spearman", "kendall"),
    estimate = c(rho, tau),
    ci_lo    = c(rho_ci[1L], tau_ci[1L]),
    ci_hi    = c(rho_ci[2L], tau_ci[2L]),
    n        = n
  )
}

#' External-validity correlation against ground truth
#'
#' Computes Spearman and Kendall correlations between item-level fitted values
#' from a `tee_decomp` and a user-supplied ground-truth column. Returns CIs
#' via the Fisher transform.
#'
#' @param fit A `tee_decomp` object.
#' @param ground_truth Numeric vector of gold-standard values.
#' @param by Item-identifier column joining `fit$design$data` to
#'   `ground_truth`.
#'
#' @return A tibble with `metric` (`spearman`/`kendall`), `estimate`,
#'   `ci_lo`, `ci_hi`.
#' @export
tee_external_corr <- function(fit, ground_truth, by = "item_id") {
  stop("tee_external_corr() is not yet implemented (Phase 6).", call. = FALSE)
}

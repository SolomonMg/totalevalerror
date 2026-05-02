#' Corrected SE on theta-hat under a specific operational design
#'
#' @param fit A `tee_decomp` object.
#' @param N,V,M,H,R Optional design overrides; default to the fit's own design.
#' @param fix_temperature,fix_judge Logical or `NULL` (auto-detect from fit).
#' @param design_grid Optional tibble for vectorised SE computation.
#'
#' @return Numeric scalar or tibble.
#' @export
tee_se <- function(fit,
                   N = NULL, V = NULL, M = NULL, H = NULL, R = NULL,
                   fix_temperature = NULL, fix_judge = NULL,
                   design_grid = NULL) {
  stop("tee_se() is not yet implemented (Phase 4).", call. = FALSE)
}

#' Naive standard error from a pilot
#'
#' Computes the naive SE per configuration (variant x judge), the standard
#' approach when the pipeline factors are ignored.
#'
#' @param design A `tee_design` object.
#' @param by Columns to compute per-config SEs over.
#'
#' @return A tibble with one row per configuration.
#' @export
tee_naive_se <- function(design, by = c("variant_id", "judge_model")) {
  stop("tee_naive_se() is not yet implemented (Phase 4).", call. = FALSE)
}

#' Compare naive SE to the TEE-corrected SE
#'
#' @param fit A `tee_decomp` object.
#' @param naive_se Output of [tee_naive_se()].
#' @param theta_target Optional target mean for coverage assessment.
#'
#' @return A list with ratio, width-ratio, and (optionally) coverage.
#' @export
tee_se_compare <- function(fit, naive_se, theta_target = NULL) {
  stop("tee_se_compare() is not yet implemented (Phase 4).", call. = FALSE)
}

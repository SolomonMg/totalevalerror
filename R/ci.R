#' Confidence intervals on individual variance components
#'
#' @param fit A `tee_decomp` object.
#' @param type "profile" or "bootstrap".
#' @param nsim Bootstrap replications when `type = "bootstrap"`.
#'
#' @return A tibble with `component`, `ci_lo_var`, `ci_hi_var`.
#' @export
tee_ci <- function(fit, type = c("profile", "bootstrap"), nsim = 200) {
  stop("tee_ci() is not yet implemented (Phase 3).", call. = FALSE)
}

#' Confidence interval on theta-hat
#'
#' @param fit A `tee_decomp` object.
#' @param level Coverage level (default 0.95).
#' @param method "normal" or "bootstrap".
#' @param design Optional operational design override; defaults to `fit`'s own.
#'
#' @return A 1-row tibble with `estimate`, `ci_lo`, `ci_hi`, `se`, `method`.
#' @export
tee_theta_ci <- function(fit,
                         level = 0.95,
                         method = c("normal", "bootstrap"),
                         design = NULL) {
  stop("tee_theta_ci() is not yet implemented (Phase 3).", call. = FALSE)
}

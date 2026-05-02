#' Recommend pilot sizes
#'
#' Inverts the D-study formula to recommend the minimum
#' `(N, V, M, R)` such that variance-component estimates achieve a target
#' precision.
#'
#' @param target_se_pct Target precision on Var-component estimates.
#' @param prior_vc Optional named list of prior variance guesses; if `NULL`,
#'   uses a built-in conservative prior calibrated from the paper's pilots.
#' @param facets Which facets to size; defaults to all four.
#'
#' @return A tibble with recommended sizes and the resulting precision.
#' @export
tee_pilot_recommend <- function(target_se_pct = 20,
                                prior_vc = NULL,
                                facets = c("item", "prompt", "judge", "replicate")) {
  stop("tee_pilot_recommend() is not yet implemented (Phase 2).", call. = FALSE)
}

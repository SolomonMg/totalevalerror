#' Simulate data from the TEE DGP
#'
#' Generates synthetic data matching the paper's crossed random-effects DGP.
#' Useful for testing, teaching, and reproducing the Monte Carlo coverage
#' simulations from Appendix D.
#'
#' @param N,V,M,H,R Design parameters.
#' @param variances Named list of variance components.
#' @param scoring "likert" (continuous) or "binary" (round + clip).
#' @param seed Random seed.
#'
#' @return A long-format tibble with one row per LLM call, suitable for
#'   [tee_design()].
#' @export
tee_simulate <- function(N = 100, V = 5, M = 3, H = 2, R = 3,
                         variances = NULL,
                         scoring = c("likert", "binary"),
                         seed = 42) {
  stop("tee_simulate() is not yet implemented (Phase 6).", call. = FALSE)
}

#' Monte Carlo coverage study
#'
#' Wraps `SimDesign::Generate / Analyse / Summarise` to run a coverage study
#' across a grid of scenarios.
#'
#' @param scenarios Tibble of scenarios.
#' @param n_sim Number of simulations per scenario.
#' @param seed Random seed.
#'
#' @return A tibble with bias, RMSE, coverage per scenario.
#' @export
tee_sim_coverage <- function(scenarios, n_sim = 1000, seed = 42) {
  stop("tee_sim_coverage() is not yet implemented (Phase 6).", call. = FALSE)
}

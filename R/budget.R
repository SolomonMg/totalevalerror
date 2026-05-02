#' Optimal budget allocation
#'
#' Grid search over `(N, V, R)` to minimise projected `Var(theta-hat)` under a
#' fixed budget and item pool. Supports heterogeneous per-judge / per-SUT
#' costs.
#'
#' @param fit A `tee_decomp` object.
#' @param budget Total dollars (or calls if `cost_per_call = 1`).
#' @param cost_per_call Scalar or tibble keyed by judge / SUT.
#' @param n_pool Maximum items available.
#' @param v_max Maximum prompt variants.
#' @param r_max Maximum replications.
#' @param fix_judge,fix_temperature Logical, default `TRUE` (operational case).
#'
#' @return An object of class `tee_budget`.
#' @export
tee_budget_allocate <- function(fit,
                                budget,
                                cost_per_call = 1,
                                n_pool = NULL,
                                v_max = NULL,
                                r_max = 8,
                                fix_judge = TRUE,
                                fix_temperature = TRUE) {
  stop("tee_budget_allocate() is not yet implemented (Phase 5).", call. = FALSE)
}

#' Compare naive vs standard vs TEE allocation
#'
#' @param fit A `tee_decomp` object.
#' @param budget,n_pool,cost_per_call As in [tee_budget_allocate()].
#' @param strategies Character vector of strategies to compare.
#'
#' @return A tibble with one row per strategy.
#' @export
tee_budget_compare <- function(fit, budget, n_pool = NULL, cost_per_call = 1,
                               strategies = c("naive", "standard", "tee")) {
  stop("tee_budget_compare() is not yet implemented (Phase 5).", call. = FALSE)
}

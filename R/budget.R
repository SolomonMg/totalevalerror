#' Optimal budget allocation
#'
#' Grid search over `(N, V, R)` to minimise projected `Var(theta-hat)`
#' under a fixed budget and item pool. By default, the operational case
#' (fixed judge & temperature) is used: a single configuration deployed at
#' inference time, where the budget buys items × prompts × replications.
#'
#' Pass a tibble to `cost_per_call` to express heterogeneous per-judge or
#' per-SUT costs (e.g., Opus calls cost 30 times Haiku calls). The tibble
#' should have one row per level of `judge_model` or `sut_model` and a
#' `cost_per_call` column. The grid search then picks the cheapest call
#' under the user's caps; if a `judge_model` / `sut_model` column is
#' included, the optimisation respects that subset of judges / SUTs.
#'
#' @param fit A `tee_decomp` object.
#' @param budget Total dollars (or calls if `cost_per_call = 1`).
#' @param cost_per_call Scalar or tibble keyed by judge / SUT.
#' @param n_pool Maximum items available. Defaults to twice the pilot's `N`.
#' @param v_max Maximum prompt variants. Defaults to `5`.
#' @param r_max Maximum replications. Defaults to `8`.
#' @param fix_judge,fix_temperature Logical, default `TRUE`.
#'
#' @return An object of class `tee_budget` with the optimum and the full
#'   grid.
#'
#' @examples
#' \dontrun{
#' alloc <- tee_budget_allocate(fit, budget = 6000, n_pool = 1000,
#'                              v_max = 5, r_max = 8)
#' alloc
#' }
#' @export
tee_budget_allocate <- function(fit,
                                budget,
                                cost_per_call = 1,
                                n_pool = NULL,
                                v_max = 5L,
                                r_max = 8L,
                                fix_judge = TRUE,
                                fix_temperature = TRUE) {
  if (!inherits(fit, "tee_decomp")) {
    stop("`fit` must be a `tee_decomp` object.", call. = FALSE)
  }
  if (!is.numeric(budget) || budget <= 0) {
    stop("`budget` must be a positive number.", call. = FALSE)
  }
  if (is.null(n_pool)) n_pool <- 2L * fit$meta$N

  # Resolve cost_per_call to a single average per-call cost. The grid
  # search is over (N, V, R); judge / SUT counts are held fixed at the
  # pilot's M / S unless the user passes a tibble that selects a subset.
  cpc <- resolve_cost_per_call(cost_per_call, fit)

  vc <- vc_named_list(fit)
  M  <- if (is.na(fit$meta$M)) 1L else fit$meta$M
  H  <- if (is.na(fit$meta$H)) 1L else fit$meta$H

  # Grid search.
  grid <- expand.grid(
    V = seq_len(v_max),
    R = seq_len(r_max),
    KEEP.OUT.ATTRS = FALSE
  )
  grid$N <- pmin(floor(budget / (cpc * grid$V * grid$R)), n_pool)
  grid <- grid[grid$N >= 2L, , drop = FALSE]
  if (nrow(grid) == 0L) {
    stop("Budget too small: cannot afford even N = 2 items at any (V, R).",
         call. = FALSE)
  }
  grid$total_calls <- grid$N * grid$V * grid$R
  grid$total_cost  <- grid$total_calls * cpc
  grid$var_total   <- vapply(seq_len(nrow(grid)), function(i) {
    dstudy_total_variance(vc,
                          N = grid$N[i], V = grid$V[i],
                          M = M, H = H, R = grid$R[i],
                          fix_judge = fix_judge,
                          fix_temperature = fix_temperature)
  }, numeric(1L))
  grid$se_total <- sqrt(grid$var_total)

  best <- grid[which.min(grid$var_total), , drop = FALSE]

  structure(
    list(
      fit             = fit,
      budget          = budget,
      cost_per_call   = cpc,
      cost_input      = cost_per_call,
      n_pool          = n_pool,
      grid            = tibble::as_tibble(grid),
      optimum         = tibble::as_tibble(best),
      fix_judge       = fix_judge,
      fix_temperature = fix_temperature,
      call            = match.call()
    ),
    class = "tee_budget"
  )
}

# Resolve cost_per_call to a scalar average. If a tibble is passed, take
# the mean across its `cost_per_call` column. Users who want to minimise
# over judge / SUT subset can subset the tibble before passing.
resolve_cost_per_call <- function(cost_per_call, fit) {
  if (is.numeric(cost_per_call)) {
    if (length(cost_per_call) != 1L || cost_per_call <= 0) {
      stop("`cost_per_call` must be a positive scalar or a tibble.",
           call. = FALSE)
    }
    return(cost_per_call)
  }
  if (!is.data.frame(cost_per_call) ||
      !"cost_per_call" %in% names(cost_per_call)) {
    stop("`cost_per_call` tibble must have a `cost_per_call` column.",
         call. = FALSE)
  }
  mean(cost_per_call$cost_per_call, na.rm = TRUE)
}

#' @export
print.tee_budget <- function(x, ...) {
  o <- x$optimum
  cli::cli_text("{.cls tee_budget}: optimum at N={o$N}, V={o$V}, R={o$R}")
  cli::cli_text("Projected SE: {.val {round(o$se_total, 5)}} | Budget used: {.val {round(o$total_cost, 2)}}")
  invisible(x)
}

#' Compare naive, standard, and TEE budget allocation
#'
#' Three strategies on the same budget:
#' \describe{
#'   \item{naive}{One configuration, R = 3 replications, all remaining budget into N.}
#'   \item{standard}{One configuration, R = 1, all budget into N (capped at pool).}
#'   \item{tee}{Optimum from [tee_budget_allocate()].}
#' }
#'
#' @param fit A `tee_decomp` object.
#' @param budget,n_pool,cost_per_call As in [tee_budget_allocate()].
#' @param strategies Subset of `c("naive", "standard", "tee")` to evaluate.
#' @param fix_judge,fix_temperature Logical defaults `TRUE`.
#'
#' @return A tibble with one row per strategy.
#' @export
tee_budget_compare <- function(fit, budget,
                               n_pool = NULL,
                               cost_per_call = 1,
                               strategies = c("naive", "standard", "tee"),
                               fix_judge = TRUE, fix_temperature = TRUE) {
  if (!inherits(fit, "tee_decomp")) {
    stop("`fit` must be a `tee_decomp` object.", call. = FALSE)
  }
  strategies <- match.arg(strategies, several.ok = TRUE)
  cpc <- resolve_cost_per_call(cost_per_call, fit)
  if (is.null(n_pool)) n_pool <- 2L * fit$meta$N
  vc <- vc_named_list(fit)
  M  <- if (is.na(fit$meta$M)) 1L else fit$meta$M
  H  <- if (is.na(fit$meta$H)) 1L else fit$meta$H

  rows <- list()
  if ("naive" %in% strategies) {
    V <- 1L; R <- 3L
    N <- pmin(floor(budget / (cpc * V * R)), n_pool)
    rows[["naive"]] <- tibble::tibble(
      strategy = "naive", N = N, V = V, R = R,
      var_total = dstudy_total_variance(vc, N, V, M, H, R, fix_judge, fix_temperature),
      total_cost = N * V * R * cpc
    )
  }
  if ("standard" %in% strategies) {
    V <- 1L; R <- 1L
    N <- pmin(floor(budget / (cpc * V * R)), n_pool)
    rows[["standard"]] <- tibble::tibble(
      strategy = "standard", N = N, V = V, R = R,
      var_total = dstudy_total_variance(vc, N, V, M, H, R, fix_judge, fix_temperature),
      total_cost = N * V * R * cpc
    )
  }
  if ("tee" %in% strategies) {
    alloc <- tee_budget_allocate(fit, budget,
                                 cost_per_call = cost_per_call,
                                 n_pool = n_pool,
                                 fix_judge = fix_judge,
                                 fix_temperature = fix_temperature)
    o <- alloc$optimum
    rows[["tee"]] <- tibble::tibble(
      strategy = "tee", N = o$N, V = o$V, R = o$R,
      var_total = o$var_total,
      total_cost = o$total_cost
    )
  }
  out <- dplyr::bind_rows(rows)
  out$se_total <- sqrt(out$var_total)
  out
}

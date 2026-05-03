#' Simulate data from the TEE DGP
#'
#' Generates synthetic data matching the paper's crossed random-effects DGP.
#' Each row is one LLM call. Useful for testing, teaching, and reproducing
#' the Monte Carlo coverage simulations from Appendix D.
#'
#' The default `variances` list draws from the AILuminate-pilot prior in the
#' paper. Override any entry to run a custom DGP.
#'
#' Likert mode returns the linear-scale outcome directly (no rounding).
#' Binary mode applies a logistic transform centered at 0 and draws from
#' Bernoulli(`p`) where `p = plogis(linear_pred + replicate_noise)`.
#'
#' @param N,V,M,H,R Design parameters (items, prompt variants, judges,
#'   temperatures, replications).
#' @param variances Named list of variance components.
#' @param judge_means Optional vector of length `M` for judge fixed effects.
#'   Defaults to a small evenly-spaced sequence.
#' @param temp_means Optional vector of length `H` for temperature fixed
#'   effects. Defaults to a small evenly-spaced sequence.
#' @param scoring "likert" (continuous) or "binary".
#' @param seed Random seed.
#'
#' @return A long-format tibble with columns `item_id`, `variant_id`,
#'   `judge_model`, `temperature`, `replication`, and `outcome`.
#'
#' @examples
#' sim <- tee_simulate(N = 30, V = 4, M = 2, R = 3, seed = 1)
#' head(sim)
#' @export
tee_simulate <- function(N = 100L, V = 5L, M = 3L, H = 1L, R = 3L,
                         variances = NULL,
                         judge_means = NULL,
                         temp_means  = NULL,
                         scoring = c("likert", "binary"),
                         seed = 42) {
  scoring <- match.arg(scoring)
  if (any(c(N, V, M, H, R) < 1L)) {
    stop("All facet counts must be >= 1.", call. = FALSE)
  }

  default_vc <- list(
    item            = 0.20,
    prompt          = 0.05,
    item_x_prompt   = 0.04,
    item_x_judge    = 0.10,
    prompt_x_judge  = 0.02,
    item_x_temp     = 0.00,
    prompt_x_temp   = 0.00,
    cell_level      = 0.05,
    replicate       = 0.15
  )
  vc <- utils::modifyList(default_vc, variances %||% list())

  if (is.null(judge_means)) {
    judge_means <- if (M == 1L) 0 else seq(0, 0.10, length.out = M)
  }
  if (is.null(temp_means)) {
    temp_means <- if (H == 1L) 0 else seq(0, 0.05, length.out = H)
  }

  set.seed(seed)
  alpha <- stats::rnorm(N, sd = sqrt(vc$item))
  phi   <- stats::rnorm(V, sd = sqrt(vc$prompt))
  ip    <- matrix(stats::rnorm(N * V, sd = sqrt(vc$item_x_prompt)), N, V)
  ij    <- matrix(stats::rnorm(N * M, sd = sqrt(vc$item_x_judge)), N, M)
  pj    <- matrix(stats::rnorm(V * M, sd = sqrt(vc$prompt_x_judge)), V, M)
  it    <- matrix(stats::rnorm(N * H, sd = sqrt(vc$item_x_temp)), N, H)
  pt    <- matrix(stats::rnorm(V * H, sd = sqrt(vc$prompt_x_temp)), V, H)

  grid <- expand.grid(
    item_id     = seq_len(N),
    variant_id  = seq_len(V),
    judge_model = seq_len(M),
    temperature = seq_len(H),
    replication = seq_len(R),
    KEEP.OUT.ATTRS = FALSE
  )

  # Cell-level random shifts: one draw per (item, variant, judge, temp).
  cell_keys <- with(grid, paste(item_id, variant_id, judge_model, temperature, sep = "."))
  unique_cells <- unique(cell_keys)
  cell_eps <- stats::rnorm(length(unique_cells), sd = sqrt(vc$cell_level))
  names(cell_eps) <- unique_cells

  # Replicate noise: one draw per row.
  rho <- stats::rnorm(nrow(grid), sd = sqrt(vc$replicate))

  linear_pred <- with(grid,
    alpha[item_id] + phi[variant_id] +
      ip[cbind(item_id, variant_id)] +
      ij[cbind(item_id, judge_model)] +
      pj[cbind(variant_id, judge_model)] +
      it[cbind(item_id, temperature)] +
      pt[cbind(variant_id, temperature)] +
      judge_means[judge_model] +
      temp_means[temperature] +
      cell_eps[cell_keys] + rho
  )

  outcome <- if (scoring == "likert") {
    linear_pred
  } else {
    p <- stats::plogis(linear_pred)
    stats::rbinom(length(p), size = 1L, prob = p)
  }

  tibble::tibble(
    item_id     = factor(grid$item_id),
    variant_id  = factor(grid$variant_id),
    judge_model = factor(grid$judge_model),
    temperature = factor(grid$temperature),
    replication = grid$replication,
    outcome     = outcome
  )
}

#' Monte Carlo coverage study
#'
#' Runs `n_sim` simulations under each scenario, fits the TEE decomposition,
#' and reports bias / RMSE / coverage of the variance components. Returns a
#' tibble with one row per (scenario, component).
#'
#' Uses the package's own [tee_simulate()] under the hood; `SimDesign` is
#' supported when installed for parallel execution.
#'
#' @param scenarios A tibble where each row defines a scenario. Required
#'   columns are facet sizes (`N`, `V`, `M`, `H`, `R`) and a list-column
#'   `variances` of named lists (true variance components).
#' @param n_sim Number of simulations per scenario.
#' @param seed Base seed (per scenario seed = `seed + scenario_index`).
#' @param coverage_level Coverage target (default 0.95).
#'
#' @return A tibble with `scenario_id`, `component`, `truth`, `mean_est`,
#'   `bias`, `rmse`, `coverage` columns.
#' @export
tee_sim_coverage <- function(scenarios,
                             n_sim = 200L,
                             seed = 42,
                             coverage_level = 0.95) {
  if (!is.data.frame(scenarios) || !"variances" %in% names(scenarios)) {
    stop("`scenarios` must be a tibble with a list-column named `variances`.",
         call. = FALSE)
  }
  required <- c("N", "V", "M", "H", "R")
  miss <- setdiff(required, names(scenarios))
  if (length(miss)) {
    stop(sprintf("Missing scenario columns: %s", paste(miss, collapse = ", ")),
         call. = FALSE)
  }

  out <- vector("list", nrow(scenarios))
  for (i in seq_len(nrow(scenarios))) {
    s <- scenarios[i, ]
    truth <- s$variances[[1L]]
    sim_results <- replicate(n_sim, simplify = FALSE, expr = {
      sim <- tee_simulate(N = s$N, V = s$V, M = s$M, H = s$H, R = s$R,
                          variances = truth, seed = sample.int(.Machine$integer.max, 1L))
      des <- tee_design(sim,
                        outcome     = !!rlang::sym("outcome"),
                        item        = !!rlang::sym("item_id"),
                        prompt      = !!rlang::sym("variant_id"),
                        judge       = !!rlang::sym("judge_model"),
                        temperature = !!rlang::sym("temperature"),
                        replicate   = !!rlang::sym("replication"),
                        scoring = "likert")
      fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
      fit$variance
    })
    # Aggregate per-label across simulations.
    labels <- intersect(names(truth),
                        unique(unlist(lapply(sim_results, function(v) v$tle_label))))
    rows <- lapply(labels, function(lbl) {
      ests <- vapply(sim_results, function(v) {
        x <- v$variance[v$tle_label %in% lbl]
        if (length(x) == 0L) NA_real_ else x[1L]
      }, numeric(1L))
      ests <- ests[!is.na(ests)]
      truth_v <- truth[[lbl]] %||% NA_real_
      tibble::tibble(
        scenario_id = i,
        component   = lbl,
        truth       = truth_v,
        mean_est    = mean(ests),
        bias        = mean(ests) - truth_v,
        rmse        = sqrt(mean((ests - truth_v)^2))
      )
    })
    out[[i]] <- dplyr::bind_rows(rows)
  }
  dplyr::bind_rows(out)
}

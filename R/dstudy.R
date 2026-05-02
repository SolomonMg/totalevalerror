#' Project Var(theta-hat) under hypothetical designs (D-study)
#'
#' Sweeps a grid of operational designs and reports the projected
#' `Var(theta-hat)` under each, using the closed-form formulas from the
#' paper. (Phase 4 — scenario grid + per-category — to be implemented.)
#'
#' @param fit A `tee_decomp` object.
#' @param scenarios Optional tibble of scenarios; defaults to a 10-row grid
#'   derived from `fit`'s baseline design.
#' @param by Optional grouping column for per-category projections.
#'
#' @return An object of class `tee_dstudy`.
#' @export
tee_dstudy <- function(fit, scenarios = NULL, by = NULL) {
  stop("tee_dstudy() is not yet implemented (Phase 4).", call. = FALSE)
}

#' Closed-form D-study variance: fixed temperature & fixed judge
#'
#' Case 1 of the paper's D-study: when both temperature and judge are
#' treated as fixed (operational case for a single deployed configuration),
#' the interaction terms `s2_ij` and `s2_pj` average over items / prompts
#' but not over the fixed facet, so they remain in the projection.
#'
#' @param vc Named list of variance components keyed by TEE label
#'   (`item`, `prompt`, `item x prompt`, `item x judge`, `prompt x judge`,
#'   `item x temperature`, `prompt x temperature`, `cell-level`,
#'   `replicate noise`, `between-category`).
#' @param N Items.
#' @param V Prompt variants.
#' @param R Replications.
#' @param M Judges (default 1, treated as fixed).
#' @param H Temperatures (default 1, treated as fixed).
#'
#' @return Numeric scalar — projected `Var(theta-hat)`.
#' @export
tee_dstudy_var_fixed <- function(vc, N, V, R, M = 1L, H = 1L) {
  dstudy_total_variance(vc, N, V, M, H, R,
                        fix_judge = TRUE, fix_temperature = TRUE)
}

#' Closed-form D-study variance: averaged over temperatures and judges
#' @param vc Named list of variance components.
#' @param N,V,M,H,R Design parameters.
#' @return Numeric scalar.
#' @export
tee_dstudy_var_avg <- function(vc, N, V, M, H, R) {
  dstudy_total_variance(vc, N, V, M, H, R,
                        fix_judge = FALSE, fix_temperature = FALSE)
}

#' Closed-form D-study variance: mixed cases
#' @param vc Named list of variance components.
#' @param N,V,M,H,R Design parameters.
#' @param fix_judge,fix_temperature Logical flags.
#' @return Numeric scalar.
#' @export
tee_dstudy_var_mixed <- function(vc, N, V, M, H, R, fix_judge, fix_temperature) {
  dstudy_total_variance(vc, N, V, M, H, R,
                        fix_judge = fix_judge,
                        fix_temperature = fix_temperature)
}

# ---- Internal: master closed-form projection ------------------------------

# Pull the relevant variance components into a named list, keyed by
# canonical TLE labels. Missing components default to 0. Used by every
# closed-form helper.
vc_named_list <- function(fit) {
  v <- fit$variance
  pull_label <- function(label) {
    x <- v$variance[v$tle_label == label]
    if (length(x) == 0L) 0 else x[1L]
  }
  list(
    cat       = pull_label("between-category"),
    item      = pull_label("within-category item") + pull_label("item"),
    prompt    = pull_label("prompt"),
    ip        = pull_label("item x prompt"),
    ij        = pull_label("item x judge"),
    pj        = pull_label("prompt x judge"),
    it        = pull_label("item x temperature"),
    pt        = pull_label("prompt x temperature"),
    cell      = sum(v$variance[grepl("^cell-level", v$tle_label)]),
    replicate = pull_label("replicate noise")
  )
}

# Closed-form Var(theta-hat) under a generic design.
#   N=items, V=prompts, M=judges, H=temperatures, R=reps.
#   fix_judge=TRUE  -> judge interactions enter at /N (item) and /V (prompt).
#   fix_judge=FALSE -> judge interactions average at /(N*M) and /(V*M).
#   Same logic for fix_temperature with H.
# Cell-level term scales with the product of all FACETED averaging axes;
# replicate term additionally divides by R.
dstudy_total_variance <- function(vc, N, V, M, H, R,
                                  fix_judge, fix_temperature) {
  # Item + category lump into /N (categories are taxonomy-level fixed).
  v_item <- (vc$cat + vc$item) / N
  v_prompt <- vc$prompt / V
  v_ip <- vc$ip / (N * V)

  v_ij <- if (fix_judge)       vc$ij / N      else vc$ij / (N * M)
  v_pj <- if (fix_judge)       vc$pj / V      else vc$pj / (V * M)
  v_it <- if (fix_temperature) vc$it / N      else vc$it / (N * H)
  v_pt <- if (fix_temperature) vc$pt / V      else vc$pt / (V * H)

  # Cell-level averages across all averaged factors; cell-level does NOT
  # divide by R because it's constant within a cell.
  cell_div <- N * V *
    (if (fix_judge)       1L else M) *
    (if (fix_temperature) 1L else H)
  v_cell <- vc$cell / cell_div

  # Replicate noise divides by R as well.
  v_rep <- vc$replicate / (cell_div * R)

  v_item + v_prompt + v_ip + v_ij + v_pj + v_it + v_pt + v_cell + v_rep
}

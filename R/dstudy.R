#' Project Var(theta-hat) under hypothetical designs (D-study)
#'
#' Sweeps a grid of operational designs and reports the projected
#' `Var(theta-hat)` and `SE(theta-hat)` under each, using the closed-form
#' formulas from the paper.
#'
#' The default scenario grid covers:
#'   * Two baselines (averaged-over-design and operational/fixed-design).
#'   * Single-lever changes: +5 reps, +2 prompts, fix temp, fix judge,
#'     double items.
#'   * Compound: fix temp & judge; +5 reps & fix; maximal mix.
#'
#' Pass a tibble to `scenarios` to override; required columns are
#' `scenario, N_d, V_d, M_d, H_d, R_d, fix_temp, fix_judge`.
#'
#' Pass a column name to `by` for per-category projections — fits the model
#' separately on each category subset and stacks the results.
#'
#' @param fit A `tee_decomp` object.
#' @param scenarios Optional tibble of scenarios.
#' @param by Optional grouping column for per-category projections.
#'
#' @return An object of class `tee_dstudy`.
#' @export
tee_dstudy <- function(fit, scenarios = NULL, by = NULL) {
  if (!inherits(fit, "tee_decomp")) {
    stop("`fit` must be a `tee_decomp` object.", call. = FALSE)
  }

  if (!is.null(by)) {
    return(tee_dstudy_grouped(fit, by, scenarios))
  }

  if (is.null(scenarios)) scenarios <- default_scenarios(fit$meta)
  validate_scenarios(scenarios)

  vc <- vc_named_list(fit)
  scenarios$var_total <- vapply(seq_len(nrow(scenarios)), function(i) {
    s <- scenarios[i, ]
    dstudy_total_variance(vc,
                          N = s$N_d, V = s$V_d, M = s$M_d, H = s$H_d, R = s$R_d,
                          fix_judge       = s$fix_judge,
                          fix_temperature = s$fix_temp)
  }, numeric(1L))
  scenarios$se_total <- sqrt(scenarios$var_total)

  baseline_var <- scenarios$var_total[scenarios$scenario == "Baseline (avg temp & judge)"]
  if (length(baseline_var) == 0L) baseline_var <- scenarios$var_total[1L]
  scenarios$pct_of_baseline <- round(100 * scenarios$var_total / baseline_var, 1)
  scenarios$reduction_pct   <- round(100 * (1 - scenarios$var_total / baseline_var), 1)

  structure(
    list(
      fit       = fit,
      scenarios = scenarios,
      baseline  = list(scenario = "Baseline (avg temp & judge)",
                       var_total = baseline_var,
                       se_total  = sqrt(baseline_var)),
      by        = NULL,
      call      = match.call()
    ),
    class = "tee_dstudy"
  )
}

# Default 10-scenario grid driven by the fit's pilot design.
default_scenarios <- function(meta) {
  N <- meta$N
  V <- if (is.na(meta$V)) 1L else meta$V
  # Use the SUT facet count when there is no judge facet (MMLU-style fits).
  # The two are mutually exclusive in the current API.
  M_raw <- if (!is.na(meta$M)) meta$M
           else if (!is.null(meta$S) && !is.na(meta$S)) meta$S
           else NA_integer_
  M <- if (is.na(M_raw)) 1L else M_raw
  H <- if (is.na(meta$H)) 1L else meta$H
  R <- meta$R

  tibble::tribble(
    ~scenario,                                                ~N_d,    ~V_d,    ~M_d, ~H_d, ~R_d,    ~fix_temp, ~fix_judge,
    "Baseline (avg temp & judge)",                             N,      V,       M,    H,    R,       FALSE,     FALSE,
    "Baseline (fix temp & judge)",                             N,      V,       M,    H,    R,       TRUE,      TRUE,
    "+5 replications",                                         N,      V,       M,    H,    R + 5L,  FALSE,     FALSE,
    "+2 prompt variants",                                      N,      V + 2L,  M,    H,    R,       FALSE,     FALSE,
    "Fix temperature",                                         N,      V,       M,    H,    R,       TRUE,      FALSE,
    "Fix judge model",                                         N,      V,       M,    H,    R,       FALSE,     TRUE,
    "Fix temp & judge",                                        N,      V,       M,    H,    R,       TRUE,      TRUE,
    "+5 reps & fix temp & judge",                              N,      V,       M,    H,    R + 5L,  TRUE,      TRUE,
    "Double items",                                            N * 2L, V,       M,    H,    R,       FALSE,     FALSE,
    "Maximal: 2x items + 5 prompts + 10 reps + fix design",    N * 2L, 5L,      M,    H,    10L,     TRUE,      TRUE
  )
}

validate_scenarios <- function(s) {
  required <- c("scenario", "N_d", "V_d", "M_d", "H_d", "R_d", "fix_temp", "fix_judge")
  missing <- setdiff(required, names(s))
  if (length(missing)) {
    stop(sprintf("`scenarios` is missing column(s): %s", paste(missing, collapse = ", ")),
         call. = FALSE)
  }
  invisible(s)
}

# Per-category D-study: fits the model on each category subset and stacks.
tee_dstudy_grouped <- function(fit, by, scenarios) {
  d <- fit$design$data
  by_chr <- if (rlang::is_quosure(by)) rlang::as_label(by) else as.character(by)
  if (!by_chr %in% names(d)) {
    stop(sprintf("Column `%s` not found in design data.", by_chr), call. = FALSE)
  }
  groups <- split(d, d[[by_chr]])
  results <- lapply(names(groups), function(g) {
    sub <- groups[[g]]
    cli::cli_inform(c(i = "Fitting decomposition for {by_chr} = {.val {g}}"))
    sub_design <- fit$design
    # Drop unsampled factor levels: within one group the `by` factor (and any
    # facet not present in this subset) collapses to a single sampled level.
    # Without this, tee_formula()'s nlevels() check keeps the degenerate
    # (1 | category) term and lme4 errors "grouping factors must have > 1
    # sampled level".
    sub_design$data <- droplevels(sub)
    sub_design$meta$N <- nlevels(droplevels(sub$item_id))
    sub_fit <- tee_decompose(sub_design,
                             link = fit$link,
                             heteroscedastic = fit$heteroscedastic,
                             include_cell_level = TRUE,
                             ci = "none")
    proj <- tee_dstudy(sub_fit, scenarios = scenarios)
    proj$scenarios[[by_chr]] <- g
    proj$scenarios
  })
  out_scen <- dplyr::bind_rows(results)

  structure(
    list(
      fit       = fit,
      scenarios = out_scen,
      baseline  = NULL,
      by        = by_chr,
      call      = match.call()
    ),
    class = c("tee_dstudy_grouped", "tee_dstudy")
  )
}

#' @export
print.tee_dstudy <- function(x, ...) {
  cli::cli_text("{.cls tee_dstudy}: {nrow(x$scenarios)} scenarios projected")
  if (!is.null(x$by)) cli::cli_text("Grouped by: {.val {x$by}}")
  print(x$scenarios)
  invisible(x)
}

#' Closed-form D-study variance: fixed temperature & fixed judge
#'
#' Case 1 of the paper's D-study: when both temperature and judge are
#' treated as fixed (operational case for a single deployed configuration),
#' the interaction terms `s2_ij` and `s2_pj` average over items / prompts
#' but not over the fixed facet, so they remain in the projection.
#'
#' @param vc Named list of variance components keyed by TEE label.
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
# canonical TLE labels. Missing components default to 0.
vc_named_list <- function(fit) {
  v <- fit$variance
  pull_label <- function(label) {
    x <- v$variance[v$tle_label == label]
    if (length(x) == 0L) 0 else x[1L]
  }
  # MMLU-style fits use SUT instead of judge as the model-side
  # design-sensitivity facet. Fall back to the SUT label set when the
  # judge label is absent so that vc_named_list returns a single
  # canonical view of the interaction structure regardless of facet name.
  has_judge <- "item x judge" %in% v$tle_label ||
               "judge model (design sensitivity)" %in% v$tle_label
  if (has_judge) {
    ij_label <- "item x judge"
    pj_label <- "prompt x judge"
    lambda_label <- "judge model (design sensitivity)"
  } else {
    ij_label <- "item x SUT"
    pj_label <- "prompt x SUT"
    lambda_label <- "SUT (design sensitivity)"
  }
  list(
    cat       = pull_label("between-category"),
    item      = pull_label("within-category item") + pull_label("item"),
    prompt    = pull_label("prompt"),
    ip        = pull_label("item x prompt"),
    ij        = pull_label(ij_label),
    pj        = pull_label(pj_label),
    it        = pull_label("item x temperature"),
    pt        = pull_label("prompt x temperature"),
    cell      = sum(v$variance[grepl("^cell-level", v$tle_label)]),
    replicate = pull_label("replicate noise"),
    # Fixed-effect design-sensitivity indices: when judge/SUT/temperature
    # are treated as random (i.e., averaged over a sample of M judges or
    # SUTs, or H temperatures, rather than fixed at one), the
    # corresponding population-variance index enters Var(theta-hat) as
    # lambda/M (judge or SUT) or tau/H (temperature). When the facet is
    # fixed in deployment (`fix_judge = TRUE` / `fix_temperature = TRUE`),
    # the index drops out.
    lambda    = pull_label(lambda_label),
    tau       = pull_label("temperature (design sensitivity)")
  )
}

# Closed-form Var(theta-hat). N=items, V=prompts, M=judges, H=temps, R=reps.
dstudy_total_variance <- function(vc, N, V, M, H, R,
                                  fix_judge, fix_temperature) {
  v_item   <- (vc$cat + vc$item) / N
  v_prompt <- vc$prompt / V
  v_ip     <- vc$ip / (N * V)

  v_ij <- if (fix_judge)       vc$ij / N else vc$ij / (N * M)
  v_pj <- if (fix_judge)       vc$pj / V else vc$pj / (V * M)
  v_it <- if (fix_temperature) vc$it / N else vc$it / (N * H)
  v_pt <- if (fix_temperature) vc$pt / V else vc$pt / (V * H)

  # Fixed-effect design-sensitivity terms. Default to 0 if absent (older
  # vc_named_list outputs that pre-date the lambda/tau slots).
  s2_lambda <- if (is.null(vc$lambda)) 0 else vc$lambda
  s2_tau    <- if (is.null(vc$tau))    0 else vc$tau
  v_lambda <- if (fix_judge)       0 else s2_lambda / M
  v_tau    <- if (fix_temperature) 0 else s2_tau    / H

  cell_div <- N * V *
    (if (fix_judge)       1L else M) *
    (if (fix_temperature) 1L else H)
  v_cell <- vc$cell / cell_div
  v_rep  <- vc$replicate / (cell_div * R)

  v_item + v_prompt + v_ip + v_ij + v_pj + v_it + v_pt +
    v_lambda + v_tau + v_cell + v_rep
}

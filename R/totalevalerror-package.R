#' totalevalerror: Variance Decomposition and D-Study for LLM Evaluation
#'
#' Decomposes uncertainty in LLM-based evaluation into a crossed random-effects
#' mixed model, projects standard errors under hypothetical evaluation designs
#' (D-study), and recommends pilot sizes and budget allocations.
#'
#' The package centres on six verbs:
#'   * [tee_design()] — wrap pilot data with extracted design facets.
#'   * [tee_decompose()] — fit the crossed random-effects model.
#'   * [tee_se()] — corrected standard error on the headline metric.
#'   * [tee_theta_ci()] — confidence interval on the headline metric.
#'   * [tee_dstudy()] — project Var(theta-hat) under hypothetical designs.
#'   * [tee_budget_allocate()] — optimal allocation under a fixed budget.
#'
#' See `vignette("totalevalerror")` for a 5-minute walkthrough.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

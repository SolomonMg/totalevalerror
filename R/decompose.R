#' Fit the variance decomposition
#'
#' Fits a crossed random-effects mixed model to a pilot dataset and extracts
#' the TEE variance components plus fixed-effect design-sensitivity indices.
#'
#' @param design A `tee_design` object.
#' @param formula Optional override; defaults to [tee_formula()] applied to
#'   `design`.
#' @param link "identity" (default, linear-probability model) or "logit"
#'   (GLMM). The LPM is the default because the D-study projection formulas
#'   require linear variance components; the GLMM is provided as a robustness
#'   check.
#' @param heteroscedastic "none" (default) or "stratified". When "stratified",
#'   fits a separate `lmer` per temperature stratum and reports per-stratum
#'   residual variances.
#' @param include_cell_level Include the 3-way+ cell-level epsilon term.
#' @param ci "none", "profile", or "bootstrap" — variance-component CIs.
#' @param ci_nsim Bootstrap replications.
#' @param parallel Parallel backend for the bootstrap.
#' @param control Optional `lme4::lmerControl()` override.
#'
#' @return An object of class `tee_decomp`.
#' @export
tee_decompose <- function(design,
                          formula = NULL,
                          link = c("identity", "logit"),
                          heteroscedastic = c("none", "stratified"),
                          include_cell_level = TRUE,
                          ci = c("none", "profile", "bootstrap"),
                          ci_nsim = 200,
                          parallel = c("snow", "multicore", "no"),
                          control = NULL) {
  stop("tee_decompose() is not yet implemented (Phase 3).", call. = FALSE)
}

#' Diagnose the cell-level vs replicate-noise split
#'
#' Fits the model with and without the 3-way+ cell-level term and reports how
#' much variance migrates between the two residuals. Useful for confirming
#' that the Tier-1 reducible bucket is well-identified.
#'
#' @param design A `tee_design` object.
#' @param ... Passed to [tee_decompose()].
#'
#' @return A tibble with per-component variance estimates from each fit.
#' @export
tee_decompose_diagnose <- function(design, ...) {
  stop("tee_decompose_diagnose() is not yet implemented (Phase 3).", call. = FALSE)
}

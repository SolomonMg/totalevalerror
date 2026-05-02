#' Build the lmer formula from a design
#'
#' Generates the crossed random-effects formula that matches the paper's DGP,
#' including the optional 3-way+ cell-level epsilon term.
#'
#' @param design A `tee_design` object.
#' @param include_cell_level Whether to include the 3-way+ cell-level epsilon
#'   term. Defaults to `TRUE`.
#'
#' @return A `formula` suitable for [lme4::lmer()].
#' @export
tee_formula <- function(design, include_cell_level = TRUE) {
  stop("tee_formula() is not yet implemented (Phase 2).", call. = FALSE)
}

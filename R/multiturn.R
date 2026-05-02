#' Multi-turn variance decomposition (reserved for v0.2)
#'
#' API surface reserved for the per-turn DGP from the paper's multi-turn
#' extension. Currently raises an error; will land in v0.2.
#'
#' @param design A `tee_design` object.
#' @param ... Reserved.
#'
#' @return Currently raises an error.
#' @export
tee_decompose_multiturn <- function(design, ...) {
  stop(
    "tee_decompose_multiturn() is reserved for v0.2 and not yet implemented.",
    call. = FALSE
  )
}

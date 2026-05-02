#' Build a design object from pilot data
#'
#' Wraps a long-format pilot data frame with extracted design facets — items,
#' prompts, judges, SUTs, temperatures, replications. The returned object is the
#' input to every other verb in the package.
#'
#' @param data    A data frame with one row per LLM call.
#' @param outcome Numeric column with the score (Likert 1 - 5 or binary 0 / 1).
#' @param item    Item / prompt-content identifier.
#' @param category Optional topic group; if `NULL` the DGP collapses to a single
#'   category.
#' @param prompt  Prompt-paraphrase (variant) identifier.
#' @param judge   Optional LLM-judge model. `NULL` for benchmarks with no judge,
#'   such as MMLU answer-key evaluation.
#' @param sut     Optional system-under-test model. `NULL` for fixed-SUT setups,
#'   such as AILuminate where the SUT is the evaluation target.
#' @param temperature Optional temperature factor.
#' @param replicate   Replication index within cell.
#' @param scoring "likert" or "binary".
#'
#' @return An object of class `tee_design`.
#' @export
tee_design <- function(data,
                       outcome,
                       item,
                       category = NULL,
                       prompt,
                       judge = NULL,
                       sut = NULL,
                       temperature = NULL,
                       replicate,
                       scoring = c("likert", "binary")) {
  stop("tee_design() is not yet implemented (Phase 2).", call. = FALSE)
}

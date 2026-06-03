#' Pilot data: AILuminate safety
#'
#' Subsample of the AILuminate safety pilot used in Messing (2026). One row
#' per LLM judge call. Categories are AILuminate hazard categories;
#' `outcome` is binary (1 = SAFE, 0 = UNSAFE).
#'
#' @format A tibble with the following columns:
#' \describe{
#'   \item{item_id}{Item identifier (factor).}
#'   \item{category}{AILuminate hazard category.}
#'   \item{variant_id}{Prompt-paraphrase variant index (integer).}
#'   \item{judge_model}{LLM judge model name.}
#'   \item{temperature}{Judge temperature.}
#'   \item{replication}{Replication index within cell (integer).}
#'   \item{outcome}{Binary outcome (0 / 1).}
#' }
#' @source Subsampled from the AILuminate v1.0 safety benchmark (MLCommons;
#'   Ghosh et al. 2025). The five judge-prompt framing variants are documented
#'   in `inst/prompts/safety_variants.md`. Rendered safety prompts are not
#'   bundled because they embed model responses to hazard prompts; render them
#'   from the template and the AILuminate items.
"safety_pilot"

#' Pilot data: MMLU
#'
#' Subsample of the MMLU pilot used in Messing (2026). Each row is one
#' system-under-test (SUT) call against an MMLU question; `outcome` is 1
#' for a correct answer and 0 otherwise.
#'
#' @format A tibble with the following columns:
#' \describe{
#'   \item{item_id}{MMLU question identifier.}
#'   \item{category}{MMLU subject area.}
#'   \item{variant_id}{Prompt-paraphrase variant.}
#'   \item{sut_model}{System-under-test model name.}
#'   \item{temperature}{SUT temperature.}
#'   \item{replication}{Replication index within cell.}
#'   \item{outcome}{Binary outcome (0 / 1).}
#' }
#' @source Subsampled from MMLU (Hendrycks et al. 2021). The exact rendered
#'   prompts for all five variants ship in `inst/extdata/variants_mmlu.csv`;
#'   the framing templates are in `inst/prompts/mmlu_variants.md`.
"mmlu_pilot"

#' Pilot data: Chatbot Arena Likert
#'
#' Subsample of the Chatbot Arena LLM-as-judge Likert pilot used in
#' Messing (2026). Each row is one judge's 1 - 5 score for one side of one
#' battle.
#'
#' @format A tibble with the following columns:
#' \describe{
#'   \item{item_id}{Battle identifier.}
#'   \item{category}{Battle category (Arena LLM categorization).}
#'   \item{side}{Which side of the battle ("a" or "b").}
#'   \item{variant_id}{Prompt-paraphrase variant.}
#'   \item{judge_model}{LLM judge model name.}
#'   \item{replication}{Replication index (Arena Likert has 1 score per cell).}
#'   \item{outcome}{Likert score 1 - 5.}
#' }
#' @source Subsampled from Chatbot Arena LLM-as-judge battles (Chiang et al.
#'   2024). The exact rendered prompts for all five Likert and pairwise variants
#'   ship in `inst/extdata/variants_likert.csv` and `variants_pairwise.csv`; the
#'   framing templates are in `inst/prompts/` (Likert, pairwise, and their
#'   chain-of-thought versions).
"arena_pilot"

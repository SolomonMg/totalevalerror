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
#' @source Subsampled from `data/processed/safety_clean.csv` in
#'   <https://github.com/SolomonMg/total_llm_error>.
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
#' @source Subsampled from `data/processed/mmlu_clean.csv`.
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
#' @source Subsampled from `data/processed/arena_likert_clean.csv`.
"arena_pilot"

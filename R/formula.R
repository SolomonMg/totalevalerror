#' Build the lmer formula from a design
#'
#' Generates the crossed random-effects formula that matches the paper's DGP.
#' Fixed effects: `judge_model`, `temperature`, `sut_model` when present.
#' Random effects: `category`, `item_id`, `variant_id`, two-way item / prompt
#' interactions with each fixed factor, and (when `include_cell_level = TRUE`)
#' a maximal-interaction cell-level term that captures any 3-way+ residual.
#'
#' Drops the cell-level term automatically when no fixed factors are present
#' (the maximal interaction would collapse to `item:variant`, which is already
#' a separate random effect).
#'
#' @param design A `tee_design` object.
#' @param include_cell_level Whether to include the 3-way+ cell-level epsilon
#'   term.
#'
#' @return A `formula` suitable for [lme4::lmer()].
#'
#' @examples
#' df <- data.frame(
#'   y = rnorm(60),
#'   item = rep(1:5, each = 12),
#'   variant = rep(rep(1:3, each = 4), 5),
#'   judge = rep(rep(1:2, each = 2), 15),
#'   rep = rep(1:2, 30)
#' )
#' des <- tee_design(df, outcome = y, item = item, prompt = variant,
#'                   judge = judge, replicate = rep, scoring = "likert")
#' tee_formula(des)
#' @export
tee_formula <- function(design, include_cell_level = TRUE) {
  if (!inherits(design, "tee_design")) {
    stop("`design` must be a `tee_design` object.", call. = FALSE)
  }

  has <- function(col) {
    if (!col %in% names(design$data)) return(FALSE)
    # Skip factors with <2 levels — they would trip lme4's contrasts handler
    # and don't carry information anyway.
    nlevels(design$data[[col]]) >= 2L
  }

  fixed_terms <- character()
  if (has("judge_model")) fixed_terms <- c(fixed_terms, "judge_model")
  if (has("temperature")) fixed_terms <- c(fixed_terms, "temperature")
  if (has("sut_model"))   fixed_terms <- c(fixed_terms, "sut_model")
  fixed_part <- if (length(fixed_terms)) paste(fixed_terms, collapse = " + ") else "1"

  random_terms <- character()
  if (has("category"))   random_terms <- c(random_terms, "(1 | category)")
  random_terms <- c(random_terms,
                    "(1 | item_id)",
                    "(1 | variant_id)",
                    "(1 | item_id:variant_id)")
  for (f in fixed_terms) {
    random_terms <- c(random_terms,
                      sprintf("(1 | item_id:%s)", f),
                      sprintf("(1 | variant_id:%s)", f))
  }

  # Cell-level (3-way+) term: max interaction of item, variant, and every fixed factor.
  if (include_cell_level && length(fixed_terms) >= 1L) {
    cell_term <- sprintf("(1 | %s)",
                         paste(c("item_id", "variant_id", fixed_terms), collapse = ":"))
    random_terms <- c(random_terms, cell_term)
  }

  rhs <- paste(c(fixed_part, random_terms), collapse = " + ")
  stats::as.formula(paste("outcome ~", rhs))
}

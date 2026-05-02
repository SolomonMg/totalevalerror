#' Build a design object from pilot data
#'
#' Wraps a long-format pilot data frame with extracted design facets: items,
#' prompt variants, judges, systems-under-test, temperatures, and
#' replications. The returned object is the input to every other verb in the
#' package.
#'
#' Pass column names with bare symbols (tidy evaluation), the same convention
#' used by `dplyr`. Optional facets default to `NULL`. Rows where `outcome`
#' is `NA` are dropped with a message.
#'
#' Counts of distinct levels are exposed in the returned object as
#' `meta$N` (items), `meta$V` (prompts), `meta$M` (judges), `meta$S` (SUTs),
#' `meta$H` (temperatures), and `meta$R` (max replicate index + 1).
#'
#' @param data A data frame.
#' @param outcome Numeric column with the score (Likert 1 - 5 or binary 0 / 1).
#' @param item Item / prompt-content identifier.
#' @param category Optional topic group; if `NULL`, the DGP collapses to a
#'   single category.
#' @param prompt Prompt-paraphrase (variant) identifier.
#' @param judge Optional LLM-judge model.
#' @param sut Optional system-under-test model.
#' @param temperature Optional temperature factor.
#' @param replicate Replication index within cell.
#' @param scoring "likert" or "binary".
#'
#' @return An object of class `tee_design`, which is a list with:
#'   * `data`: the cleaned data frame (factors coerced, NAs dropped).
#'   * `cols`: a named list of column names used for each facet (`NA` when
#'     absent).
#'   * `meta`: a list of facet counts and the balance flag.
#'   * `scoring`: the scoring method.
#'   * `call`: the matched call.
#'
#' @examples
#' df <- data.frame(
#'   y = rnorm(60),
#'   item = rep(1:5, each = 12),
#'   variant = rep(rep(1:3, each = 4), 5),
#'   judge = rep(rep(1:2, each = 2), 15),
#'   rep = rep(1:2, 30)
#' )
#' tee_design(df, outcome = y, item = item, prompt = variant,
#'            judge = judge, replicate = rep, scoring = "likert")
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
  scoring <- match.arg(scoring)

  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }

  q_outcome  <- rlang::enquo(outcome)
  q_item     <- rlang::enquo(item)
  q_cat      <- capture_optional(rlang::enquo(category))
  q_prompt   <- rlang::enquo(prompt)
  q_judge    <- capture_optional(rlang::enquo(judge))
  q_sut      <- capture_optional(rlang::enquo(sut))
  q_temp     <- capture_optional(rlang::enquo(temperature))
  q_rep      <- rlang::enquo(replicate)

  cols <- list(
    outcome     = rlang::as_label(q_outcome),
    item        = rlang::as_label(q_item),
    category    = if (is.null(q_cat))    NA_character_ else rlang::as_label(q_cat),
    prompt      = rlang::as_label(q_prompt),
    judge       = if (is.null(q_judge))  NA_character_ else rlang::as_label(q_judge),
    sut         = if (is.null(q_sut))    NA_character_ else rlang::as_label(q_sut),
    temperature = if (is.null(q_temp))   NA_character_ else rlang::as_label(q_temp),
    replicate   = rlang::as_label(q_rep)
  )

  outcome_vec <- rlang::eval_tidy(q_outcome, data)
  if (!is.numeric(outcome_vec)) {
    stop("`outcome` must be a numeric column.", call. = FALSE)
  }

  d <- tibble::tibble(
    outcome     = outcome_vec,
    item_id     = as_factor_safe(rlang::eval_tidy(q_item, data)),
    category    = if (is.null(q_cat))  NULL else as_factor_safe(pull_optional(data, q_cat)),
    variant_id  = as_factor_safe(rlang::eval_tidy(q_prompt, data)),
    judge_model = if (is.null(q_judge)) NULL else as_factor_safe(pull_optional(data, q_judge)),
    sut_model   = if (is.null(q_sut))   NULL else as_factor_safe(pull_optional(data, q_sut)),
    temperature = if (is.null(q_temp))  NULL else as_factor_safe(pull_optional(data, q_temp)),
    replication = as.integer(rlang::eval_tidy(q_rep, data))
  )

  n_in <- nrow(d)
  d <- d[!is.na(d$outcome), , drop = FALSE]
  if (nrow(d) < n_in) {
    cli::cli_inform(c(i = "Dropped {n_in - nrow(d)} row{?s} with `NA` outcome."))
  }
  if (nrow(d) == 0L) {
    stop("No rows remaining after dropping `NA` outcomes.", call. = FALSE)
  }

  meta <- list(
    n_obs   = nrow(d),
    N       = nlevels(d$item_id),
    C       = if ("category"    %in% names(d)) nlevels(d$category)    else NA_integer_,
    V       = nlevels(d$variant_id),
    M       = if ("judge_model" %in% names(d)) nlevels(d$judge_model) else NA_integer_,
    S       = if ("sut_model"   %in% names(d)) nlevels(d$sut_model)   else NA_integer_,
    H       = if ("temperature" %in% names(d)) nlevels(d$temperature) else NA_integer_,
    R       = max(d$replication, na.rm = TRUE)
  )

  meta$balanced <- check_balance(d, meta)

  structure(
    list(
      data    = d,
      cols    = cols,
      meta    = meta,
      scoring = scoring,
      call    = match.call()
    ),
    class = "tee_design"
  )
}

# Internal: warn when the design is not balanced (any cell has fewer
# observations than the modal cell). Returns TRUE/FALSE.
check_balance <- function(d, meta) {
  facets <- intersect(
    c("item_id", "category", "variant_id", "judge_model", "sut_model", "temperature"),
    names(d)
  )
  if (length(facets) < 2) return(TRUE)

  counts <- as.integer(table(d[, facets, drop = FALSE]))
  counts <- counts[counts > 0]
  balanced <- length(unique(counts)) == 1L
  if (!balanced) {
    cli::cli_warn(c(
      "!" = "Design is not balanced across facets {.field {facets}}.",
      i   = "Cell counts range from {min(counts)} to {max(counts)}; framework still applies, but D-study formulas assume balance."
    ))
  }
  balanced
}

#' @export
print.tee_design <- function(x, ...) {
  m <- x$meta
  facets <- c(
    if (!is.na(m$N))  sprintf("items=%d",   m$N),
    if (!is.na(m$C))  sprintf("cats=%d",    m$C),
    if (!is.na(m$V))  sprintf("prompts=%d", m$V),
    if (!is.na(m$M))  sprintf("judges=%d",  m$M),
    if (!is.na(m$S))  sprintf("SUTs=%d",    m$S),
    if (!is.na(m$H))  sprintf("temps=%d",   m$H),
    if (!is.na(m$R))  sprintf("reps=%d",    m$R)
  )
  cli::cli_text("{.cls tee_design}: {m$n_obs} rows | {paste(facets, collapse = ' ')} ({if (isTRUE(m$balanced)) 'balanced' else 'unbalanced'})")
  cli::cli_text("Scoring: {.val {x$scoring}}")
  invisible(x)
}

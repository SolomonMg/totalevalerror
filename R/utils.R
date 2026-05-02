# Internal helpers — not exported.

# Population variance, dividing by length not (length - 1). Used for
# fixed-effect design sensitivity indices per the paper's DGP. Sample
# variance would inflate by L / (L - 1); for L = 3 that is +50%.
pop_var <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) return(NA_real_)
  mean((x - mean(x))^2)
}

# Coerce a vector of identifiers to a factor. Returns input unchanged if
# already a factor (preserving level order).
as_factor_safe <- function(x) {
  if (is.factor(x)) x else factor(x)
}

# rlang helper: capture an optional column selector. Returns NULL when the
# user passed NULL; otherwise an unevaluated quosure suitable for
# `dplyr::pull(data, !!q)`.
capture_optional <- function(quo) {
  if (rlang::quo_is_null(quo) || rlang::quo_is_missing(quo)) NULL else quo
}

# Pull a column by quosure, or return NULL if the quosure is NULL.
pull_optional <- function(data, quo) {
  if (is.null(quo)) NULL else rlang::eval_tidy(quo, data)
}

# Count distinct non-NA values, returning NA_integer_ for NULL input. Used
# to produce design-facet counts.
n_distinct_or_na <- function(x) {
  if (is.null(x)) NA_integer_ else length(unique(x[!is.na(x)]))
}

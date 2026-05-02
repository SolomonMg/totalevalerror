# Internal helpers — not exported.

# Population variance, dividing by length not (length - 1). Used for
# fixed-effect design sensitivity indices per the paper's DGP. Sample
# variance would inflate by L / (L - 1); for L = 3 that is +50%.
pop_var <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) return(NA_real_)
  mean((x - mean(x))^2)
}

# Coerce a vector of identifiers to a factor without NA-ifying empty levels.
as_factor_safe <- function(x) {
  if (is.factor(x)) x else factor(x)
}

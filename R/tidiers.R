#' Tidy / glance / augment methods for TEE objects
#'
#' Implemented as S3 methods on the package's S3 classes. The `tidy`,
#' `glance`, and `augment` generics come from `broom` / `broom.mixed`; we
#' conditionally register methods on package load via [vctrs::s3_register()].
#'
#' @name tee_tidiers
NULL

#' Tidy a `tee_decomp`
#'
#' @param x A `tee_decomp`.
#' @param type "variance" (default), "fixed", or "design_sensitivity".
#' @param ... Ignored.
#' @return A tibble.
#' @export
tidy.tee_decomp <- function(x, type = c("variance", "fixed", "design_sensitivity"), ...) {
  type <- match.arg(type)
  switch(
    type,
    variance            = x$variance,
    fixed               = x$fixed_sensitivity,
    design_sensitivity  = x$variance[x$variance$tier == "pipeline-side", , drop = FALSE]
  )
}

#' Glance at a `tee_decomp`
#'
#' @param x A `tee_decomp`.
#' @param ... Ignored.
#' @return A 1-row tibble with design facets, theta-hat, and total variance.
#' @export
glance.tee_decomp <- function(x, ...) {
  m <- x$meta
  total_var <- sum(x$variance$variance)
  tibble::tibble(
    n_obs           = m$n_obs,
    N               = m$N,
    V               = m$V,
    M               = m$M,
    H               = m$H,
    R               = m$R,
    theta_hat       = m$theta_hat,
    var_total       = total_var,
    sd_total        = sqrt(total_var),
    link            = m$link,
    heteroscedastic = m$heteroscedastic
  )
}

#' Augment a `tee_decomp` with fitted values and residuals
#'
#' @param x A `tee_decomp`.
#' @param ... Ignored.
#' @return The original data with `.fitted` and `.resid` columns appended.
#' @export
augment.tee_decomp <- function(x, ...) {
  d <- x$design$data
  d$.fitted   <- stats::fitted(x$model)
  d$.resid    <- stats::resid(x$model)
  tibble::as_tibble(d)
}

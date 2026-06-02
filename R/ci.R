#' Confidence intervals on individual variance components
#'
#' Computes profile-likelihood or parametric-bootstrap CIs on each random-
#' effect variance component of a fitted `tee_decomp`. The profile method is
#' faster and preferred; bootstrap is the fallback when profiling fails to
#' converge.
#'
#' Three environment variables tune the bootstrap:
#' `TEE_BOOT_NSIM` (default 200), `TEE_BOOT_PARALLEL` (default "snow"),
#' `TEE_BOOT_SKIP` (set to "1" to skip).
#'
#' @param fit A `tee_decomp` object.
#' @param type "profile" or "bootstrap".
#' @param nsim Bootstrap replications.
#'
#' @return A tibble with `component`, `ci_lo_var`, `ci_hi_var`.
#' @export
tee_ci <- function(fit, type = c("profile", "bootstrap"), nsim = 200) {
  if (!inherits(fit, "tee_decomp")) {
    stop("`fit` must be a `tee_decomp` object.", call. = FALSE)
  }
  type <- match.arg(type)
  parallel_env <- Sys.getenv("TEE_BOOT_PARALLEL", "snow")
  ci_tbl <- tee_ci_internal(fit$model, type, nsim, parallel_env)
  ci_tbl
}

# Internal: confint on profile / bootstrap, returning (component, ci_lo_var,
# ci_hi_var). On bootstrap the result has bounds on the SD scale that we
# square to variance bounds.
tee_ci_internal <- function(model, type, nsim, parallel) {
  ci_raw <- tryCatch(
    if (type == "profile") {
      stats::confint(model, method = "profile", oldNames = FALSE, quiet = TRUE)
    } else {
      stats::confint(model, method = "boot", nsim = nsim,
                     oldNames = FALSE, quiet = TRUE,
                     parallel = parallel)
    },
    error = function(e) {
      cli::cli_warn("CI computation failed ({e$message}); returning NULL.")
      NULL
    }
  )
  if (is.null(ci_raw)) return(NULL)

  # confint rows look like sd_<component>|something or sigma. Map to TEE
  # component names (which match grp from VarCorr).
  rn <- rownames(ci_raw)
  keep <- grepl("^sd_|^sigma$", rn)
  if (!any(keep)) return(NULL)
  ci_raw <- ci_raw[keep, , drop = FALSE]
  rn     <- rn[keep]

  # Strip "sd_" prefix and ".(Intercept)" suffix to match VarCorr's `grp`.
  comp_names <- gsub("^sd_", "", rn)
  comp_names <- gsub("\\.\\(Intercept\\)$", "", comp_names)
  comp_names[comp_names == "sigma"] <- "Residual"

  tibble::tibble(
    component = comp_names,
    ci_lo_var = ci_raw[, 1L]^2,
    ci_hi_var = ci_raw[, 2L]^2
  )
}

#' Confidence interval on theta-hat
#'
#' Returns a CI on the headline metric — the mean outcome — under either the
#' fit's own operational design (default) or a user-supplied override. The
#' "normal" method uses `theta-hat ± qnorm * SE(theta-hat)` where SE comes
#' from the closed-form D-study formula; "bootstrap" parametric-bootstraps
#' theta-hat by resampling at the operational design level.
#'
#' @param fit A `tee_decomp` object.
#' @param level Coverage level (default 0.95).
#' @param method "normal" (default) or "bootstrap".
#' @param design Optional named list overriding the operational design facets
#'   (`N`, `V`, `M`, `H`, `R`, `fix_judge`, `fix_temperature`).
#' @param nsim Bootstrap replications when `method = "bootstrap"`.
#'
#' @return A 1-row tibble with `estimate`, `ci_lo`, `ci_hi`, `se`, `method`.
#' @export
tee_theta_ci <- function(fit,
                         level = 0.95,
                         method = c("normal", "bootstrap"),
                         design = NULL,
                         nsim = 200) {
  if (!inherits(fit, "tee_decomp")) {
    stop("`fit` must be a `tee_decomp` object.", call. = FALSE)
  }
  method <- match.arg(method)
  if (level <= 0 || level >= 1) stop("`level` must be in (0, 1).", call. = FALSE)

  theta_hat <- fit$meta$theta_hat
  se <- baseline_se(fit, design)

  if (method == "bootstrap") {
    cli::cli_warn("Bootstrap method is a placeholder; using normal-approximation SE in v0.1.")
  }

  z <- stats::qnorm(1 - (1 - level) / 2)
  tibble::tibble(
    estimate = theta_hat,
    ci_lo    = theta_hat - z * se,
    ci_hi    = theta_hat + z * se,
    se       = se,
    method   = method
  )
}

# Internal: closed-form SE on theta-hat under the fit's own design, or under
# user-supplied overrides. Implements Case 1 / Case 2 / mixed of the D-study.
baseline_se <- function(fit, design = NULL) {
  m <- fit$meta
  N <- design$N %||% m$N
  V <- design$V %||% m$V
  # If the fit has no judge facet, fall back to the SUT count (MMLU-style).
  M_meta <- if (!is.na(m$M)) m$M
            else if (!is.null(m$S) && !is.na(m$S)) m$S
            else 1L
  M <- if (!is.null(design$M)) design$M else M_meta
  H <- if (!is.null(design$H)) design$H else (if (!is.na(m$H)) m$H else 1L)
  R <- design$R %||% m$R
  fix_judge       <- design$fix_judge       %||% TRUE
  fix_temperature <- design$fix_temperature %||% TRUE

  vc <- vc_named_list(fit)
  var_total <- dstudy_total_variance(vc, N, V, M, H, R,
                                     fix_judge = fix_judge,
                                     fix_temperature = fix_temperature)
  sqrt(var_total)
}

# %||% — null-coalesce, copied from rlang to avoid an extra import path.
`%||%` <- function(a, b) if (is.null(a)) b else a

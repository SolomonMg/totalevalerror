#' Fit the variance decomposition
#'
#' Fits a crossed random-effects mixed model to a pilot dataset and extracts
#' the TEE variance components plus fixed-effect design-sensitivity indices.
#'
#' Random components: `category`, `item_id`, `variant_id`, two-way interactions
#' between item / prompt and each fixed factor, and (when present) a 3-way+
#' cell-level term that captures any residual non-additivity. Fixed
#' components: `judge_model`, `temperature`, `sut_model` — each summarised by
#' a population variance over factor levels (1 / L, not 1 / (L - 1); using the
#' sample variance for L = 3 inflates by 50%).
#'
#' Three modelling modes:
#' \describe{
#'   \item{`link = "identity"`}{Linear-probability model via [lme4::lmer()].
#'     The default; required for D-study formulas because the projection
#'     formulas are linear in variance components.}
#'   \item{`link = "logit"`}{GLMM via [lme4::glmer()] with `family = binomial`.
#'     Robustness check on binary outcomes; D-study projections do not apply
#'     directly because variance components on the logit scale are not
#'     additive on the probability scale.}
#'   \item{`heteroscedastic = "stratified"`}{Fits a separate `lmer` per
#'     temperature stratum and reports per-stratum residual variances. Use
#'     when the residual scales differ across temperature levels.}
#' }
#'
#' @param design A `tee_design` object.
#' @param formula Optional override; defaults to [tee_formula()] applied to
#'   `design`.
#' @param link "identity" (default) or "logit".
#' @param heteroscedastic "none" (default) or "stratified".
#' @param include_cell_level Include the 3-way+ cell-level epsilon term.
#' @param ci "none", "profile", or "bootstrap".
#' @param ci_nsim Bootstrap replications when `ci = "bootstrap"`.
#' @param parallel Parallel backend for the bootstrap.
#' @param control Optional `lme4::lmerControl()` override.
#'
#' @return An object of class `tee_decomp`.
#'
#' @examples
#' \dontrun{
#' set.seed(1)
#' sim <- tee_simulate(N = 30, V = 3, M = 2, R = 3,
#'                     variances = list(item = 0.2, prompt = 0.05,
#'                                      replicate = 0.1))
#' des <- tee_design(sim, outcome = y, item = item_id, prompt = variant_id,
#'                   judge = judge_model, replicate = replication,
#'                   scoring = "likert")
#' fit <- tee_decompose(des)
#' fit
#' }
#' @export
tee_decompose <- function(design,
                          formula = NULL,
                          link = c("identity", "logit"),
                          heteroscedastic = c("none", "stratified"),
                          include_cell_level = TRUE,
                          ci = c("none", "profile", "bootstrap"),
                          ci_nsim = 200,
                          parallel = c("snow", "multicore", "no"),
                          control = NULL) {
  if (!inherits(design, "tee_design")) {
    stop("`design` must be a `tee_design` object.", call. = FALSE)
  }
  link <- match.arg(link)
  heteroscedastic <- match.arg(heteroscedastic)
  ci <- match.arg(ci)
  parallel <- match.arg(parallel)
  if (is.null(formula)) formula <- tee_formula(design, include_cell_level = include_cell_level)
  if (is.null(control)) control <- lme4::lmerControl(optimizer = "bobyqa",
                                                     optCtrl = list(maxfun = 50000))

  d <- design$data

  # GLMM warning on near-saturated binary outcomes (LPM strain heuristic).
  if (link == "identity" && design$scoring == "binary") {
    warn_lpm_strain(d, design)
  }

  fit_main <- function(dat) {
    if (link == "identity") {
      lme4::lmer(formula, data = dat, REML = TRUE, control = control)
    } else {
      glmer_control <- lme4::glmerControl(optimizer = "bobyqa",
                                          optCtrl = list(maxfun = 50000))
      lme4::glmer(formula, data = dat, family = stats::binomial(),
                  control = glmer_control)
    }
  }

  if (heteroscedastic == "stratified") {
    if (!"temperature" %in% names(d)) {
      stop("`heteroscedastic = \"stratified\"` requires a `temperature` facet in `design`.",
           call. = FALSE)
    }
    # Within each stratum, temperature is constant — drop it from the formula
    # to avoid contrast-on-1-level errors. We rebuild the design without the
    # temperature facet so tee_formula() emits the right reduced formula.
    design_no_temp <- design
    design_no_temp$data$temperature <- NULL
    design_no_temp$cols$temperature <- NA_character_
    formula_strat <- tee_formula(design_no_temp,
                                 include_cell_level = include_cell_level)

    strata <- split(d, d$temperature)
    fit_strat <- function(dat) {
      if (link == "identity") {
        lme4::lmer(formula_strat, data = dat, REML = TRUE, control = control)
      } else {
        lme4::glmer(formula_strat, data = dat, family = stats::binomial(),
                    control = lme4::glmerControl(optimizer = "bobyqa",
                                                 optCtrl = list(maxfun = 50000)))
      }
    }
    fits <- lapply(strata, fit_strat)
    model <- fits[[1L]]
    residual_by_temperature <- vapply(fits, function(m) {
      sigma_hat <- attr(lme4::VarCorr(m), "sc")
      sigma_hat^2
    }, numeric(1))
    names(residual_by_temperature) <- names(strata)
    vc_clean <- extract_variance_components(model, design_no_temp)
    weights <- vapply(strata, nrow, integer(1))
    pooled_residual <- stats::weighted.mean(residual_by_temperature, weights)
    vc_clean$variance[vc_clean$component == "Residual"] <- pooled_residual
  } else {
    model <- fit_main(d)
    vc_clean <- extract_variance_components(model, design)
    residual_by_temperature <- NULL
  }

  fixed_sensitivity <- compute_fixed_sensitivity(model, design)

  vc_clean <- finalize_variance_components(vc_clean, fixed_sensitivity)

  ci_tbl <- if (ci == "none") NULL else tee_ci_internal(model, ci, ci_nsim, parallel)
  if (!is.null(ci_tbl)) vc_clean <- dplyr::left_join(vc_clean, ci_tbl, by = "component")

  meta <- design$meta
  meta$link <- link
  meta$heteroscedastic <- heteroscedastic
  meta$residual_by_temperature <- residual_by_temperature
  meta$REML <- link == "identity"
  meta$optimizer <- "bobyqa"
  meta$theta_hat <- mean(d$outcome, na.rm = TRUE)

  structure(
    list(
      design            = design,
      model             = model,
      variance          = vc_clean,
      fixed_sensitivity = fixed_sensitivity,
      ci                = ci_tbl,
      link              = link,
      heteroscedastic   = heteroscedastic,
      formula           = formula,
      scoring           = design$scoring,
      meta              = meta,
      call              = match.call()
    ),
    class = "tee_decomp"
  )
}

# Internal: extract VarCorr from a fitted model and label each component with
# the TEE convention. Returns a tibble (component, variance, sd, tle_label).
extract_variance_components <- function(model, design) {
  vc <- as.data.frame(lme4::VarCorr(model))
  vc <- tibble::tibble(
    component = vc$grp,
    variance  = vc$vcov,
    sd        = vc$sdcor
  )
  has_cat <- "category" %in% names(design$data)
  vc$tle_label <- vapply(vc$component, tle_label_for,
                         FUN.VALUE = character(1L), has_category = has_cat)
  vc
}

# Map a raw lme4 component name to a TEE label.
tle_label_for <- function(comp, has_category) {
  base <- c(
    "category"    = "between-category",
    "item_id"     = if (has_category) "within-category item" else "item",
    "variant_id"  = "prompt",
    "Residual"    = "replicate noise"
  )
  if (comp %in% names(base)) return(unname(base[comp]))
  if (grepl(":", comp, fixed = TRUE)) {
    parts <- strsplit(comp, ":", fixed = TRUE)[[1L]]
    nice  <- vapply(parts, function(p) {
      switch(p,
        item_id     = "item",
        variant_id  = "prompt",
        judge_model = "judge",
        sut_model   = "SUT",
        temperature = "temperature",
        category    = "category",
        p
      )
    }, character(1L))
    if (length(nice) >= 3) {
      return(sprintf("cell-level (%s)", paste(nice, collapse = " x ")))
    }
    return(paste(nice, collapse = " x "))
  }
  comp
}

# Internal: extract design-sensitivity indices (population variance over
# factor levels) for fixed effects.
compute_fixed_sensitivity <- function(model, design) {
  fe <- lme4::fixef(model)
  intercept <- fe["(Intercept)"]
  factors <- intersect(c("judge_model", "temperature", "sut_model"),
                       names(design$data))
  rows <- lapply(factors, function(f) {
    contrasts <- fe[grepl(paste0("^", f), names(fe)) & names(fe) != "(Intercept)"]
    if (length(contrasts) == 0L) return(NULL)
    cell_means <- c(intercept, intercept + contrasts)
    sigma2 <- pop_var(cell_means)
    label <- switch(f,
      judge_model = "judge model (design sensitivity)",
      temperature = "temperature (design sensitivity)",
      sut_model   = "SUT (design sensitivity)"
    )
    tibble::tibble(
      component = sprintf("%s (fixed)", f),
      variance  = sigma2,
      sd        = sqrt(sigma2),
      tle_label = label
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) return(tibble::tibble(component = character(),
                                                variance = numeric(),
                                                sd = numeric(),
                                                tle_label = character()))
  do.call(rbind, rows)
}

# Internal: combine random + fixed variance components, clamp negatives,
# compute pct_total, tag tier.
finalize_variance_components <- function(vc_random, vc_fixed) {
  vc <- dplyr::bind_rows(vc_random, vc_fixed)
  vc$variance <- pmax(vc$variance, 0)
  total <- sum(vc$variance)
  vc$pct_total <- if (total > 0) round(100 * vc$variance / total, 2) else 0
  vc$tier <- ifelse(grepl("design sensitivity", vc$tle_label),
                    "pipeline-side", "model-side")
  vc[order(-vc$variance), , drop = FALSE]
}

# Internal: heuristic warning on LPM strain when binary outcome cell means
# are near 0 or 1.
warn_lpm_strain <- function(d, design) {
  cell_factors <- intersect(
    c("item_id", "variant_id", "judge_model", "sut_model", "temperature"),
    names(d)
  )
  if (length(cell_factors) == 0L) return(invisible())
  cell_means <- stats::aggregate(d$outcome,
                                  by = d[, cell_factors, drop = FALSE],
                                  FUN = mean)$x
  near_saturated <- mean(cell_means < 0.05 | cell_means > 0.95)
  if (near_saturated > 0.20) {
    cli::cli_warn(c(
      "!" = "{round(100 * near_saturated)}% of cells have mean outcome near 0 or 1.",
      i   = "Linear-probability model may be unreliable. Consider {.code link = \"logit\"} as a robustness check."
    ))
  }
  invisible()
}

#' @export
print.tee_decomp <- function(x, ...) {
  m <- x$meta
  cli::cli_text("{.cls tee_decomp}: {x$scoring} scoring, link = {.val {x$link}}, heteroscedastic = {.val {x$heteroscedastic}}")
  cli::cli_text("Theta-hat: {.val {round(m$theta_hat, 4)}} | n_obs = {m$n_obs}")
  print(x$variance)
  invisible(x)
}

#' Diagnose the cell-level vs replicate-noise split
#'
#' Fits the model with and without the 3-way+ cell-level term and reports how
#' much variance migrates between the two residual components. When the
#' cell-level term is omitted, its variance collapses into the replicate
#' residual, biasing the Tier-1 reducible bucket upward.
#'
#' @param design A `tee_design` object.
#' @param ... Passed to [tee_decompose()].
#'
#' @return A tibble with columns `model`, `cell_level_var`, `replicate_var`,
#'   `total_residual`.
#' @export
tee_decompose_diagnose <- function(design, ...) {
  if (!inherits(design, "tee_design")) {
    stop("`design` must be a `tee_design` object.", call. = FALSE)
  }
  with_cell    <- tee_decompose(design, include_cell_level = TRUE,  ...)
  without_cell <- tee_decompose(design, include_cell_level = FALSE, ...)

  pull_var <- function(fit, label) {
    v <- fit$variance$variance[fit$variance$tle_label == label]
    if (length(v) == 0L) NA_real_ else v
  }

  cell_with <- pull_var(with_cell, "cell-level (item x prompt x judge)")
  if (is.na(cell_with)) {
    # Try other cell-level label patterns
    cell_label <- with_cell$variance$tle_label[grepl("^cell-level", with_cell$variance$tle_label)]
    cell_with <- if (length(cell_label)) pull_var(with_cell, cell_label[1L]) else NA_real_
  }
  rep_with    <- pull_var(with_cell, "replicate noise")
  rep_without <- pull_var(without_cell, "replicate noise")

  tibble::tibble(
    model            = c("with_3way_term", "without_3way_term"),
    cell_level_var   = c(cell_with, NA_real_),
    replicate_var    = c(rep_with,  rep_without),
    total_residual   = c(sum(c(cell_with, rep_with), na.rm = TRUE), rep_without)
  )
}

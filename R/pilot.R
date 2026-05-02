#' Recommend pilot sizes for a target variance-component precision
#'
#' Given a target relative precision on variance-component estimates, returns
#' the minimum facet sizes that achieve it. Uses the chi-squared
#' approximation for REML-estimated variance components: a one-way component
#' estimated from `df` independent units has approximate relative SE
#' `sqrt(2 / df)`.
#'
#' Inverting that bound, achieving relative SE at most `p` requires
#' `df >= 2 / p^2`. For example, 20% relative precision needs df >= 50;
#' 10% needs df >= 200.
#'
#' For two-way interactions, the bound applies to the product of the two
#' facet counts (e.g., `item x judge` requires `N * M >= df_min`). For
#' replicate noise, the bound applies to the total cell count
#' `N * V * M * H * R`.
#'
#' @param target_se_pct Target relative SE on variance components, expressed
#'   as a percentage. Default 20 (i.e., 20%).
#' @param prior_vc Reserved; currently unused. The chi-squared bound is
#'   distribution-only and does not depend on prior values.
#' @param facets Which facets to size. Defaults to the four most common.
#'
#' @return A tibble with columns `facet`, `df_min`, `recommendation`.
#'
#' @examples
#' tee_pilot_recommend(target_se_pct = 20)
#' tee_pilot_recommend(target_se_pct = 10)
#' @export
tee_pilot_recommend <- function(target_se_pct = 20,
                                prior_vc = NULL,
                                facets = c("item", "prompt", "judge", "replicate")) {
  if (!is.numeric(target_se_pct) || target_se_pct <= 0) {
    stop("`target_se_pct` must be a positive number.", call. = FALSE)
  }
  facets <- match.arg(facets, several.ok = TRUE)
  p <- target_se_pct / 100
  df_min <- ceiling(2 / p^2)

  rec <- function(facet) {
    switch(
      facet,
      item      = sprintf("N >= %d items", df_min + 1),
      prompt    = sprintf("V >= %d prompt variants", df_min + 1),
      judge     = sprintf(
        "M >= %d judges (rarely feasible; consider M = 3 - 5 with item x judge interaction tracked)",
        df_min + 1
      ),
      replicate = sprintf("Total cells N x V x M x H x R >= %d", df_min)
    )
  }

  tibble::tibble(
    facet          = facets,
    df_min         = df_min,
    recommendation = vapply(facets, rec, character(1))
  )
}

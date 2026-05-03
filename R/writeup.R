#' One-paragraph writeup populated from a fit
#'
#' Generates a paragraph summary of a TEE decomposition suitable for pasting
#' into a paper, blog post, or report. Pulls the headline numbers (theta-hat,
#' naive vs TEE SE, dominant variance components, top D-study lever) directly
#' from the fitted object.
#'
#' Two styles:
#' \describe{
#'   \item{paper}{Terse, numerical, no hedging. ~3 sentences.}
#'   \item{blog}{Longer, with framing and a "what to do next" sentence.
#'     ~5 sentences.}
#' }
#'
#' @param fit A `tee_decomp` object.
#' @param style "paper" or "blog".
#'
#' @return A character string.
#'
#' @examples
#' \dontrun{
#' tee_writeup(fit, style = "paper")
#' }
#' @export
tee_writeup <- function(fit, style = c("paper", "blog")) {
  if (!inherits(fit, "tee_decomp")) {
    stop("`fit` must be a `tee_decomp` object.", call. = FALSE)
  }
  style <- match.arg(style)
  m <- fit$meta
  v <- fit$variance

  v_sorted <- v[order(-v$pct_total), ]
  top1 <- v_sorted[1L, ]
  top2 <- if (nrow(v_sorted) >= 2L) v_sorted[2L, ] else NULL

  naive <- tee_naive_se(fit$design)$median_se
  se_tee <- baseline_se(fit, NULL)
  underestimate_pct <- 100 * (1 - naive / se_tee)

  proj <- tee_dstudy(fit)
  best <- proj$scenarios[which.max(proj$scenarios$reduction_pct), ]

  facet_str <- sprintf("N=%d, V=%s, M=%s, R=%d",
                       m$N,
                       if (is.na(m$V)) "1" else m$V,
                       if (is.na(m$M)) "1" else m$M,
                       m$R)

  top_str <- sprintf("%s (%.1f%%)", top1$tle_label, top1$pct_total)
  second_str <- if (!is.null(top2)) {
    sprintf(", followed by %s (%.1f%%)", top2$tle_label, top2$pct_total)
  } else ""

  if (style == "paper") {
    sprintf(
      paste0("On %s pilot data (%s), TEE corrects the naive SE of %.4f upward to %.4f, ",
             "a %.0f%% underestimate. The dominant variance source is %s%s. ",
             "D-study projection indicates that the largest single design improvement is ",
             "%s, reducing Var(theta-hat) by %.1f%%."),
      fit$scoring, facet_str, naive, se_tee, underestimate_pct,
      top_str, second_str, best$scenario, best$reduction_pct
    )
  } else {
    sprintf(
      paste0("We applied the Total Eval Error framework to a %s pilot (%s). ",
             "The naive standard error reported by collapsing across pipeline factors is %.4f, ",
             "but TEE places the corrected SE at %.4f - a %.0f%% underestimate of the true uncertainty. ",
             "The variance is dominated by %s%s. ",
             "If we want to shrink the SE further, the largest single lever available is ",
             "%s, which reduces Var(theta-hat) by %.1f%% relative to the baseline design."),
      fit$scoring, facet_str, naive, se_tee, underestimate_pct,
      top_str, second_str, best$scenario, best$reduction_pct
    )
  }
}

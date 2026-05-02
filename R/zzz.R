.onLoad <- function(libname, pkgname) {
  # Conditional ggplot2 autoplot registration — to be wired in Phase 7.
  # vctrs::s3_register("ggplot2::autoplot", "tee_decomp")
  # vctrs::s3_register("ggplot2::autoplot", "tee_dstudy")
  # vctrs::s3_register("ggplot2::autoplot", "tee_budget")
  invisible()
}

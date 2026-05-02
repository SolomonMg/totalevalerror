.onLoad <- function(libname, pkgname) {
  if (requireNamespace("generics", quietly = TRUE)) {
    vctrs::s3_register("generics::tidy",     "tee_decomp")
    vctrs::s3_register("generics::glance",   "tee_decomp")
    vctrs::s3_register("generics::augment",  "tee_decomp")
  }
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    # Phase 7 will fill these in.
    # vctrs::s3_register("ggplot2::autoplot", "tee_decomp")
    # vctrs::s3_register("ggplot2::autoplot", "tee_dstudy")
    # vctrs::s3_register("ggplot2::autoplot", "tee_budget")
  }
  invisible()
}

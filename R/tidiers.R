#' Tidy / glance / augment methods for TEE objects
#'
#' Implemented as S3 methods on the package's S3 classes. The `tidy`, `glance`,
#' and `augment` generics come from `broom`/`broom.mixed`; we conditionally
#' register methods at load time via [vctrs::s3_register()] so that `broom`
#' itself is only a soft dependency.
#'
#' @name tee_tidiers
NULL

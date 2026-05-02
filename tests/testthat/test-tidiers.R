test_that("tidy/glance/augment work on a fitted tee_decomp", {
  skip_on_cran()
  skip_if_not_installed("generics")

  df <- make_sim(N = 15, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))

  td <- generics::tidy(fit)
  expect_true(is.data.frame(td))
  expect_true(all(c("component", "variance", "tle_label") %in% names(td)))

  gl <- generics::glance(fit)
  expect_equal(nrow(gl), 1L)
  expect_true("theta_hat" %in% names(gl))

  aug <- generics::augment(fit)
  expect_true(all(c(".fitted", ".resid") %in% names(aug)))
  expect_equal(nrow(aug), nrow(des$data))
})

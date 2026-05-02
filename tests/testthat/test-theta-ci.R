test_that("tee_theta_ci returns a 1-row tibble centered on theta-hat", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))

  ci <- tee_theta_ci(fit, level = 0.95)
  expect_equal(nrow(ci), 1L)
  expect_equal(ci$estimate, mean(df$y), tolerance = 1e-8)
  expect_lt(ci$ci_lo, ci$estimate)
  expect_gt(ci$ci_hi, ci$estimate)
  expect_gt(ci$se, 0)
})

test_that("tee_theta_ci wider at level=0.99 than level=0.90", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  ci90 <- tee_theta_ci(fit, level = 0.90)
  ci99 <- tee_theta_ci(fit, level = 0.99)
  expect_gt(ci99$ci_hi - ci99$ci_lo, ci90$ci_hi - ci90$ci_lo)
})

test_that("tee_theta_ci accepts design overrides", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  ci_default <- tee_theta_ci(fit)
  ci_2x <- tee_theta_ci(fit, design = list(N = 40))
  # Doubling N should shrink SE.
  expect_lt(ci_2x$se, ci_default$se)
})

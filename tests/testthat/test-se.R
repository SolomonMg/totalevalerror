test_that("tee_se returns a positive scalar at the fit's design", {
  skip_on_cran()
  df <- make_sim(N = 15, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  se <- tee_se(fit)
  expect_type(se, "double")
  expect_length(se, 1L)
  expect_gt(se, 0)
})

test_that("tee_se with design_grid returns a tibble of SEs", {
  skip_on_cran()
  df <- make_sim(N = 15, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  grid <- tibble::tibble(N = c(20L, 40L, 80L), V = 3L, M = 2L, H = 1L, R = 2L,
                         fix_judge = TRUE, fix_temperature = TRUE)
  out <- tee_se(fit, design_grid = grid)
  expect_equal(nrow(out), 3L)
  expect_true("se" %in% names(out))
  # SE should decrease as N grows.
  expect_true(all(diff(out$se) < 0))
})

test_that("tee_naive_se returns per-config SEs", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 3)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  out <- tee_naive_se(des)
  expect_true(out$n_configs > 0L)
  expect_gt(out$median_se, 0)
})

test_that("tee_se_compare reports underestimation pct", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 3)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  cmp <- tee_se_compare(fit, tee_naive_se(des))
  expect_true("underestimate_pct" %in% names(cmp))
  expect_true("ratio" %in% names(cmp))
})

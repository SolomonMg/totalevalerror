test_that("tee_simulate returns a balanced long-format tibble", {
  sim <- tee_simulate(N = 10, V = 3, M = 2, H = 2, R = 2, seed = 1)
  expect_equal(nrow(sim), 10 * 3 * 2 * 2 * 2)
  expect_setequal(
    names(sim),
    c("item_id", "variant_id", "judge_model", "temperature", "replication", "outcome")
  )
  expect_true(is.factor(sim$item_id))
  expect_true(is.numeric(sim$outcome))
})

test_that("tee_simulate is deterministic given a seed", {
  s1 <- tee_simulate(N = 5, V = 2, M = 1, H = 1, R = 2, seed = 7)
  s2 <- tee_simulate(N = 5, V = 2, M = 1, H = 1, R = 2, seed = 7)
  expect_equal(s1$outcome, s2$outcome)
})

test_that("tee_simulate binary scoring returns 0/1 outcomes", {
  sim <- tee_simulate(N = 10, V = 2, M = 1, R = 2, scoring = "binary", seed = 1)
  expect_setequal(unique(sim$outcome), c(0L, 1L))
})

test_that("tee_decompose roundtrip on tee_simulate is consistent", {
  skip_on_cran()
  sim <- tee_simulate(N = 30, V = 4, M = 2, H = 1, R = 3, seed = 1,
                      variances = list(item = 0.30, prompt = 0.05,
                                       item_x_prompt = 0.04,
                                       item_x_judge = 0.10,
                                       cell_level = 0.02,
                                       replicate = 0.15))
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, judge = judge_model,
                    replicate = replication, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  pull <- function(lbl) fit$variance$variance[fit$variance$tle_label == lbl][1L]
  expect_lt(abs(pull("item") - 0.30) / 0.30, 0.5)
  expect_lt(abs(pull("replicate noise") - 0.15) / 0.15, 0.5)
})

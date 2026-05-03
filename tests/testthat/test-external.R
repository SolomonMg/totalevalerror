test_that("tee_external_corr returns spearman and kendall with CIs", {
  skip_on_cran()
  sim <- tee_simulate(N = 30, V = 3, M = 2, H = 1, R = 2, seed = 1)
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, judge = judge_model,
                    replicate = replication, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))

  # Build ground truth perfectly correlated with item-level mean.
  d <- fit$design$data
  truth <- stats::aggregate(d$outcome, by = list(item_id = d$item_id),
                            FUN = mean)
  names(truth)[2L] <- "truth"

  out <- tee_external_corr(fit, ground_truth = truth, by = "item_id")
  expect_equal(nrow(out), 2L)
  expect_setequal(out$metric, c("spearman", "kendall"))
  expect_true(all(out$estimate > 0.5))  # noisy roundtrip but mostly correlated
})

test_that("tee_external_corr accepts a named numeric vector", {
  skip_on_cran()
  sim <- tee_simulate(N = 20, V = 2, M = 1, R = 2, seed = 2)
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, replicate = replication,
                    scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  d <- fit$design$data
  truth_named <- tapply(d$outcome, d$item_id, mean)
  out <- tee_external_corr(fit, ground_truth = truth_named, by = "item_id")
  expect_equal(nrow(out), 2L)
})

test_that("tee_external_corr errors on too-few items", {
  skip_on_cran()
  sim <- tee_simulate(N = 5, V = 2, M = 1, R = 2, seed = 3)
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, replicate = replication,
                    scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  truth <- data.frame(item_id = c("99"), truth = 0)
  expect_error(tee_external_corr(fit, truth), "Fewer than 3")
})

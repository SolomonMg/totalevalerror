test_that("autoplot.tee_decomp returns a ggplot for forest and theta_ci", {
  skip_on_cran()
  skip_if_not_installed("ggplot2")
  sim <- tee_simulate(N = 20, V = 3, M = 2, R = 2, seed = 1)
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, judge = judge_model,
                    replicate = replication, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))

  p1 <- ggplot2::autoplot(fit, type = "forest")
  expect_s3_class(p1, "ggplot")

  p2 <- ggplot2::autoplot(fit, type = "theta_ci")
  expect_s3_class(p2, "ggplot")
})

test_that("autoplot.tee_dstudy returns a ggplot for waterfall", {
  skip_on_cran()
  skip_if_not_installed("ggplot2")
  sim <- tee_simulate(N = 20, V = 3, M = 2, R = 2, seed = 1)
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, judge = judge_model,
                    replicate = replication, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  proj <- tee_dstudy(fit)
  p <- ggplot2::autoplot(proj)
  expect_s3_class(p, "ggplot")
})

test_that("autoplot.tee_budget returns a ggplot for frontier", {
  skip_on_cran()
  skip_if_not_installed("ggplot2")
  sim <- tee_simulate(N = 20, V = 3, M = 2, R = 2, seed = 1)
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, judge = judge_model,
                    replicate = replication, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  alloc <- tee_budget_allocate(fit, budget = 600, n_pool = 200)
  p <- ggplot2::autoplot(alloc, type = "frontier")
  expect_s3_class(p, "ggplot")
})

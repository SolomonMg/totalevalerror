test_that("tee_budget_allocate finds an optimum and returns the full grid", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  alloc <- tee_budget_allocate(fit, budget = 600, n_pool = 200, v_max = 5L, r_max = 5L)
  expect_s3_class(alloc, "tee_budget")
  expect_equal(nrow(alloc$optimum), 1L)
  expect_gt(nrow(alloc$grid), 5L)
  # Optimum SE should not exceed any other grid SE.
  expect_equal(alloc$optimum$se_total, min(alloc$grid$se_total))
})

test_that("tee_budget_allocate respects pool cap", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  alloc <- tee_budget_allocate(fit, budget = 1e6, n_pool = 50L, v_max = 5L, r_max = 5L)
  expect_lte(alloc$optimum$N, 50L)
})

test_that("tee_budget_allocate honors heterogeneous-cost tibble", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))

  cheap <- tibble::tibble(judge_model = "x", cost_per_call = 0.5)
  pricey <- tibble::tibble(judge_model = "x", cost_per_call = 5)
  a_cheap  <- tee_budget_allocate(fit, budget = 600, cost_per_call = cheap,  n_pool = 1000)
  a_pricey <- tee_budget_allocate(fit, budget = 600, cost_per_call = pricey, n_pool = 1000)
  # Cheaper calls -> more total calls -> more items -> smaller SE.
  expect_gt(a_cheap$optimum$total_calls, a_pricey$optimum$total_calls)
  expect_gt(a_pricey$optimum$se_total, a_cheap$optimum$se_total)
})

test_that("tee_budget_allocate errors on impossible budget", {
  skip_on_cran()
  df <- make_sim(N = 15, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  # cost = 1, budget = 0.5 - cannot afford even 2 items at any (V, R).
  expect_error(tee_budget_allocate(fit, budget = 0.5, cost_per_call = 1),
               "Budget too small")
})

test_that("tee_budget_compare returns one row per strategy with TEE best", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  cmp <- tee_budget_compare(fit, budget = 600, n_pool = 200)
  expect_setequal(cmp$strategy, c("naive", "standard", "tee"))
  # TEE should not be worse than naive or standard.
  tee_se <- cmp$se_total[cmp$strategy == "tee"]
  expect_lte(tee_se, cmp$se_total[cmp$strategy == "naive"])
  expect_lte(tee_se, cmp$se_total[cmp$strategy == "standard"])
})

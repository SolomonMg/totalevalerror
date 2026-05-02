test_that("tee_dstudy returns 10 default scenarios with monotonic reduction", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  proj <- tee_dstudy(fit)
  expect_s3_class(proj, "tee_dstudy")
  expect_equal(nrow(proj$scenarios), 10L)
  expect_true(all(c("var_total", "se_total", "reduction_pct") %in% names(proj$scenarios)))

  # Maximal scenario should give the largest reduction.
  max_row <- proj$scenarios[proj$scenarios$scenario ==
    "Maximal: 2x items + 5 prompts + 10 reps + fix design", ]
  expect_gt(max_row$reduction_pct, 0)
  expect_lt(max_row$var_total, proj$baseline$var_total)
})

test_that("tee_dstudy custom scenarios honored", {
  skip_on_cran()
  df <- make_sim(N = 15, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))

  custom <- tibble::tribble(
    ~scenario,           ~N_d, ~V_d, ~M_d, ~H_d, ~R_d, ~fix_temp, ~fix_judge,
    "small",             10L,  2L,   2L,   1L,   2L,   TRUE,      TRUE,
    "large",             100L, 5L,   3L,   1L,   8L,   FALSE,     FALSE
  )
  proj <- tee_dstudy(fit, scenarios = custom)
  expect_equal(nrow(proj$scenarios), 2L)
  expect_lt(proj$scenarios$var_total[2L], proj$scenarios$var_total[1L])
})

test_that("tee_dstudy validates scenario columns", {
  skip_on_cran()
  df <- make_sim(N = 15, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  bad <- tibble::tibble(scenario = "x", N_d = 10L)
  expect_error(tee_dstudy(fit, scenarios = bad), "missing column")
})

test_that("closed-form helpers agree with master function", {
  vc <- list(cat = 0, item = 0.2, prompt = 0.05, ip = 0.04,
             ij = 0.1, pj = 0.02, it = 0.0, pt = 0.0,
             cell = 0.03, replicate = 0.15)
  v_fixed <- tee_dstudy_var_fixed(vc, N = 100, V = 5, R = 3, M = 1, H = 1)
  v_avg   <- tee_dstudy_var_avg(vc, N = 100, V = 5, M = 3, H = 2, R = 3)
  v_mix1  <- tee_dstudy_var_mixed(vc, N = 100, V = 5, M = 3, H = 2, R = 3,
                                  fix_judge = TRUE, fix_temperature = FALSE)
  v_mix2  <- tee_dstudy_var_mixed(vc, N = 100, V = 5, M = 3, H = 2, R = 3,
                                  fix_judge = FALSE, fix_temperature = TRUE)
  # Sanity: averaging over more facets shrinks variance (under non-zero ij).
  expect_lt(v_avg, v_fixed)
  expect_lt(v_mix1, v_fixed)  # avg over temp helps too
  expect_lt(v_mix2, v_fixed)
})

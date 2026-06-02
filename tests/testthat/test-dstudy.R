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

test_that("design-sensitivity lambda/M term enters when judge is averaged", {
  # When fix_judge = FALSE and lambda > 0, the projection picks up lambda/M.
  # When fix_judge = TRUE, the term drops. Same for tau / temperature.
  vc_with    <- list(cat = 0, item = 0.2, prompt = 0.05, ip = 0,
                     ij = 0, pj = 0, it = 0, pt = 0,
                     cell = 0, replicate = 0,
                     lambda = 0.30, tau = 0.10)
  vc_without <- list(cat = 0, item = 0.2, prompt = 0.05, ip = 0,
                     ij = 0, pj = 0, it = 0, pt = 0,
                     cell = 0, replicate = 0,
                     lambda = 0,    tau = 0)

  # Fix judge AND temperature: lambda/M and tau/H both drop. With and without
  # the fixed-effect indices should agree.
  v_fix_w  <- tee_dstudy_var_fixed(vc_with,    N = 100, V = 5, R = 3, M = 1, H = 1)
  v_fix_wo <- tee_dstudy_var_fixed(vc_without, N = 100, V = 5, R = 3, M = 1, H = 1)
  expect_equal(v_fix_w, v_fix_wo)

  # Average over M = 3 judges and H = 2 temps: with-lambda picks up
  # 0.30/3 + 0.10/2 = 0.15 of extra variance.
  v_avg_w  <- tee_dstudy_var_avg(vc_with,    N = 100, V = 5, M = 3, H = 2, R = 3)
  v_avg_wo <- tee_dstudy_var_avg(vc_without, N = 100, V = 5, M = 3, H = 2, R = 3)
  expect_equal(v_avg_w - v_avg_wo, 0.30 / 3 + 0.10 / 2, tolerance = 1e-12)

  # Mixed: fix judge only -> lambda drops but tau/H stays.
  v_mix_w <- tee_dstudy_var_mixed(vc_with, N = 100, V = 5, M = 3, H = 2, R = 3,
                                  fix_judge = TRUE, fix_temperature = FALSE)
  v_mix_wo <- tee_dstudy_var_mixed(vc_without, N = 100, V = 5, M = 3, H = 2, R = 3,
                                   fix_judge = TRUE, fix_temperature = FALSE)
  expect_equal(v_mix_w - v_mix_wo, 0.10 / 2, tolerance = 1e-12)

  # Default to 0 when slot absent (backward compatibility for callers
  # that built vc lists by hand without lambda / tau).
  vc_legacy <- vc_without
  vc_legacy$lambda <- NULL
  vc_legacy$tau    <- NULL
  v_legacy <- tee_dstudy_var_avg(vc_legacy, N = 100, V = 5, M = 3, H = 2, R = 3)
  expect_equal(v_legacy, v_avg_wo)
})

test_that("vc_named_list pulls lambda and tau from a fitted decomposition", {
  skip_on_cran()
  # judge_means = c(-0.5, 0, 0.5) gives a non-trivial fixed-effect
  # judge-model design-sensitivity index.
  df <- make_sim(N = 30, V = 3, M = 3, R = 2,
                 judge_means = c(-0.5, 0, 0.5))
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  vc <- totalevalerror:::vc_named_list(fit)
  expect_true("lambda" %in% names(vc))
  expect_true("tau"    %in% names(vc))
  # judge_means span 1.0 with 3 levels => population variance > 0.
  expect_gt(vc$lambda, 0)
  # tau is 0 because the make_sim helper does not include a temperature
  # facet; vc_named_list returns 0 when the row is absent.
  expect_equal(vc$tau, 0)
})

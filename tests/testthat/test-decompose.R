test_that("tee_decompose recovers variance components on simulated data", {
  skip_on_cran()
  df <- make_sim(N = 30, V = 4, M = 3, R = 3,
                 s2_item = 0.30, s2_prompt = 0.05,
                 s2_ip = 0.04, s2_ij = 0.08,
                 s2_replicate = 0.15,
                 judge_means = c(0, 0.10, 0.15))
  des <- tee_design(df,
                    outcome   = y,
                    item      = item,
                    prompt    = variant,
                    judge     = judge,
                    replicate = rep,
                    scoring   = "likert")

  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  expect_s3_class(fit, "tee_decomp")
  expect_true(is.data.frame(fit$variance))
  expect_true(all(fit$variance$variance >= 0))

  # Recovered components should be in the right ballpark (±50%).
  # Without category, item label is "item", not "within-category item".
  v <- vapply(c("item", "prompt", "item x prompt", "item x judge",
                "replicate noise"),
              function(label) fit$variance$variance[fit$variance$tle_label == label][1L],
              numeric(1L))
  truth <- c("item" = 0.30, "prompt" = 0.05,
             "item x prompt" = 0.04, "item x judge" = 0.08,
             "replicate noise" = 0.15)
  # Allow ±50% recovery on small N — these are pilot-scale samples.
  for (lbl in names(truth)) {
    expect_lt(abs(v[lbl] - truth[lbl]) / truth[lbl], 0.6,
              label = sprintf("recovered %s", lbl))
  }
})

test_that("tee_decompose tags pipeline-side vs model-side correctly", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  judge_row <- fit$variance[fit$variance$tle_label == "judge model (design sensitivity)", ]
  expect_equal(nrow(judge_row), 1L)
  expect_equal(judge_row$tier, "pipeline-side")
  model_rows <- fit$variance[fit$variance$tier == "model-side", ]
  expect_gt(nrow(model_rows), 0L)
})

test_that("tee_decompose with link='logit' fits a GLMM on binary data", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2,
                 s2_item = 0.5, s2_replicate = 0.1)
  df$y <- as.numeric(df$y > median(df$y))
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "binary")
  fit <- suppressWarnings(suppressMessages(
    tee_decompose(des, link = "logit")
  ))
  expect_equal(fit$link, "logit")
  expect_s4_class(fit$model, "glmerMod")
})

test_that("tee_decompose heteroscedastic stratified mode reports per-stratum residuals", {
  skip_on_cran()
  df <- make_sim(N = 15, V = 3, M = 1, R = 3, s2_replicate = 0.05)
  df$temp <- rep(c(0, 0.5, 1.0), length.out = nrow(df))
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    temperature = temp, replicate = rep,
                    scoring = "likert")
  fit <- suppressWarnings(suppressMessages(
    tee_decompose(des, heteroscedastic = "stratified")
  ))
  expect_equal(fit$heteroscedastic, "stratified")
  expect_equal(length(fit$meta$residual_by_temperature), 3L)
})

test_that("tee_decompose_diagnose returns a 2-row table", {
  skip_on_cran()
  df <- make_sim(N = 20, V = 3, M = 2, R = 2)
  des <- tee_design(df, outcome = y, item = item, prompt = variant,
                    judge = judge, replicate = rep, scoring = "likert")
  out <- suppressWarnings(suppressMessages(tee_decompose_diagnose(des)))
  expect_equal(nrow(out), 2L)
  expect_setequal(out$model, c("with_3way_term", "without_3way_term"))
})

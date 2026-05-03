test_that("tee_writeup paper style returns a single string with key numbers", {
  skip_on_cran()
  sim <- tee_simulate(N = 20, V = 3, M = 2, R = 2, seed = 1)
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, judge = judge_model,
                    replicate = replication, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  txt <- tee_writeup(fit, style = "paper")
  expect_type(txt, "character")
  expect_length(txt, 1L)
  expect_match(txt, "underestimate")
  expect_match(txt, "D-study")
})

test_that("tee_writeup blog style is longer than paper style", {
  skip_on_cran()
  sim <- tee_simulate(N = 20, V = 3, M = 2, R = 2, seed = 1)
  des <- tee_design(sim, outcome = outcome, item = item_id,
                    prompt = variant_id, judge = judge_model,
                    replicate = replication, scoring = "likert")
  fit <- suppressWarnings(suppressMessages(tee_decompose(des)))
  paper <- tee_writeup(fit, style = "paper")
  blog  <- tee_writeup(fit, style = "blog")
  expect_gt(nchar(blog), nchar(paper))
})

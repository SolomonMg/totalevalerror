make_pilot <- function(N = 5, V = 3, M = 2, R = 2, scoring = "likert") {
  grid <- expand.grid(
    item    = seq_len(N),
    variant = seq_len(V),
    judge   = seq_len(M),
    rep     = seq_len(R)
  )
  grid$y <- if (scoring == "binary") {
    rbinom(nrow(grid), 1, 0.5)
  } else {
    rnorm(nrow(grid))
  }
  grid
}

test_that("tee_design coerces factors and counts facets", {
  set.seed(1)
  df <- make_pilot(N = 5, V = 3, M = 2, R = 2)
  des <- tee_design(df,
                    outcome   = y,
                    item      = item,
                    prompt    = variant,
                    judge     = judge,
                    replicate = rep,
                    scoring   = "likert")

  expect_s3_class(des, "tee_design")
  expect_equal(des$meta$N, 5)
  expect_equal(des$meta$V, 3)
  expect_equal(des$meta$M, 2)
  expect_equal(des$meta$R, 2)
  expect_true(des$meta$balanced)
  expect_true(is.factor(des$data$item_id))
  expect_true(is.factor(des$data$variant_id))
  expect_equal(des$scoring, "likert")
})

test_that("tee_design handles NULL optional facets", {
  set.seed(1)
  df <- make_pilot(N = 4, V = 2, M = 1, R = 2)
  des <- tee_design(df,
                    outcome   = y,
                    item      = item,
                    prompt    = variant,
                    replicate = rep,
                    scoring   = "binary")
  expect_false("judge_model" %in% names(des$data))
  expect_true(is.na(des$meta$M))
  expect_true(is.na(des$cols$judge))
})

test_that("tee_design drops NA outcome rows", {
  set.seed(1)
  df <- make_pilot(N = 4, V = 2, M = 1, R = 2)
  df$y[1:3] <- NA
  des <- suppressMessages(suppressWarnings(
    tee_design(df,
               outcome   = y,
               item      = item,
               prompt    = variant,
               replicate = rep,
               scoring   = "likert")
  ))
  expect_equal(des$meta$n_obs, nrow(df) - 3)
})

test_that("tee_design rejects non-numeric outcome", {
  df <- data.frame(y = letters[1:4], item = 1:4, variant = 1, rep = 1)
  expect_error(
    tee_design(df, outcome = y, item = item, prompt = variant,
               replicate = rep, scoring = "likert"),
    "must be a numeric"
  )
})

test_that("tee_design warns on unbalanced design", {
  set.seed(1)
  df <- make_pilot(N = 4, V = 2, M = 2, R = 2)
  df <- df[-1, ]
  expect_warning(
    tee_design(df,
               outcome   = y,
               item      = item,
               prompt    = variant,
               judge     = judge,
               replicate = rep,
               scoring   = "likert"),
    "not balanced"
  )
})

make_des <- function(judge = TRUE, temp = TRUE, sut = FALSE, cat = FALSE) {
  set.seed(1)
  df <- expand.grid(
    item    = 1:3,
    variant = 1:2,
    judge   = if (judge) 1:2 else 1L,
    temp    = if (temp)  c(0, 1) else 0,
    sut     = if (sut)   1:2 else 1L,
    rep     = 1:2
  )
  df$category <- if (cat) (df$item %% 2) else 1L
  df$y <- rnorm(nrow(df))
  args <- list(data = df, outcome = quote(y), item = quote(item),
               prompt = quote(variant), replicate = quote(rep),
               scoring = "likert")
  if (judge) args$judge <- quote(judge)
  if (temp)  args$temperature <- quote(temp)
  if (sut)   args$sut <- quote(sut)
  if (cat)   args$category <- quote(category)
  do.call(tee_design, args)
}

test_that("tee_formula includes fixed effects when present", {
  des <- make_des(judge = TRUE, temp = TRUE)
  f <- tee_formula(des)
  s <- deparse(f, width.cutoff = 500L)
  expect_true(grepl("judge_model", s))
  expect_true(grepl("temperature", s))
  expect_true(grepl("\\(1 \\| item_id\\)", s))
  expect_true(grepl("\\(1 \\| variant_id\\)", s))
  expect_true(grepl("item_id:variant_id", s))
  expect_true(grepl("item_id:judge_model", s))
  expect_true(grepl("variant_id:temperature", s))
  expect_true(grepl("item_id:variant_id:judge_model:temperature", s))
})

test_that("tee_formula drops cell-level term when no fixed factors present", {
  des <- make_des(judge = FALSE, temp = FALSE)
  f <- tee_formula(des)
  s <- deparse(f, width.cutoff = 500L)
  expect_false(grepl("item_id:variant_id:", s))
  expect_true(grepl("\\(1 \\| item_id:variant_id\\)", s))
})

test_that("tee_formula honors include_cell_level = FALSE", {
  des <- make_des(judge = TRUE, temp = TRUE)
  f <- tee_formula(des, include_cell_level = FALSE)
  s <- deparse(f, width.cutoff = 500L)
  expect_false(grepl("item_id:variant_id:judge_model:temperature", s))
})

test_that("tee_formula adds category random effect when present", {
  des <- make_des(judge = TRUE, temp = FALSE, cat = TRUE)
  f <- tee_formula(des)
  s <- deparse(f, width.cutoff = 500L)
  expect_true(grepl("\\(1 \\| category\\)", s))
})

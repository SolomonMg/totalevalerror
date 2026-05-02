test_that("tee_pilot_recommend returns expected df_min for 20% target", {
  out <- tee_pilot_recommend(target_se_pct = 20)
  expect_equal(unique(out$df_min), 50)
  expect_equal(nrow(out), 4)
})

test_that("tee_pilot_recommend scales with target precision", {
  expect_equal(unique(tee_pilot_recommend(20)$df_min), 50)
  expect_equal(unique(tee_pilot_recommend(10)$df_min), 200)
  expect_equal(unique(tee_pilot_recommend(30)$df_min), 23)
})

test_that("tee_pilot_recommend rejects bad target", {
  expect_error(tee_pilot_recommend(0), "positive")
  expect_error(tee_pilot_recommend(-5), "positive")
})

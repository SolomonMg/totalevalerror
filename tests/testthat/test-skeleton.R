test_that("package loads and exported stubs raise informative errors", {
  expect_error(tee_design(), "not yet implemented")
  expect_error(tee_decompose(), "not yet implemented")
  expect_error(tee_dstudy(), "not yet implemented")
  expect_error(tee_se(), "not yet implemented")
  expect_error(tee_budget_allocate(), "not yet implemented")
  expect_error(tee_simulate(), "not yet implemented")
})

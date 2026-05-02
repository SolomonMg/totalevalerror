test_that("Phase 4+ stubs raise informative errors", {
  expect_error(tee_dstudy(), "not yet implemented")
  expect_error(tee_se(), "not yet implemented")
  expect_error(tee_budget_allocate(), "not yet implemented")
  expect_error(tee_simulate(), "not yet implemented")
  expect_error(tee_decompose_multiturn(), "reserved for v0.2")
})

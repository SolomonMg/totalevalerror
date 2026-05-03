test_that("Phase 6+ stubs raise informative errors", {
  expect_error(tee_simulate(), "not yet implemented")
  expect_error(tee_decompose_multiturn(), "reserved for v0.2")
})

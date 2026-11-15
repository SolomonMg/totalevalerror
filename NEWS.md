# totalevalerror 0.1.0

## First public release

* Variance decomposition (`tee_decompose`), closed-form D-study projections
  (`tee_dstudy`, `tee_se`, `tee_theta_ci`), pilot-size and budget-allocation
  helpers (`tee_pilot_recommend`, `tee_budget_allocate`, `tee_budget_compare`),
  and the naive-vs-TEE SE comparison (`tee_se_compare`).
* Fixed-effect design-sensitivity terms (lambda/M for judge/SUT, tau/H for
  temperature) added to the D-study projection.
* Fix: `tee_dstudy(by = ...)` now drops unsampled factor levels in each group,
  so per-category projections no longer error on the degenerate
  `(1 | category)` term.
* Three bundled pilot datasets (`mmlu_pilot`, `safety_pilot`, `arena_pilot`)
  and vignettes replicating the paper's empirical analyses.

# totalevalerror 0.0.0.9000

## Initial scaffolding

* Package skeleton, S3 class definitions, and roxygen-headed stubs for every
  exported function. No method bodies yet; those land in Phases 2 - 9 of the
  development plan.

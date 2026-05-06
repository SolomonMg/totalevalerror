
# totalevalerror

<!-- badges: start -->
[![R-CMD-check](https://github.com/SolomonMg/totalevalerror/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/SolomonMg/totalevalerror/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`totalevalerror` decomposes uncertainty in LLM-based evaluation into a crossed random-effects mixed model, projects standard errors under hypothetical designs (D-study), and recommends pilot sizes and budget allocations. It implements the Total Eval Error (TEE) framework from Messing (2026).

## Installation

```r
# install.packages("remotes")
remotes::install_github("SolomonMg/totalevalerror")
```

## 30-second example

```r
library(totalevalerror)

# 1. Wrap your pilot data
data(mmlu_pilot)
des <- tee_design(
  mmlu_pilot,
  outcome = outcome, item = item_id, category = category,
  prompt = variant_id, sut = sut_model, temperature = temperature,
  replicate = replication, scoring = "binary"
)

# 2. Fit the variance decomposition
fit <- tee_decompose(des)

# 3. Get a 95% confidence interval on the headline accuracy (theta-hat).
#    Returns a 1-row tibble: estimate | ci_lo | ci_hi | se | method
tee_theta_ci(fit, level = 0.95)
#> # A tibble: 1 x 5
#>   estimate ci_lo ci_hi     se method
#>      <dbl> <dbl> <dbl>  <dbl> <chr>
#> 1    0.836 0.731 0.941 0.0535 normal

# Just the SE? Use tee_se(fit). Compare it to the naive (i.i.d.) SE that
# pretends prompts/judges/items don't add variance — TEE typically reveals
# the naive CI is far too narrow:
tee_se_compare(fit, naive_se = sd(mmlu_pilot$outcome) / sqrt(nrow(mmlu_pilot)))
#> $se_naive 0.0058   $se_tee 0.0534   $underestimate_pct 89.1

# 4. Project under hypothetical designs (D-study)
proj <- tee_dstudy(fit)

# 5. Optimal budget allocation
alloc <- tee_budget_allocate(fit, budget = 6000, n_pool = 1000)

# 6. Auto-paragraph for paper writeup
tee_writeup(fit)
```

See `vignette("totalevalerror")` for a 5-minute walkthrough.

## Empirical replications

The package ships three bundled pilot datasets and four vignettes that replicate the empirical analyses from the paper:

| Vignette | Dataset | Headline |
|---|---|---|
| `vignette("mmlu")` | `mmlu_pilot` | Budget reallocation can halve the SE on the headline number. |
| `vignette("safety")` | `safety_pilot` | Swapping a single judge for three reduces the SE by ~38%. |
| `vignette("arena-likert")` | `arena_pilot` | Per-category D-study reveals different dominant variance sources. |
| `vignette("heteroscedastic")` | (simulated) | Stratified-by-temperature fits when residual scales differ. |

## Citation

```r
citation("totalevalerror")
```

## License

MIT (c) Solomon Messing.

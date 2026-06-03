# Prompt variants

Prompt material for the five framing variants per scoring method used in
Messing (2026), *Total Eval Error*. Anchor replications on these rather than
reconstructing.

## Actual rendered prompts (`inst/extdata/`)

The exact prompts sent to the models, with the real items filled in (one row per
item x variant). Each was prepended with the system prompt
`"You are a helpful assistant."`.

| File | Scoring method | Rows (items x 5) |
|---|---|---|
| `variants_mmlu.csv` | Binary correctness (MMLU) | 1000 (200 x 5) |
| `variants_likert.csv` | Likert 1 - 5 | 750 (150 x 5) |
| `variants_pairwise.csv` | Pairwise A / B | 750 (150 x 5) |

```r
mmlu <- read.csv(system.file("extdata", "variants_mmlu.csv", package = "totalevalerror"))
```

**Safety is intentionally not bundled as rendered prompts.** Each safety judge
prompt embeds a model's response to an AILuminate hazard prompt, including
borderline/unsafe responses (that is what the judge scores). To avoid
republishing potentially-unsafe model output, only the safety *template* ships
(below); render the safety prompts from the template plus the AILuminate items.

## Framing templates (`inst/prompts/`)

The generators (one `{placeholder}` per fill-in field). Crossing each template
with its items produces the rendered prompts above.

| File | Scoring method |
|---|---|
| `mmlu_variants.md` | Binary MMLU (`{question}`, `{A}`-`{D}`) |
| `safety_variants.md` | Binary SAFE/UNSAFE judge (`{prompt_text}`, `{response_text}`) |
| `likert_variants.md` | Likert 1 - 5 (`{response_text}`) |
| `pairwise_variants.md` | Pairwise A/B (`{response_a}`, `{response_b}`) |
| `likert_cot_variants.md` | Likert with chain-of-thought + JSON output |
| `pairwise_cot_variants.md` | Pairwise with chain-of-thought + JSON output |

The CoT templates are used in the chain-of-thought decomposition analysis
(paper appendix). Arena-specific and anchor-validation CoT variants used in
narrower sub-analyses live in the paper's replication code
(`experiments/create_prompt_variants.py`); the strict-paraphrase generator for
the propaganda demonstration is in `experiments/generate_prompts.py`.

## Important: these are framing variants, not strict paraphrases

The five variants deliberately vary **framing and (for MMLU) option delimiters**,
not just surface wording of one seed (e.g. MMLU shifts between `A.`, `(A)`,
`A)`, lowercase `a)` and "standard"/"exam"/"expert"/"minimal"/"analytical"
framings; safety asks materially different questions). The prompt-sensitivity
variance component ($\sigma^2_\phi$) therefore captures **phrasing-and-framing**
sensitivity, an **upper bound** on what a strict-semantic-paraphrase pilot would
estimate. See Assumption 1 in the paper.

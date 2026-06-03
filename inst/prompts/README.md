# Prompt variant templates

Exact prompt texts for the five framing variants per scoring method used in
Messing (2026), *Total Eval Error*. These are the originals consumed by the
data-collection scripts; anchor replications on these rather than reconstructing.

| File | Scoring method | Paper analysis | Fill-in fields |
|---|---|---|---|
| `mmlu_variants.md` | Binary correctness (MMLU multiple-choice) | MMLU pilot | `{question}`, `{A}`, `{B}`, `{C}`, `{D}` |
| `safety_variants.md` | Binary judge (SAFE / UNSAFE) | AILuminate safety pilot | `{prompt_text}`, `{response_text}` |
| `likert_variants.md` | Likert 1 - 5 | Likert ideology scoring | `{response_text}` |
| `pairwise_variants.md` | Pairwise A / B | Pairwise (Bradley-Terry) scoring | `{response_a}`, `{response_b}` |

Each file lists 5 variants (`v_0` - `v_4`). A design matrix crosses every item
with all 5 templates; `variant_id` indexes the template.

## Important: these are framing variants, not strict paraphrases

The five variants deliberately vary **framing and (for MMLU) option delimiters**,
not just surface wording of one seed. For example, the MMLU variants shift
between `A.`, `(A)`, `A)`, and lowercase `a)` delimiters and between "standard",
"exam", "expert", "minimal", and "analytical" framings; the safety variants ask
materially different questions ("violates guidelines" vs "could cause harm")
about the same response. The resulting prompt-sensitivity variance component
($\sigma^2_\phi$) therefore captures **phrasing-and-framing** sensitivity, an
**upper bound** on what a strict-semantic-paraphrase pilot would estimate. See
Assumption 1 in the paper for the formal interpretation.

A separate chain-of-thought variant set (used only in the CoT decomposition
appendix) and the strict-paraphrase generator for the propaganda demonstration
live in the paper's replication code (`experiments/create_prompt_variants.py`,
`experiments/generate_prompts.py`); they are not part of the core five-variant
disclosure above.

## Accessing from R

```r
prompt_dir <- system.file("prompts", package = "totalevalerror")
cat(readLines(file.path(prompt_dir, "mmlu_variants.md")), sep = "\n")
```

# Build bundled pilot datasets for the totalevalerror package by
# subsampling the paper's processed CSVs. Run from within the package
# project root with `Rscript data-raw/make_pilot_data.R`.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(usethis)
})

set.seed(42)

paper_root <- "/Users/ns/workspace/total_llm_error/data/processed"

# ---- safety_pilot --------------------------------------------------------
# Subsample 50 items x 3 variants x 3 judges x 1 temp x 3 reps = 1350 rows.
safety_full <- read_csv(file.path(paper_root, "safety_clean.csv"),
                        show_col_types = FALSE) |>
  filter(!is.na(outcome))

safety_pilot <- safety_full |>
  filter(temperature == min(temperature)) |>
  group_by(category) |>
  filter(item_id %in% sample(unique(item_id), size = min(7, n_distinct(item_id)))) |>
  ungroup() |>
  filter(replication < 3, variant_id < 3) |>
  select(item_id, category, variant_id, judge_model, temperature,
         replication, outcome) |>
  mutate(
    item_id     = as.character(item_id),
    category    = as.character(category),
    variant_id  = as.integer(variant_id),
    judge_model = as.character(judge_model),
    temperature = as.numeric(temperature),
    replication = as.integer(replication),
    outcome     = as.numeric(outcome)
  )

# ---- mmlu_pilot ----------------------------------------------------------
# 30 items x 5 variants x 4 SUTs x 3 temps x 3 reps approx.
mmlu_full <- read_csv(file.path(paper_root, "mmlu_clean.csv"),
                      show_col_types = FALSE) |>
  filter(!is.na(outcome))

mmlu_pilot <- mmlu_full |>
  group_by(category) |>
  filter(item_id %in% sample(unique(item_id), size = min(8, n_distinct(item_id)))) |>
  ungroup() |>
  filter(replication < 3) |>
  select(item_id, category, variant_id, sut_model, temperature,
         replication, outcome) |>
  mutate(
    item_id     = as.character(item_id),
    category    = as.character(category),
    variant_id  = as.character(variant_id),
    sut_model   = as.character(sut_model),
    temperature = as.numeric(temperature),
    replication = as.integer(replication),
    outcome     = as.numeric(outcome)
  )

# ---- arena_pilot ---------------------------------------------------------
# 100 battles x 3 variants x 3 judges Likert.
arena_full <- read_csv(file.path(paper_root, "arena_likert_clean.csv"),
                       show_col_types = FALSE) |>
  filter(!is.na(score), mode == "likert")

# Pick 100 unique battles, all responses (a/b sides), all variants/judges.
keep_battles <- arena_full |>
  distinct(battle_id, category_llm) |>
  group_by(category_llm) |>
  slice_sample(n = 25) |>
  ungroup() |>
  pull(battle_id)

arena_pilot <- arena_full |>
  filter(battle_id %in% keep_battles) |>
  transmute(
    item_id     = battle_id,
    category    = category_llm,
    side        = response_side,
    variant_id  = as.integer(variant_id),
    judge_model = judge_model,
    replication = 1L,                     # Arena Likert has 1 score per cell
    outcome     = as.numeric(score)
  )

# ---- write ---------------------------------------------------------------
cat(sprintf("safety_pilot: %d rows\n", nrow(safety_pilot)))
cat(sprintf("mmlu_pilot:   %d rows\n", nrow(mmlu_pilot)))
cat(sprintf("arena_pilot:  %d rows\n", nrow(arena_pilot)))

usethis::use_data(safety_pilot, overwrite = TRUE)
usethis::use_data(mmlu_pilot,   overwrite = TRUE)
usethis::use_data(arena_pilot,  overwrite = TRUE)

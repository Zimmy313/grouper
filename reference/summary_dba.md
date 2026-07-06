# Summarise a DBA result by topic-repetition group

Summarise a DBA result by topic-repetition group

## Usage

``` r
summary_dba(df_result, df_list, id_col)
```

## Arguments

- df_result:

  Data frame returned by
  [`solve_assignment()`](https://Zimmy313.github.io/grouper/reference/solve_assignment.md)
  for a diversity model. Must contain columns `topic`, `rep`, and the
  column named by `id_col`.

- df_list:

  Input list from
  [`extract_student_info()`](https://Zimmy313.github.io/grouper/reference/extract_student_info.md).
  Must contain `d` (distance matrix) and optionally `s` (skill vector).

- id_col:

  Character. Name of the student-ID column in `df_result`.

## Value

A grouped summary tibble with columns `topic`, `rep`, `n`, and
`total_diversity` (plus `total_skill` when `df_list$s` is present).

# Summarise a PBA result by topic-subtopic-repetition group

Summarise a PBA result by topic-subtopic-repetition group

## Usage

``` r
summary_pba(df_result, df_list, n_topics)
```

## Arguments

- df_result:

  Data frame returned by
  [`solve_assignment()`](https://Zimmy313.github.io/grouper/reference/solve_assignment.md)
  for a preference model. Must contain columns `group`, `topic2`,
  `subtopic`, and `rep`.

- df_list:

  Input list from
  [`extract_student_info()`](https://Zimmy313.github.io/grouper/reference/extract_student_info.md)
  for `assignment = "preference"`. Must contain `p` (preference matrix).

- n_topics:

  Integer. Number of base topics.

## Value

A grouped summary tibble with columns `topic2`, `subtopic`, `rep`, `n`,
and `total_pref_score`.

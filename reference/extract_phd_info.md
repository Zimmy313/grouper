# Extract inputs for the PhD workload allocation model

Converts student-level data and input matrices into the list expected by
[`prepare_phd_model()`](https://Zimmy313.github.io/grouper/reference/prepare_phd_model.md).

## Usage

``` r
extract_phd_info(
  student_df,
  p_mat,
  d_mat,
  e_mode = c("rr", "none"),
  C = 4,
  s = c(-1, 0, 1, 2)
)
```

## Arguments

- student_df:

  A data frame with one row per student. Required columns are:
  `student_id`, `year`, `past_ta`, and `past_gr`. Note that it has to be
  in this order and name. `year` is capped to 1-4.

- p_mat:

  Preference matrix with dimensions `Ns x Nj`. Row order must match
  `student_df` row order.

- d_mat:

  Demand matrix with dimensions `Nj x 2` or `Nj x 3`. Columns are
  interpreted in order as `TA`, `GR`, and optional `E`. Row order must
  match the column order of `p_mat`.

- e_mode:

  How to handle E demand when `d_mat` does not include E. `"rr"`
  computes E using round-robin allocation from highest to lowest GR
  demand; `"none"` leaves E at 0.

- C:

  Semester workload capacity per student. Used when `e_mode = "rr"` to
  compute total semester capacity as `Ns * C`.

- s:

  A finite numeric vector of length four containing the E-allocation
  scores for Years 1, 2, 3, and 4, respectively. Larger scores make E
  units more attractive for that year when `phi > 0` in
  [`prepare_phd_model()`](https://Zimmy313.github.io/grouper/reference/prepare_phd_model.md).
  Defaults to `c(-1, 0, 1, 2)`.

## Value

A list containing:

- `Ns`: number of students

- `Nj`: number of courses

- `P`: preference matrix (`Ns x Nj`)

- `d`: demand matrix (`Nj x 3`) with columns `TA`, `GR`, `E`

- `s`: student-level E-allocation score vector

- `year`: capped year-of-study vector

- `t1`: past TA workload vector

- `g1`: past GR workload vector

## Details

This function assumes input order is already aligned:

- `student_df` row `i` corresponds to `P[i, ]`, `s[i]`, `t1[i]`, and
  `g1[i]`.

- `d_mat` row `j` corresponds to `P[, j]`.

`p_mat` is used as supplied, so users can choose any numeric preference
scoring scheme during preprocessing.

If E is computed (`e_mode = "rr"`), total E is set to:

`Ns * C - sum(TA) - sum(GR)`.

## Examples

``` r
default_scores <- extract_phd_info(
  student_df = phd_students_ex001,
  p_mat = phd_prefmat_ex001,
  d_mat = phd_demand_ex001,
  e_mode = "none"
)

custom_scores <- extract_phd_info(
  student_df = phd_students_ex001,
  p_mat = phd_prefmat_ex001,
  d_mat = phd_demand_ex001,
  e_mode = "none",
  s = c(0, 1, 3, 6)
)
custom_scores$s
#> [1] 0 1 3 6
```

# Extract inputs for the multi-role workload allocation model

Converts individual-level data, role-specific preference matrices, and
role demand into the list expected by
[`prepare_multirole_model()`](https://Zimmy313.github.io/grouper/reference/prepare_multirole_model.md).

## Usage

``` r
extract_multirole_info(
  student_df,
  d_mat,
  p_ta_mat = NULL,
  p_gr_mat = NULL,
  e_mode = c("rr", "none"),
  C = 4,
  s = c(-1, 0, 1, 2)
)
```

## Arguments

- student_df:

  A data frame with one row per individual. Its first four columns must
  be named `student_id`, `year`, `past_ta`, and `past_gr`, in that
  order. `year` is capped to the range 1-4.

- d_mat:

  A finite numeric demand matrix with `Nj` rows and two or three
  columns. Columns are interpreted as TA, GR, and optional E.

- p_ta_mat:

  Optional finite numeric TA preference matrix with dimensions
  `Ns x Nj`.

- p_gr_mat:

  Optional finite numeric GR preference matrix with dimensions
  `Ns x Nj`.

- e_mode:

  How to handle E demand when `d_mat` has no E column. `"rr"` computes E
  demand by round-robin allocation from highest to lowest GR demand;
  `"none"` sets E demand to zero.

- C:

  Semester workload capacity per individual. Used when `e_mode = "rr"`
  to compute total semester capacity as `Ns * C`.

- s:

  A finite numeric vector of length four containing E-allocation scores
  for Years 1, 2, 3, and 4. Larger values make E allocation more
  attractive when the `phi` term is active.

## Value

A list containing `Ns`, `Nj`, `P_ta`, `P_gr`, `d`, `s`, `year`, `t1`,
and `g1`.

## Details

Preference matrices are optional during extraction because their
objective terms can be disabled in
[`prepare_multirole_model()`](https://Zimmy313.github.io/grouper/reference/prepare_multirole_model.md).
When `beta_ta` or `beta_gr` is active, the corresponding matrix must be
present.

Input order must already be aligned: row `i` in each preference matrix
must correspond to row `i` in `student_df`, and demand row `j` must
correspond to preference column `j`.

## Examples

``` r
inputs <- extract_multirole_info(
  student_df = phd_students_ex001,
  d_mat = phd_demand_ex001,
  p_ta_mat = phd_prefmat_ex001,
  p_gr_mat = phd_prefmat_ex001,
  e_mode = "none"
)
```

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
  s = c(-1, 0, 1, 2),
  single_semester = FALSE
)
```

## Arguments

- student_df:

  A data frame with one row per individual. By default, its first four
  columns must be named `student_id`, `year`, `past_ta`, and `past_gr`,
  in that order. With `single_semester = TRUE`, only `student_id` and
  `year` are required as the first two columns. `year` is capped to the
  range 1-4.

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

  Semester workload capacity per individual. It is stored in the
  extracted input and used by
  [`prepare_multirole_model()`](https://Zimmy313.github.io/grouper/reference/prepare_multirole_model.md)
  to set annual workload to `2 * C`. It also determines E demand when
  `e_mode = "rr"`.

- s:

  A finite numeric vector of length four containing E-allocation scores
  for Years 1, 2, 3, and 4. Larger values make E allocation more
  attractive when the `phi` term is active.

- single_semester:

  One non-missing logical value. When `TRUE`, supplied past-workload
  columns are ignored and extraction returns synthetic prior workloads
  `t1 = 0` and `g1 = C` for every individual.

## Value

A list containing `Ns`, `Nj`, `C`, `P_ta`, `P_gr`, `d`, `s`, `year`,
`t1`, and `g1`.

## Details

Preference matrices are optional during extraction because their
objective terms can be disabled in
[`prepare_multirole_model()`](https://Zimmy313.github.io/grouper/reference/prepare_multirole_model.md).
When `beta_ta` or `beta_gr` is active, the corresponding matrix must be
present.

Input order must already be aligned: row `i` in each preference matrix
must correspond to row `i` in `student_df`, and demand row `j` must
correspond to preference column `j`.

In single-semester mode, the uniform synthetic GR workload does not
change the GR workload spread. It fills the prior-semester half of
annual capacity, leaving `C` units per individual for current
allocation.

## Examples

``` r
inputs <- extract_multirole_info(
  student_df = multirole_students_ex001,
  d_mat = multirole_demand_ex001,
  p_ta_mat = multirole_prefmat_ex001,
  p_gr_mat = multirole_prefmat_ex001,
  e_mode = "none"
)
```

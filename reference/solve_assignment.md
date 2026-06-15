# Solve a prepared model and post-process the assignment

Solves an existing `ompr` model with an ROI-backed solver, then routes
the solver result through
[`assign_groups()`](https://Zimmy313.github.io/grouper/reference/assign_groups.md)
or
[`assign_job()`](https://Zimmy313.github.io/grouper/reference/assign_job.md)
depending on the assignment type.

## Usage

``` r
solve_assignment(
  model,
  assignment = c("diversity", "preference", "phd", "multirole"),
  solver = c("glpk", "highs", "gurobi"),
  dframe = NULL,
  params_list = NULL,
  group_names = NULL,
  student_df = NULL,
  course_codes = NULL,
  name_col = "Name",
  verbose = TRUE,
  time_limit = NULL,
  iteration_limit = NULL,
  solver_args = list()
)
```

## Arguments

- model:

  A prepared `ompr` model, usually from
  [`prepare_model()`](https://Zimmy313.github.io/grouper/reference/prepare_model.md).

- assignment:

  Character string indicating model type. Must be one of `"diversity"`,
  `"preference"`, `"phd"`, or `"multirole"`.

- solver:

  Solver to use through `ompr.roi`. Must be one of `"glpk"`, `"highs"`,
  or `"gurobi"`.

- dframe:

  The original dataframe used in
  [`extract_student_info()`](https://Zimmy313.github.io/grouper/reference/extract_student_info.md).
  Required for `assignment = "diversity"` and
  `assignment = "preference"`.

- params_list:

  The list of parameters from
  [`extract_params_yaml()`](https://Zimmy313.github.io/grouper/reference/extract_params_yaml.md).
  Required for `assignment = "preference"`.

- group_names:

  A character string denoting the self-formed group column in `dframe`.
  Required for `assignment = "diversity"` and
  `assignment = "preference"`.

- student_df:

  A data frame that contains individual name information. Required for
  `assignment = "phd"` and `assignment = "multirole"`.

- course_codes:

  Character vector of course or task codes in model order. Required for
  `assignment = "phd"` and `assignment = "multirole"`.

- name_col:

  Student name column name in `student_df`.

- verbose:

  Logical value passed to
  [`ompr.roi::with_ROI()`](https://rdrr.io/pkg/ompr.roi/man/with_ROI.html).

- time_limit, iteration_limit:

  Optional Gurobi controls. These are applied only when
  `solver = "gurobi"`.

- solver_args:

  Additional named arguments passed to
  [`ompr.roi::with_ROI()`](https://rdrr.io/pkg/ompr.roi/man/with_ROI.html).

## Value

A list with two elements:

- `model_result`: the raw result from
  [`ompr::solve_model()`](https://rdrr.io/pkg/ompr/man/solve_model.html)

- `output`: the post-processed assignment table

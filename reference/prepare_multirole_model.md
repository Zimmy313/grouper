# Prepare the multi-role workload allocation model

Builds a mixed-integer model for assigning TA, GR, and lighter E duties
while balancing role-specific workload, preferences, and cohort
protection.

## Usage

``` r
prepare_multirole_model(
  df_list,
  ta_protected_max = 1,
  gr_protected_max = 1,
  e_max = NULL,
  ta_min = NULL,
  ta_max = NULL,
  gr_min = NULL,
  gr_max = NULL,
  e_min = NULL,
  alpha_ta = 2,
  alpha_gr = NULL,
  beta_ta = 1,
  beta_gr = NULL,
  phi = 1,
  rho_ta = 10,
  rho_gr = NULL,
  C = 4,
  protected_year_ta = 1,
  protected_year_gr = 1
)
```

## Arguments

- df_list:

  A model input list from
  [`extract_multirole_info()`](https://Zimmy313.github.io/grouper/reference/extract_multirole_info.md).

- ta_protected_max, gr_protected_max:

  Non-negative soft upper limits on current-semester TA or GR workload
  for the corresponding protected cohort. A value may be `NULL` when the
  corresponding `rho_*` term is disabled.

- e_max:

  Optional upper bound on per-individual E units.

- ta_min, ta_max:

  Optional lower and upper bounds on per-individual TA units.

- gr_min, gr_max:

  Optional lower and upper bounds on per-individual GR units.

- e_min:

  Optional lower bound on per-individual E units.

- alpha_ta, alpha_gr:

  Non-negative weights for annual TA and GR workload spread.

- beta_ta, beta_gr:

  Non-negative weights for TA and GR preferences.

- phi:

  Non-negative weight for score-guided E allocation.

- rho_ta, rho_gr:

  Non-negative penalties for TA and GR protected-cohort slack.

- C:

  Semester workload capacity per individual. Annual total workload is
  fixed at `2 * C`.

- protected_year_ta, protected_year_gr:

  Whole numbers from 1 to 4 identifying the TA- and GR-protected
  cohorts.

## Value

An `ompr` model.

## Details

Any objective weight set to `NULL` or zero is disabled. Disabled
preference and E terms are omitted from the objective. Disabling a
spread term also omits its two spread variables and fairness
constraints. Disabling a protection penalty omits that role's slack
variables and soft-limit constraints, and includes every individual in
that role's fairness spread.

When a preference term is active, the corresponding `P_ta` or `P_gr`
element must be present in `df_list`.

## Examples

``` r
inputs <- extract_multirole_info(
  student_df = phd_students_ex001,
  d_mat = phd_demand_ex001,
  p_ta_mat = phd_prefmat_ex001,
  p_gr_mat = phd_prefmat_ex001,
  e_mode = "rr"
)
model <- prepare_multirole_model(
  inputs,
  alpha_gr = 1,
  beta_gr = 1,
  rho_gr = 10
)
```

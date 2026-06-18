# Multi-role Workload Allocation

## Model introduction

Higher-education teaching teams often need to allocate multiple types of
work across the same pool of staff or graduate students. A common
setting involves three roles:

1.  Teaching-assistant work (TA), such as tutorials, laboratory
    sessions, and other forms of direct teaching support.
2.  Grading work (GR), such as marking assignments, tests, and
    examinations.
3.  A third role, E, which captures lighter or more intermittent duties
    such as exam invigilation, consultation support, and routine
    administrative tasks.

This model is useful when a department must satisfy exact demand for
each role while also accounting for role-specific preferences, priority
rules for lighter duties, and protections for selected cohorts. It can
also incorporate previous workload and balance total workload over a
longer planning horizon.

Let there be $`N_s`$ individuals indexed by $`i \in \{1,\ldots,N_s\}`$
and $`N_j`$ courses or tasks indexed by $`j \in \{1,\ldots,N_j\}`$. For
each task-role pair, where
$`r \in \{\mathrm{TA}, \mathrm{GR}, \mathrm{E}\}`$, the required demand
$`d_{j,r}`$ must be fully assigned.

For each individual-task pair, $`P^{\mathrm{TA}}_{i,j}`$ and
$`P^{\mathrm{GR}}_{i,j}`$ denote the user-supplied TA and grading
preference scores. Higher values indicate stronger preferences. Year of
study is denoted by $`y_i`$ (capped within 1-4), and $`s_i`$ is a
user-configurable score that guides E allocation. The model also tracks
past semester TA and GR workload, denoted by $`t_i^{(1)}`$ and
$`g_i^{(1)}`$.

TA and GR may protect different cohorts. Let
$`y^\ast_{\mathrm{TA}}, y^\ast_{\mathrm{GR}} \in \{1,2,3,4\}`$ denote
the protected years for the two roles. Each role’s fairness spread
excludes its own protected cohort. The model supports one protected
cohort per role, but the two roles may protect the same or different
cohorts.

The generalized model balances:

1.  annual TA and GR workload fairness,
2.  role-specific TA and grading preferences,
3.  score-guided allocation of lighter E duties, and
4.  separate TA and GR workload protection for selected cohorts.

## Model formulation

### Objective function

``` math
\begin{align*}
X_{i,j,r} &\in \mathbb{Z}_{\ge 0} && \text{units of role } r \text{ in course } j \text{ assigned to student } i \\
t_i^{(2)} &= \sum_{j=1}^{N_j} X_{i,j,\mathrm{TA}} && \text{current-semester TA workload} \\
g_i^{(2)} &= \sum_{j=1}^{N_j} X_{i,j,\mathrm{GR}} && \text{current-semester GR workload} \\
e_i^{(2)} &= \sum_{j=1}^{N_j} X_{i,j,\mathrm{E}} && \text{current-semester E workload} \\
T_i &= t_i^{(1)} + t_i^{(2)} && \text{yearly TA workload} \\
G_i &= g_i^{(1)} + g_i^{(2)} && \text{yearly GR workload} \\
w_i^{\mathrm{TA}} &\ge 0 && \text{slack for the protected cohort's TA soft bound} \\
w_i^{\mathrm{GR}} &\ge 0 && \text{slack for the protected cohort's GR soft bound} \\
T_{\max},T_{\min} &\ge 0 && \text{TA workload bounds outside } y^\ast_{\mathrm{TA}} \\
G_{\max},G_{\min} &\ge 0 && \text{GR workload bounds outside } y^\ast_{\mathrm{GR}}
\end{align*}
```

``` math
\begin{aligned}
\min\quad
&\alpha_{\mathrm{TA}}(T_{\max}-T_{\min})
+\alpha_{\mathrm{GR}}(G_{\max}-G_{\min})\\
&-\beta_{\mathrm{TA}}
  \sum_{i=1}^{N_s}\sum_{j=1}^{N_j}
  P^{\mathrm{TA}}_{i,j}X_{i,j,\mathrm{TA}}\\
&-\beta_{\mathrm{GR}}
  \sum_{i=1}^{N_s}\sum_{j=1}^{N_j}
  P^{\mathrm{GR}}_{i,j}X_{i,j,\mathrm{GR}}\\
&-\phi
  \sum_{i=1}^{N_s}\sum_{j=1}^{N_j}
  s_iX_{i,j,\mathrm{E}}\\
&+\rho_{\mathrm{TA}}
  \sum_{i:y_i=y^\ast_{\mathrm{TA}}}w_i^{\mathrm{TA}}
+\rho_{\mathrm{GR}}
  \sum_{i:y_i=y^\ast_{\mathrm{GR}}}w_i^{\mathrm{GR}}.
\end{aligned}
```

All objective weights are non-negative and user-specified.
$`\alpha_{\mathrm{TA}}`$ and $`\alpha_{\mathrm{GR}}`$ control the
importance of annual workload balance for the two main roles.
$`\beta_{\mathrm{TA}}`$ and $`\beta_{\mathrm{GR}}`$ reward role-specific
preference satisfaction. The E term rewards allocation to individuals
with larger $`s_i`$ when $`\phi > 0`$. Finally, $`\rho_{\mathrm{TA}}`$
and $`\rho_{\mathrm{GR}}`$ penalize violations of the protected cohorts’
soft workload limits.

### Demand satisfaction

For every task and role, assigned units must match demand:

``` math
\sum_{i=1}^{N_s}X_{i,j,r}=d_{j,r},
\quad \forall j,\quad
r\in\{\mathrm{TA},\mathrm{GR},\mathrm{E}\}.
```

### Role-specific workload spread

Annual TA spread is measured outside the TA-protected cohort:

``` math
T_{\min}\le T_i\le T_{\max},
\quad \forall i:y_i\ne y^\ast_{\mathrm{TA}}.
```

Annual GR spread is measured outside the GR-protected cohort:

``` math
G_{\min}\le G_i\le G_{\max},
\quad \forall i:y_i\ne y^\ast_{\mathrm{GR}}.
```

The two protected years may be the same or different. If a role’s
protection penalty is disabled, no cohort is protected for that role and
all individuals enter its fairness spread.

### Annual workload equality

Let $`C`$ denote semester workload capacity per individual. The model
fixes each individual’s annual workload total at $`2C`$:

``` math
T_i+G_i+e_i^{(2)}=2C,\quad \forall i.
```

### Protected-cohort soft upper bounds

Current-semester TA workload is softly capped for the TA-protected
cohort:

``` math
t_i^{(2)}
\le t_{\max}^{(P)}+w_i^{\mathrm{TA}},
\quad \forall i:y_i=y^\ast_{\mathrm{TA}}.
```

Current-semester grading workload is separately capped for the
GR-protected cohort:

``` math
g_i^{(2)}
\le g_{\max}^{(P)}+w_i^{\mathrm{GR}},
\quad \forall i:y_i=y^\ast_{\mathrm{GR}}.
```

The slack variables preserve feasibility while making excess workload
costly through the corresponding $`\rho`$ terms.

### Optional current-semester workload bounds

If supplied, role-wide lower and upper bounds are also imposed:

``` math
\begin{align}
t_{\min}^{(2)} \le t_i^{(2)} \le t_{\max}^{(2)}, \quad &\forall i, \\
g_{\min}^{(2)} \le g_i^{(2)} \le g_{\max}^{(2)}, \quad &\forall i, \\
e_{\min}^{(2)} \le e_i^{(2)} \le e_{\max}^{(2)}, \quad &\forall i.
\end{align}
```

If a bound is omitted, its corresponding constraint is not added.

## Package interface

The multi-role workflow consists of:

1.  [`extract_multirole_info()`](https://Zimmy313.github.io/grouper/reference/extract_multirole_info.md)
    or `extract_info(assignment = "multirole")`,
2.  [`prepare_multirole_model()`](https://Zimmy313.github.io/grouper/reference/prepare_multirole_model.md)
    or `prepare_model(assignment = "multirole")`,
3.  `solve_assignment(assignment = "multirole")` or the lower-level
    [`ompr::solve_model()`](https://rdrr.io/pkg/ompr/man/solve_model.html)
    and
    [`assign_job()`](https://Zimmy313.github.io/grouper/reference/assign_job.md)
    functions.

The bundled multi-role example data demonstrate the generalized
interface. Here the same matrix is supplied for TA and GR preferences
only to keep the example compact. In practice, the matrices can contain
different user-defined scores.

### Semester history and capacity

By default,
[`extract_multirole_info()`](https://Zimmy313.github.io/grouper/reference/extract_multirole_info.md)
expects `student_id`, `year`, `past_ta`, and `past_gr` as the first four
columns of `student_df` and uses the supplied prior workload. Semester
capacity `C` is also supplied at extraction and stored in the returned
input list.
[`prepare_multirole_model()`](https://Zimmy313.github.io/grouper/reference/prepare_multirole_model.md)
reads this stored value when enforcing annual workload of `2 * C`; it
does not take a separate capacity argument.

For an allocation with no prior-semester workload data, use
`single_semester = TRUE`. In this mode, only `student_id` and `year` are
required as the first two columns, and any supplied past-workload
columns are ignored. Extraction generates `t1 = 0` and `g1 = C` for
every individual:

``` r

single_semester_students <- grouper::multirole_students_ex001[
  , c("student_id", "year", "Name")
]

single_semester_inputs <- grouper::extract_multirole_info(
  student_df = single_semester_students,
  d_mat = grouper::multirole_demand_ex001,
  p_ta_mat = grouper::multirole_prefmat_ex001,
  e_mode = "rr",
  C = 4,
  single_semester = TRUE
)

cbind(t1 = single_semester_inputs$t1, g1 = single_semester_inputs$g1)
#>      t1 g1
#> [1,]  0  4
#> [2,]  0  4
#> [3,]  0  4
#> [4,]  0  4
```

The uniform synthetic `g1 = C` workload adds the same constant to every
individual’s annual GR workload, so it does not change the GR spread. It
fills the prior-semester half of the annual equality and leaves `C`
units per individual for current TA, GR, and E allocation.

### E-allocation scoring

[`extract_multirole_info()`](https://Zimmy313.github.io/grouper/reference/extract_multirole_info.md)
accepts a four-value `s` vector ordered by Years 1 to 4. The default is
set to `c(-1, 0, 1, 2)`, which encourages E allocation to more senior
students.

``` r

default_inputs <- grouper::extract_multirole_info(
  student_df = grouper::multirole_students_ex001,
  d_mat = grouper::multirole_demand_ex001,
  p_ta_mat = grouper::multirole_prefmat_ex001,
  p_gr_mat = grouper::multirole_prefmat_ex001,
  e_mode = "none"
)

default_inputs$s
#> [1] -1  0  1  2
```

Users can provide a different encoding to control the E-allocation
objective:

``` r

custom_inputs <- grouper::extract_multirole_info(
  student_df = grouper::multirole_students_ex001,
  d_mat = grouper::multirole_demand_ex001,
  p_ta_mat = grouper::multirole_prefmat_ex001,
  p_gr_mat = grouper::multirole_prefmat_ex001,
  e_mode = "none",
  s = c(0, 1, 3, 6)
)

custom_inputs$s
#> [1] 0 1 3 6
```

The score vector affects only the E objective. Protection and TA
fairness use `student_df$year`. Both preference matrices are used
exactly as supplied, so users can choose their own numeric scoring
schemes during preprocessing rather than using the example `3/2/1/-99`
encoding.

### Role-specific terms

The new GR terms are disabled by default. Set their weights to positive
values to enable GR workload spread, grading preferences, and GR cohort
protection:

``` r

multi_role_model <- grouper::prepare_model(
  default_inputs,
  assignment = "multirole",
  alpha_ta = 2,
  alpha_gr = 2,
  beta_ta = 1,
  beta_gr = 1,
  phi = 1,
  rho_ta = 10,
  rho_gr = 10,
  protected_year_ta = 1,
  protected_year_gr = 3,
  ta_protected_max = 1,
  gr_protected_max = 1
)
```

The TA and GR protected years must each be one value from 1 to 4. The
selected cohort receives that role’s soft upper bound and slack penalty,
and is excluded from that role’s fairness spread.

### Keeping the model small

An objective weight set to `NULL` or zero is disabled during model
construction. The corresponding objective expression is not added. For
spread and protection terms, their supporting variables and constraints
are also omitted. For example:

``` r

ta_only_model <- grouper::prepare_multirole_model(
  default_inputs,
  alpha_gr = NULL,
  beta_gr = NULL,
  rho_gr = NULL
)
```

This conditional construction is useful for larger allocation problems
because the solver receives only the variables and constraints needed
for the selected formulation. When `rho_ta` or `rho_gr` is disabled,
that role has no protected cohort and its fairness spread, if active,
includes every individual.

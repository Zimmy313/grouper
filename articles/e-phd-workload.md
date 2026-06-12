# PhD Workload Allocation

## Model introduction

Consider a situation where a department needs to allocate semester
workload across PhD students. Let there be $`N_s`$ students indexed by
$`i \in \{1,\ldots,N_s\}`$ and $`N_j`$ courses indexed by
$`j \in \{1,\ldots,N_j\}`$. For each course-role pair, where
$`r \in \{\mathrm{TA}, \mathrm{GR}, \mathrm{E}\}`$, the required demand
$`d_{j,r}`$ must be fully assigned.

For each student-course pair, $`P_{i,j}`$ denotes the user-supplied TA
preference score. Student year of study is denoted by $`y_i`$. The
E-allocation score is represented by $`s_i`$ and defaults to
$`-1,0,1,2`$ for Years 1, 2, 3 and 4, respectively. Users may replace
this four-value encoding during extraction. We also track prior-semester
TA and GR workload, denoted by $`t_i^{(1)}`$ and $`g_i^{(1)}`$.

This model allocates current-semester TA, GR and E units while
balancing:

1.  TA fairness across non-Year-1 students,
2.  TA preference satisfaction,
3.  Seniority-aware E allocation, and
4.  protection of Year-1 students from excessive TA load.

## Objective function

The model minimises the weighted objective:

``` math
\begin{align*}
X_{i,j,r} &\in \mathbb{Z}_{\ge 0} && \text{units of role } r \text{ in course } j \text{ assigned to student } i \\
t_i^{(2)} &= \sum_{j=1}^{N_j} X_{i,j,\mathrm{TA}} && \text{current-semester TA workload} \\
g_i^{(2)} &= \sum_{j=1}^{N_j} X_{i,j,\mathrm{GR}} && \text{current-semester GR workload} \\
e_i^{(2)} &= \sum_{j=1}^{N_j} X_{i,j,\mathrm{E}} && \text{current-semester E workload} \\
T_i &= t_i^{(1)} + t_i^{(2)} && \text{yearly TA workload} \\
G_i &= g_i^{(1)} + g_i^{(2)} && \text{yearly GR workload} \\
w_i &\ge 0 && \text{slack for Year-1 TA soft bound} \\
T_{\max} &\ge 0 && \text{maximum yearly TA workload among students with } y_i \ge 2 \\
T_{\min} &\ge 0 && \text{minimum yearly TA workload among students with } y_i \ge 2
\end{align*}
```

``` math
\min \quad
\alpha (T_{\max} - T_{\min})
- \beta \sum_{i=1}^{N_s} \sum_{j=1}^{N_j} P_{i,j} X_{i,j,\mathrm{TA}}
- \phi \sum_{i=1}^{N_s} \sum_{j=1}^{N_j} s_i X_{i,j,\mathrm{E}}
+ \rho \sum_{i:y_i=1} w_i
```

where $`\alpha,\beta,\phi,\rho \ge 0`$ are user-specified weights. When
$`\phi > 0`$, larger values of $`s_i`$ make E allocation more
attractive.

## Input scoring

[`extract_phd_info()`](https://Zimmy313.github.io/grouper/reference/extract_phd_info.md)
accepts a four-value `s` vector ordered by Years 1 to 4. The default
`c(-1, 0, 1, 2)` reproduces the original seniority scoring:

``` r

default_inputs <- grouper::extract_phd_info(
  student_df = grouper::phd_students_ex001,
  p_mat = grouper::phd_prefmat_ex001,
  d_mat = grouper::phd_demand_ex001,
  e_mode = "none"
)

default_inputs$s
#> [1] -1  0  1  2
```

Users can provide a different encoding to control the E-allocation
objective:

``` r

custom_inputs <- grouper::extract_phd_info(
  student_df = grouper::phd_students_ex001,
  p_mat = grouper::phd_prefmat_ex001,
  d_mat = grouper::phd_demand_ex001,
  e_mode = "none",
  s = c(0, 1, 3, 6)
)

custom_inputs$s
#> [1] 0 1 3 6
```

The score vector affects only the E objective. Year-1 protection and the
TA fairness group continue to use `student_df$year`. The preference
matrix is also used exactly as supplied, so users can choose their own
numeric scoring during preprocessing rather than using the example
`3/2/1/-99` encoding.

## Constraints

### Demand satisfaction

For every course and role, assigned units must match demand:

``` math
\sum_{i=1}^{N_s} X_{i,j,r} = d_{j,r},
\quad \forall j,\; r \in \{\mathrm{TA}, \mathrm{GR}, \mathrm{E}\}
```

### TA spread among non-Year-1 students

The spread term applies only to students in Year 2 or above:

``` math
\begin{align}
T_i &\le T_{\max}, \quad \forall i : y_i \ge 2 \\
T_i &\ge T_{\min}, \quad \forall i : y_i \ge 2
\end{align}
```

### Annual workload equality

Let $`C`$ denote semester workload capacity per student. The model fixes
each student’s annual workload total at $`2C`$.

``` math
T_i + G_i + e_i^{(2)} = 2C, \quad \forall i
```

### Year-1 TA soft upper bound

For Year-1 students, current-semester TA load is softly capped:

``` math
t_i^{(2)} \le t_{\max}^{(Y1)} + w_i, \quad \forall i : y_i = 1
```

### Optional current-semester workload bounds

If provided by the user, the following bounds are imposed:

``` math
\begin{align}
t_{\min}^{(2)} \le t_i^{(2)} \le t_{\max}^{(2)}, \quad \forall i \\
g_{\min}^{(2)} \le g_i^{(2)} \le g_{\max}^{(2)}, \quad \forall i \\
e_{\min}^{(2)} \le e_i^{(2)} \le e_{\max}^{(2)}, \quad \forall i
\end{align}
```

If any bound parameter is omitted, the corresponding constraint is not
added.

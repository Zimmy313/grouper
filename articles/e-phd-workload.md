# PhD Workload Allocation

## Model introduction

Consider a situation where a department needs to allocate semester
workload across PhD students. Let there be $N_{s}$ students indexed by
$i \in \{ 1,\ldots,N_{s}\}$ and $N_{j}$ courses indexed by
$j \in \{ 1,\ldots,N_{j}\}$. For each course-role pair, where
$r \in \{{TA},{GR},E\}$, the required demand $d_{j,r}$ must be fully
assigned.

For each student-course pair, $P_{i,j}$ denotes the TA preference score.
Student seniority is represented by $s_{i}$, where Year-1, Year-2,
Year-3 and Year-4 are mapped to $- 1,0,1,2$ respectively. We also track
prior-semester TA and GR workload, denoted by $t_{i}^{(1)}$ and
$g_{i}^{(1)}$.

This model allocates current-semester TA, GR and E units while
balancing:

1.  TA fairness across non-Year-1 students,
2.  TA preference satisfaction,
3.  Seniority-aware E allocation, and
4.  protection of Year-1 students from excessive TA load.

## Objective function

The model minimises the weighted objective:

$$\begin{aligned}
X_{i,j,r} & {\in {\mathbb{Z}}_{\geq 0}} & & {{\text{units of role}\mspace{6mu}}r{\mspace{6mu}\text{in course}\mspace{6mu}}j{\mspace{6mu}\text{assigned to student}\mspace{6mu}}i} \\
t_{i}^{(2)} & {= \sum\limits_{j = 1}^{N_{j}}X_{i,j,{TA}}} & & \text{current-semester TA workload} \\
g_{i}^{(2)} & {= \sum\limits_{j = 1}^{N_{j}}X_{i,j,{GR}}} & & \text{current-semester GR workload} \\
e_{i}^{(2)} & {= \sum\limits_{j = 1}^{N_{j}}X_{i,j,E}} & & \text{current-semester E workload} \\
T_{i} & {= t_{i}^{(1)} + t_{i}^{(2)}} & & \text{yearly TA workload} \\
G_{i} & {= g_{i}^{(1)} + g_{i}^{(2)}} & & \text{yearly GR workload} \\
w_{i} & {\geq 0} & & \text{slack for Year-1 TA soft bound} \\
T_{\max} & {\geq 0} & & {{\text{maximum yearly TA workload among students with}\mspace{6mu}}s_{i} \geq 0} \\
T_{\min} & {\geq 0} & & {{\text{minimum yearly TA workload among students with}\mspace{6mu}}s_{i} \geq 0}
\end{aligned}$$

$$\min\quad\alpha\left( T_{\max} - T_{\min} \right) - \beta\sum\limits_{i = 1}^{N_{s}}\sum\limits_{j = 1}^{N_{j}}P_{i,j}X_{i,j,{TA}} - \phi\sum\limits_{i = 1}^{N_{s}}\sum\limits_{j = 1}^{N_{j}}s_{i}X_{i,j,E} + \rho\sum\limits_{i:s_{i} = - 1}w_{i}$$

where $\alpha,\beta,\phi,\rho \geq 0$ are user-specified weights.

## Constraints

### Demand satisfaction

For every course and role, assigned units must match demand:

$$\sum\limits_{i = 1}^{N_{s}}X_{i,j,r} = d_{j,r},\quad\forall j,\; r \in \{{TA},{GR},E\}$$

### TA spread among non-Year-1 students

The spread term applies only to students with $s_{i} \geq 0$:

$$\begin{aligned}
T_{i} & {\leq T_{\max},\quad\forall i:s_{i} \geq 0} \\
T_{i} & {\geq T_{\min},\quad\forall i:s_{i} \geq 0}
\end{aligned}$$

### Annual workload equality

Let $C$ denote semester workload capacity per student. The model fixes
each student’s annual workload total at $2C$.

$$T_{i} + G_{i} + e_{i}^{(2)} = 2C,\quad\forall i$$

### Year-1 TA soft upper bound

For Year-1 students, current-semester TA load is softly capped:

$$t_{i}^{(2)} \leq t_{\max}^{(Y1)} + w_{i},\quad\forall i:s_{i} = - 1$$

### Optional current-semester workload bounds

If provided by the user, the following bounds are imposed:

$$\begin{array}{r}
{t_{\min}^{(2)} \leq t_{i}^{(2)} \leq t_{\max}^{(2)},\quad\forall i} \\
{g_{\min}^{(2)} \leq g_{i}^{(2)} \leq g_{\max}^{(2)},\quad\forall i} \\
{e_{\min}^{(2)} \leq e_{i}^{(2)} \leq e_{\max}^{(2)},\quad\forall i}
\end{array}$$

If any bound parameter is omitted, the corresponding constraint is not
added.

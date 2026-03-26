# Maximising Preference

## Model introduction

Consider a situation where an instructor wishes to divide students into
groups. Each group will be allocated a topic $t$, from a pool of topics
$1,\ldots,T$. However, each project team assigned to topic would
comprise $B$ sub-groups or sub-teams. Thus, in essence, there would be
$BT$ topics to be assigned to student groups. It is also possible that
each topic $t$ is repeated $R_{t}$ times across the class. Note that the
more common case, where there is only one sub-group per topic, can be
easily attained by setting $B = 1$.

In total, there are $N$ students in the class. Suppose that students
form their own groups, which they submit through a survey form. In total
there are $G$ groups; each student appears in exactly 1 group. We let
$n_{g}$ represent the number of students in group $g$, where $g$ runs
from $1,\ldots,G$.

Finally, suppose we also have the preference that each self-formed group
has for a particular topic $t$, where $t \in \{ 1,\ldots,BT\}$.

This model allows you to maximise the preference scores for each group.

## Objective function

$$\max\sum\limits_{g = 1}^{G}\sum\limits_{t = 1}^{BT}\sum\limits_{r = 1}^{R_{t}}x_{gtr} \cdot n_{g} \cdot p_{tg}$$

where $p_{tg}$ corresponds to the preference score that group $g$ has
for topic $t$. Since our objective function is formulated as a
*maximum*, the preference scores should be coded such that higher scores
indicate stronger preference for a topic.

The decision variable $x_{gtr}$ is a binary variable.

$$x_{gtr} = \begin{cases}
1 & {{\text{if group}\mspace{6mu}}g{\mspace{6mu}\text{is assigned to repetition}\mspace{6mu}}r{\mspace{6mu}\text{of topic}\mspace{6mu}}t} \\
0 & \text{otherwise}
\end{cases}$$

## Constraints

### Group to topic-repetition combination

The first constraint ensures that each group is assigned to exactly one
topic $t$, where $t \in \{ 1,\;\ldots,\; BT\}$.

$$\sum\limits_{t = 1}^{BT}\sum\limits_{r = 1}^{R_{t}}x_{gtr} = 1,\quad\forall g$$

### Number of repetitions per topic

This set of constraints serve to regulate the total number of
repetitions for each topic. $r_{min}$ and $r_{max} = R_{t}$ are input
variables that the instructor needs to set.

$a_{tr}$ is a binary decision variable which indicates if repetition $r$
of topic $t$ is “live”, where $r \in \{ 1,\ldots,R_{t}\}$.

$$\begin{array}{rcl}
a_{tr} & \geq & {x_{gtr},\quad\forall t \in \{ 1,2,\ldots,BT\},\; r} \\
a_{tr} & \leq & {\sum\limits_{g = 1}^{G}x_{gtr},\quad\forall t \in \{ 1,2,\ldots,BT\},\; r} \\
a_{tr} & \geq & {r_{min},\quad\forall t \in \{ 1,2,\ldots,T\}}
\end{array}$$

### Balanced number of subgroups

The next constraint ensures that there is an equal number of subgroups
for each “live” repetition of a topic.
$$\sum\limits_{r = 1}^{R}a_{tr} = \sum\limits_{r = 1}^{R}a_{{(bT + t)}r},\quad\forall t \in \{ 1,2,\ldots,T\},\;\min(1,B - 1) \leq b \leq \max(0,B - 1)$$

This is where we can see that the ordering of all sub-groups in the
preference matrix should be as follows:

$$T_{1}S_{1},\; T_{2}S_{1},\;\ldots,\; T_{1}S_{2},T_{2}S_{2},\;\ldots T_{T}S_{B}$$

### Number of students per subgroup

A similar set of constraints are used to bound the number of students in
each eventually assigned group.

$$\begin{array}{rcl}
{\sum\limits_{i = 1}^{N}\sum\limits_{g = 1}^{G}m_{ig} \cdot x_{gtr}} & \geq & {a_{tr} \cdot n_{tr}^{min},\quad\forall t \in \{ 1,2,\ldots,BT\},\; r} \\
{\sum\limits_{i = 1}^{N}\sum\limits_{g = 1}^{G}m_{ig} \cdot x_{gtr}} & \leq & {a_{tr} \cdot n_{tr}^{max},\quad\forall t \in \{ 1,2,\ldots,BT\},\; r}
\end{array}$$

### Binary and non-negativity constraints

Finally, as stated above, we have the following constraints on the
decision variables.

$$\begin{array}{rcl}
x_{gtr} & \in & {\{ 0,1\}} \\
a_{tr} & \in & {\{ 0,1\}}
\end{array}$$

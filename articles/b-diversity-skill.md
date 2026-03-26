# Maximising Diversity and Balancing Skill

## Model introduction

Consider a situation where an instructor wishes to divide students into
groups. Each group will be allocated a topic $t$, from a pool of topics
$1,\ldots,T$. It is possible that each topic $t$ is repeated $R_{t}$
times across the class. In total, there are $N$ students in the class.

Suppose that students form their own groups, which they submit through a
survey form. In total there are $G$ groups; each student appears in
exactly 1 group.

In addition, we have the following information about each student:

1.  Information that can be used to compute dissimilarities between
    pairs of students. Examples are: the major of the student (STEM
    vs. non-STEM), gender, year-of-study, etc.
2.  Information on the skill level pertinent to your class, or to the
    problem they will be working on.

This model allows you to maximise the diversity within a group and
minimise the difference in skill within groups.

## Objective function

The overall objective function can be written as:

$$\max\quad w_{1}\left( \sum\limits_{i = 1}^{N - 1}\sum\limits_{j = i + 1}^{N}\sum\limits_{t = 1}^{T}\sum\limits_{r = 1}^{R_{t}}z_{ijtr} \cdot d_{ij} \right) + w_{2}\left( s_{min} - s_{max} \right)$$

where $w_{1}$ and $w_{2}$ are weights. They indicate which half of the
objective function should be given priority.

## Constraints

### Group to topic-repetition combination

First, let us introduce the decision variable of interest:

$$x_{gtr} = \begin{cases}
1 & {{\text{if group}\mspace{6mu}}g{\mspace{6mu}\text{is assigned to repetition}\mspace{6mu}}r{\mspace{6mu}\text{of topic}\mspace{6mu}}t} \\
0 & \text{otherwise}
\end{cases}$$

$s_{min}$ and $s_{max}$ are also decision variables. The objective
function attempts to minimise the difference between them, ensuring all
groups have a similar range of total skill.

This first constraint represents the need for each group to be assigned
to exactly one topic-repetition combination:

$$\sum\limits_{t = 1}^{T}\sum\limits_{r = 1}^{R_{t}}x_{gtr} = 1,\quad\forall g$$

### Defining $z_{ijtr}$

$z_{ijtr}$ is a binary variable, used to pick up whether the pairwise
dissimilarity between student $i$ and student $j$ should be included in
the objective function calculation.

$$\begin{array}{rcl}
z_{ijtr} & \leq & {\sum\limits_{g = 1}^{G}m_{ig} \cdot x_{gtr},\quad\forall i,j,t,r} \\
z_{ijtr} & \leq & {\sum\limits_{g = 1}^{G}m_{jg} \cdot x_{gtr},\quad\forall i,j,t,r} \\
z_{ijtr} & \geq & {\sum\limits_{g = 1}^{G}m_{ig} \cdot x_{gtr} + \sum\limits_{g = 1}^{G}m_{jg} \cdot x_{gtr} - 1,\quad\forall i,j,t,r}
\end{array}$$

### Number of repetitions per topic

This set of constraints serve to regulate the total number of
repetitions for each topic. $r_{min}$ and $r_{max}$ are input variables
that the instructor needs to set.

$$\begin{array}{rcl}
a_{tr} & \geq & {x_{gtr},\quad\forall t,r} \\
a_{tr} & \leq & {\sum\limits_{g = 1}^{G}x_{gtr},\quad\forall t,r} \\
{\sum\limits_{r = 1}^{R_{t}}a_{tr}} & \geq & {r_{min},\quad\forall t} \\
{\sum\limits_{r = 1}^{R_{t}}a_{tr}} & \leq & {r_{max},\quad\forall t}
\end{array}$$

### Number of students per group

A similar set of constraints are used to bound the number of students in
each eventually assigned group.

$$\begin{array}{rcl}
{\sum\limits_{i = 1}^{N}\sum\limits_{g = 1}^{G}m_{ig} \cdot x_{gtr}} & \geq & {a_{tr} \cdot n_{tr}^{min},\quad\forall t,r} \\
{\sum\limits_{i = 1}^{N}\sum\limits_{g = 1}^{G}m_{ig} \cdot x_{gtr}} & \leq & {a_{tr} \cdot n_{tr}^{max},\quad\forall t,r}
\end{array}$$

### Per-group skill levels

We aim to maintain the skill level within each group using the following
constraints.

$$\begin{array}{rcl}
{\sum\limits_{i = 1}^{N}\sum\limits_{g = 1}^{G}m_{ig} \cdot x_{gtr} \cdot s_{i}} & \geq & {s_{min},\quad\forall t,r} \\
{\sum\limits_{i = 1}^{N}\sum\limits_{g = 1}^{G}m_{ig} \cdot x_{gtr} \cdot s_{i}} & \leq & {s_{max},\quad\forall t,r} \\
 & & 
\end{array}$$

### Binary and non-negativity constraints

$$\begin{array}{rcl}
x_{gtr} & \in & {\{ 0,1\}} \\
a_{tr} & \in & {\{ 0,1\}} \\
s_{min} & \geq & 0 \\
s_{max} & \geq & 0
\end{array}$$

# Application to simple datasets

``` r

library(grouper)
library(ompr)
library(ompr.roi)
#library(ROI.plugin.gurobi)
library(ROI.plugin.glpk)
```

## Introduction

This vignette illustrates the use of the package on simple datasets, for
which the optimal solutions are apparent from inspection.

For each dataset below, we will use 2 workflows to run the optimisation.
The first workflow does not make use of the wrapper function
[`extract_info()`](https://Zimmy313.github.io/grouper/reference/extract_info.md)
and instead uses
[`extract_student_info()`](https://Zimmy313.github.io/grouper/reference/extract_student_info.md)
and
[`extract_params_yaml()`](https://Zimmy313.github.io/grouper/reference/extract_params_yaml.md).
The alternative uses
[`extract_info()`](https://Zimmy313.github.io/grouper/reference/extract_info.md)
as the extraction wrapper; for diversity and preference models it also
demonstrates direct parameter supply in
[`prepare_model()`](https://Zimmy313.github.io/grouper/reference/prepare_model.md)
(without YAML).

## Diversity-Based Assignment

### Dataset 001 (diversity only)

The first dataset comprises just 4 students. Here is what it looks like.
The name of this dataset indicates that it is for the
diversity-based-assignment (dba) model and that it consists of the group
composition (gc) information.

``` r

dba_gc_ex001
#>   id major skill groups
#> 1  1     A     1      1
#> 2  2     A     1      2
#> 3  3     B     3      3
#> 4  4     B     3      4
```

It is intuitive that an assignment into two groups of size two, based on
the diversity of majors alone, should assign students 1 and 2 into the
first group and the remaining two students into another group.

The corresponding YAML `dba_gc_ex001.yml` file for this exercise
consists of the following lines:

    n_topics:  2
    R:  1
    nmin: 2
    nmax: 2
    rmin: 1
    rmax: 1

To run the assignment using only the primary major (ignoring the skill),
we can use the following commands. We can use either the gurobi solver,
or the glpk solver for this example. Both are equally fast.

``` r

# indicate appropriate columns using integer ids.
df_ex001_list <- extract_student_info(dba_gc_ex001, "diversity",
                                  demographic_cols = 2, skills = 3, 
                                  self_formed_groups = 4)
yaml_ex001_list <- extract_params_yaml(system.file("extdata", 
                                             "dba_params_ex001.yml",  
                                             package = "grouper"),
                                       "diversity")
m1 <- prepare_model(df_ex001_list, yaml_ex001_list, assignment="diversity",
                    w1=1.0, w2=0.0)
#result3 <- solve_model(m1, with_ROI(solver="gurobi"))
result3 <- solve_model(m1, with_ROI(solver="glpk"))
assign_groups(result3, assignment = "diversity", dframe=dba_gc_ex001, 
              group_names="groups")
#>   topic rep group id major skill
#> 1     1   1     2  2     A     1
#> 2     1   1     4  4     B     3
#> 3     2   1     1  1     A     1
#> 4     2   1     3  3     B     3
```

Alternative workflow (wrapper + direct parameters):

``` r

df_ex001_alt <- extract_info(
  assignment = "diversity",
  dframe = dba_gc_ex001,
  demographic_cols = 2,
  skills = 3,
  self_formed_groups = 4
)

m1_alt <- prepare_model(
  df_ex001_alt,
  assignment = "diversity",
  w1 = 1.0,
  w2 = 0.0,
  n_topics = 2,
  R = 1,
  nmin = 2,
  nmax = 2,
  rmin = 1,
  rmax = 1
)

result3_alt <- solve_model(m1_alt, with_ROI(solver = "glpk"))
assign_groups(
  model_result = result3_alt,
  assignment = "diversity",
  dframe = dba_gc_ex001,
  group_names = "groups"
)
#>   topic rep group id major skill
#> 1     1   1     2  2     A     1
#> 2     1   1     4  4     B     3
#> 3     2   1     1  1     A     1
#> 4     2   1     3  3     B     3
```

We can see that students 1 and 2 have been assigned to topic 1,
repetition 1. Students 3 and 4 have been assigned to topic 2, repetition
1.

### Dataset 001 (skills only)

``` r

# indicate appropriate columns using integer ids.
df_ex001_list <- extract_student_info(dba_gc_ex001, "diversity",
                                  demographic_cols = 2, skills = 3, 
                                  self_formed_groups = 4)
yaml_ex001_list <- extract_params_yaml(system.file("extdata", 
                                             "dba_params_ex001.yml",  
                                             package = "grouper"),
                                       "diversity")
m1a <- prepare_model(df_ex001_list, yaml_ex001_list, assignment="diversity",
                    w1=0.0, w2=1.0)
#result3 <- solve_model(m1a, with_ROI(solver="gurobi"))
result3 <- solve_model(m1a, with_ROI(solver="glpk"))

assign_groups(result3, assignment = "diversity", dframe=dba_gc_ex001, 
              group_names="groups")
#>   topic rep group id major skill
#> 1     1   1     2  2     A     1
#> 2     1   1     3  3     B     3
#> 3     2   1     1  1     A     1
#> 4     2   1     4  4     B     3

get_solution(result3, smin)
#> smin 
#>    4
get_solution(result3, smax)
#> smax 
#>    4
```

Alternative workflow (wrapper + direct parameters):

``` r

df_ex001_skill_alt <- extract_info(
  assignment = "diversity",
  dframe = dba_gc_ex001,
  demographic_cols = 2,
  skills = 3,
  self_formed_groups = 4
)

m1a_alt <- prepare_model(
  df_ex001_skill_alt,
  assignment = "diversity",
  w1 = 0.0,
  w2 = 1.0,
  n_topics = 2,
  R = 1,
  nmin = 2,
  nmax = 2,
  rmin = 1,
  rmax = 1
)

result3_skill_alt <- solve_model(m1a_alt, with_ROI(solver = "glpk"))

assign_groups(
  model_result = result3_skill_alt,
  assignment = "diversity",
  dframe = dba_gc_ex001,
  group_names = "groups"
)
#>   topic rep group id major skill
#> 1     1   1     2  2     A     1
#> 2     1   1     3  3     B     3
#> 3     2   1     1  1     A     1
#> 4     2   1     4  4     B     3

get_solution(result3_skill_alt, smin)
#> smin 
#>    4
get_solution(result3_skill_alt, smax)
#> smax 
#>    4
```

We can see that students 1 and 2 have been assigned to topic 1,
repetition 1. Students 3 and 4 have been assigned to topic 2, repetition
1.

### Dataset 003

This dataset demonstrates the use of a custom dissimilarity matrix
instead of using the default Gower distance from the
[cluster](https://cran.r-project.org/package=cluster) package.

``` r

dba_gc_ex003
#>   year   major self_groups id
#> 1    1    math           1  1
#> 2    2 history           2  2
#> 3    3    dsds           3  3
#> 4    4    elts           4  4
```

Now consider a situation where we wish to consider years 1 and 2
different from years 3 and 4, and `math` and `dsds` (STEM majors) to be
different from `elts` and `history` (non-STEM majors). For each
difference, we assign a score of 1.

This means that students 1 and 2 would have a dissimilarity score of 1
due to their difference in majors. Students 1 and 3 would also have a
score of 1, but due to their difference in years. Students 1 and 4 would
have score of 2, due to their differences in majors and in years. The
overall dissimilarity matrix would be:

``` r

d_mat <- matrix(c(0, 1, 1, 2,
                  1, 0, 2, 1,
                  1, 2, 0, 1,
                  2, 1, 1, 0), nrow=4, byrow = TRUE)
```

To run the optimisation for this model, we can execute the following
code:

``` r

df_ex003_list <- extract_student_info(dba_gc_ex003, "diversity",
                                skills = NULL,
                                self_formed_groups = 3,
                                d_mat=d_mat)
yaml_ex003_list <- extract_params_yaml(system.file("extdata",   
                                                   "dba_params_ex003.yml",   
                                                   package = "grouper"), 
                                       "diversity")
m3 <- prepare_model(df_ex003_list, yaml_ex003_list, w1=1.0, w2=0.0)
result <- solve_model(m3, with_ROI(solver="glpk", verbose=TRUE))
#> <SOLVER MSG>  ----
#> GLPK Simplex Optimizer 5.0
#> 58 rows, 22 columns, 142 non-zeros
#>       0: obj =  -0.000000000e+00 inf =   6.000e+00 (6)
#>      12: obj =  -0.000000000e+00 inf =   1.110e-15 (0)
#> *    28: obj =   8.000000000e+00 inf =   7.772e-16 (0)
#> OPTIMAL LP SOLUTION FOUND
#> GLPK Integer Optimizer 5.0
#> 58 rows, 22 columns, 142 non-zeros
#> 22 integer variables, all of which are binary
#> Integer optimization begins...
#> Long-step dual simplex will be used
#> +    28: mip =     not found yet <=              +inf        (1; 0)
#> +    44: >>>>>   4.000000000e+00 <=   7.000000000e+00  75.0% (6; 0)
#> +    49: mip =   4.000000000e+00 <=     tree is empty   0.0% (0; 11)
#> INTEGER OPTIMAL SOLUTION FOUND
#> <!SOLVER MSG> ----

assign_groups(result, "diversity", dba_gc_ex003, group_names="self_groups")
#>   topic rep group year   major id
#> 1     1   1     1    1    math  1
#> 2     1   1     4    4    elts  4
#> 3     2   1     2    2 history  2
#> 4     2   1     3    3    dsds  3
```

Alternative workflow (wrapper + direct parameters):

``` r

df_ex003_alt <- extract_info(
  assignment = "diversity",
  dframe = dba_gc_ex003,
  skills = NULL,
  self_formed_groups = 3,
  d_mat = d_mat
)

m3_alt <- prepare_model(
  df_ex003_alt,
  assignment = "diversity",
  w1 = 1.0,
  w2 = 0.0,
  n_topics = 2,
  R = 1,
  nmin = 2,
  nmax = 2,
  rmin = 1,
  rmax = 1
)

result_alt <- solve_model(m3_alt, with_ROI(solver = "glpk", verbose = TRUE))
#> <SOLVER MSG>  ----
#> GLPK Simplex Optimizer 5.0
#> 58 rows, 22 columns, 142 non-zeros
#>       0: obj =  -0.000000000e+00 inf =   6.000e+00 (6)
#>      12: obj =  -0.000000000e+00 inf =   1.110e-15 (0)
#> *    28: obj =   8.000000000e+00 inf =   7.772e-16 (0)
#> OPTIMAL LP SOLUTION FOUND
#> GLPK Integer Optimizer 5.0
#> 58 rows, 22 columns, 142 non-zeros
#> 22 integer variables, all of which are binary
#> Integer optimization begins...
#> Long-step dual simplex will be used
#> +    28: mip =     not found yet <=              +inf        (1; 0)
#> +    44: >>>>>   4.000000000e+00 <=   7.000000000e+00  75.0% (6; 0)
#> +    49: mip =   4.000000000e+00 <=     tree is empty   0.0% (0; 11)
#> INTEGER OPTIMAL SOLUTION FOUND
#> <!SOLVER MSG> ----

assign_groups(
  model_result = result_alt,
  assignment = "diversity",
  dframe = dba_gc_ex003,
  group_names = "self_groups"
)
#>   topic rep group year   major id
#> 1     1   1     1    1    math  1
#> 2     1   1     4    4    elts  4
#> 3     2   1     2    2 history  2
#> 4     2   1     3    3    dsds  3
```

As you can see, the members of the two groups have maximal difference
between them - they differ in terms of their year, and in terms of their
major.

### Dataset 004

In this example, we demonstrate that `grouper` provides the flexibility
to constrain group sizes for individual topics. This could be useful in
a situation where a particular project topic may require a larger group.

The dataset we use contains only skill levels (Python skills, higher
corresponding to more skill).

``` r

dba_gc_ex004
#>   id python self_groups
#> 1  1      1           1
#> 2  2      1           2
#> 3  3      1           3
#> 4  4      2           4
#> 5  5      3           5
```

Suppose we wish to assign the students to two topics, but the second
topic requires 3 members, and the first requires only 2. In this
example, we only utilise the skill levels; no demographic variables are
included in the objective function.

``` r

df_ex004_list <- extract_student_info(dba_gc_ex004, 
                                      skills = 2, 
                                      self_formed_groups = 3, 
                                      d_mat=matrix(0, 5, 5))
yaml_ex004_list <- extract_params_yaml(system.file("extdata",    
                                                   "dba_params_ex004.yml",   
                                                   package = "grouper"),  
                                       "diversity")
m4 <- prepare_model(df_ex004_list, yaml_ex004_list, w1=0.0, w2=1.0)
result <- solve_model(m4, with_ROI(solver="glpk", verbose=TRUE))
#> <SOLVER MSG>  ----
#> GLPK Simplex Optimizer 5.0
#> 89 rows, 34 columns, 234 non-zeros
#>       0: obj =  -0.000000000e+00 inf =   7.000e+00 (7)
#>      28: obj =  -4.000000000e+00 inf =   4.441e-16 (0)
#> *    29: obj =  -4.440892099e-16 inf =   4.441e-16 (0)
#> OPTIMAL LP SOLUTION FOUND
#> GLPK Integer Optimizer 5.0
#> 89 rows, 34 columns, 234 non-zeros
#> 32 integer variables, all of which are binary
#> Integer optimization begins...
#> Long-step dual simplex will be used
#> +    29: mip =     not found yet <=              +inf        (1; 0)
#> +    40: >>>>>   0.000000000e+00 <=   0.000000000e+00   0.0% (3; 0)
#> +    40: mip =   0.000000000e+00 <=     tree is empty   0.0% (0; 5)
#> INTEGER OPTIMAL SOLUTION FOUND
#> <!SOLVER MSG> ----
assign_groups(result, "diversity", dba_gc_ex004, group_names="self_groups")
#>   topic rep group id python
#> 1     1   1     2  2      1
#> 2     1   1     5  5      3
#> 3     2   1     1  1      1
#> 4     2   1     3  3      1
#> 5     2   1     4  4      2
```

Alternative workflow (wrapper + direct parameters):

``` r

df_ex004_alt <- extract_info(
  assignment = "diversity",
  dframe = dba_gc_ex004,
  skills = 2,
  self_formed_groups = 3,
  d_mat = matrix(0, 5, 5)
)

m4_alt <- prepare_model(
  df_ex004_alt,
  assignment = "diversity",
  w1 = 0.0,
  w2 = 1.0,
  n_topics = 2,
  R = 1,
  nmin = c(2, 3),
  nmax = c(2, 3),
  rmin = 1,
  rmax = 1
)

result4_alt <- solve_model(m4_alt, with_ROI(solver = "glpk", verbose = TRUE))
#> <SOLVER MSG>  ----
#> GLPK Simplex Optimizer 5.0
#> 89 rows, 34 columns, 234 non-zeros
#>       0: obj =  -0.000000000e+00 inf =   7.000e+00 (7)
#>      28: obj =  -4.000000000e+00 inf =   4.441e-16 (0)
#> *    29: obj =  -4.440892099e-16 inf =   4.441e-16 (0)
#> OPTIMAL LP SOLUTION FOUND
#> GLPK Integer Optimizer 5.0
#> 89 rows, 34 columns, 234 non-zeros
#> 32 integer variables, all of which are binary
#> Integer optimization begins...
#> Long-step dual simplex will be used
#> +    29: mip =     not found yet <=              +inf        (1; 0)
#> +    40: >>>>>   0.000000000e+00 <=   0.000000000e+00   0.0% (3; 0)
#> +    40: mip =   0.000000000e+00 <=     tree is empty   0.0% (0; 5)
#> INTEGER OPTIMAL SOLUTION FOUND
#> <!SOLVER MSG> ----
assign_groups(
  model_result = result4_alt,
  assignment = "diversity",
  dframe = dba_gc_ex004,
  group_names = "self_groups"
)
#>   topic rep group id python
#> 1     1   1     2  2      1
#> 2     1   1     5  5      3
#> 3     2   1     1  1      1
#> 4     2   1     3  3      1
#> 5     2   1     4  4      2
```

Due to the constraints, topic 2 was assigned 3 members, while preserving
the total skill level in each group (to be 4).

## Preference-Based Assignment

### Dataset 002

The second datasets comprises 8 students. Here is a listing of the
dataset:

``` r

pba_gc_ex002
#>   id grouping
#> 1  1        1
#> 2  2        1
#> 3  3        2
#> 4  4        2
#> 5  5        3
#> 6  6        3
#> 7  7        4
#> 8  8        4
```

Each student is in a self-formed group of size 2, indicated via the
`grouping` column. Suppose that, for this set of students, the
instructor wishes to assign students into two topics, with each topic
having two sub-groups. This requires the preference matrix to have 4
columns - one for each topic-subgroup combination. Remember that the
ordering of topics/subtopics should be:

T1S1, T2S1, T1S2, T2S2

There should be 4 rows in the preference matrix - one for each
self-formed group.

``` r

pba_prefmat_ex002
#>      col1 col2 col3 col4
#> [1,]    4    3    2    1
#> [2,]    3    4    2    1
#> [3,]    1    2    4    3
#> [4,]    1    2    3    4
```

It is possible to assign each self-formed group to its optimal choice of
topic-subtopic combination. In our solution, we should see that group 1
is assigned to subtopic 1 of topic 1, group 2 is assigned to sub-topic 1
of topic 2, and so on.

``` r

df_ex002_list <- extract_student_info(pba_gc_ex002, "preference", 
                                      self_formed_groups = 2, 
                                      pref_mat = pba_prefmat_ex002)
yaml_ex002_list <- extract_params_yaml(system.file("extdata", 
                                             "pba_params_ex002.yml",  
                                             package = "grouper"),
                                       "preference")
m2 <- prepare_model(df_ex002_list, yaml_ex002_list, "preference")

#result2 <- solve_model(m2, with_ROI(solver="gurobi"))
result2 <- solve_model(m2, with_ROI(solver="glpk"))
assign_groups(result2, assignment = "preference", 
              dframe=pba_gc_ex002, yaml_ex002_list, 
              group_names="grouping")
#>   topic2 subtopic rep group size
#> 1      1        1   1     1    2
#> 2      2        1   1     2    2
#> 3      1        2   1     3    2
#> 4      2        2   1     4    2
```

Alternative workflow (wrapper + direct parameters):

``` r

df_ex002_alt <- extract_info(
  assignment = "preference",
  dframe = pba_gc_ex002,
  self_formed_groups = 2,
  pref_mat = pba_prefmat_ex002
)

m2_alt <- prepare_model(
  df_ex002_alt,
  assignment = "preference",
  n_topics = 2,
  B = 2,
  R = 1,
  nmin = 2,
  nmax = 2,
  rmin = 1,
  rmax = 1
)

result2_alt <- solve_model(m2_alt, with_ROI(solver = "glpk"))
assign_groups(
  model_result = result2_alt,
  assignment = "preference",
  dframe = pba_gc_ex002,
  params_list = list(n_topics = 2, B = 2),
  group_names = "grouping"
)
#>   topic2 subtopic rep group size
#> 1      1        1   1     1    2
#> 2      2        1   1     2    2
#> 3      1        2   1     3    2
#> 4      2        2   1     4    2
```

## Multi-role Workload Assignment

This example has four individuals and four courses, with
`past_ta + past_gr = 4` for each individual.

``` r

multirole_students_ex001
#>   student_id year past_ta past_gr  Name
#> 1          1    1       2       2   Ava
#> 2          2    2       1       3   Ben
#> 3          3    3       3       1 Chloe
#> 4          4    4       0       4 Dylan
multirole_prefmat_ex001
#>      C101 C102 C103 C104
#> [1,]    3    2    1  -99
#> [2,]  -99    3    2    1
#> [3,]    2  -99    3    1
#> [4,]    2    1  -99    3
multirole_demand_ex001
#>      TA GR
#> C101  1  1
#> C102  1  1
#> C103  1  1
#> C104  1  1
```

The demand matrix intentionally excludes E. Because TA and GR demand are
below total capacity, `e_mode = "rr"` generates the remaining E demand.

The direct workflow uses
[`extract_multirole_info()`](https://Zimmy313.github.io/grouper/reference/extract_multirole_info.md)
and
[`prepare_multirole_model()`](https://Zimmy313.github.io/grouper/reference/prepare_multirole_model.md).
The example preference matrix is used for TA; the GR terms are disabled
in this first example.

``` r

multirole_ex001 <- extract_multirole_info(
  student_df = multirole_students_ex001,
  d_mat = multirole_demand_ex001,
  p_ta_mat = multirole_prefmat_ex001,
  e_mode = "rr",
  C = c_sem
)

multirole_ex001$d
#>      TA GR E
#> C101  1  1 2
#> C102  1  1 2
#> C103  1  1 2
#> C104  1  1 2
```

``` r

m_multirole_ex001 <- prepare_multirole_model(
  multirole_ex001,
  ta_protected_max = 1,
  ta_min = 1, ta_max = 1,
  gr_min = 1, gr_max = 1,
  alpha_ta = 2, beta_ta = 1, phi = 1, rho_ta = 10,
  alpha_gr = NULL, beta_gr = NULL, rho_gr = NULL
)

result_multirole_ex001 <- solve_model(
  m_multirole_ex001,
  with_ROI(solver = "glpk")
)

assign_job(
  result_multirole_ex001,
  student_df = multirole_students_ex001,
  course_codes = rownames(multirole_demand_ex001),
  name_col = "Name"
)
#>    Name C101-t C102-t C103-t C104-t C101-g C102-g C103-g C104-g C101-e C102-e
#> 1   Ava      1      0      0      0      1      0      0      0      2      0
#> 2   Ben      0      1      0      0      0      1      0      0      0      2
#> 3 Chloe      0      0      1      0      0      0      1      0      0      0
#> 4 Dylan      0      0      0      1      0      0      0      1      0      0
#>   C103-e C104-e
#> 1      0      0
#> 2      0      0
#> 3      2      0
#> 4      0      2
```

### Full TA and GR workflow

The following wrapper workflow activates every objective component. For
simplicity, the same example preference matrix is used for TA and GR,
although the two matrices can be different in practice. Year 1 receives
TA protection, while Year 2 receives GR protection.

``` r

full_multirole_inputs <- extract_info(
  assignment = "multirole",
  student_df = multirole_students_ex001,
  d_mat = multirole_demand_ex001,
  p_ta_mat = multirole_prefmat_ex001,
  p_gr_mat = multirole_prefmat_ex001,
  e_mode = "rr",
  C = c_sem
)

full_multirole_model <- prepare_model(
  full_multirole_inputs,
  assignment = "multirole",
  protected_year_ta = 1,
  protected_year_gr = 2,
  ta_protected_max = 1,
  gr_protected_max = 1,
  alpha_ta = 2,
  alpha_gr = 2,
  beta_ta = 1,
  beta_gr = 1,
  phi = 1,
  rho_ta = 10,
  rho_gr = 10
)

full_multirole_result <- solve_assignment(
  model = full_multirole_model,
  assignment = "multirole",
  solver = "glpk",
  student_df = multirole_students_ex001,
  course_codes = rownames(multirole_demand_ex001),
  name_col = "Name",
  verbose = FALSE
)

full_multirole_result$output
#>    Name C101-t C102-t C103-t C104-t C101-g C102-g C103-g C104-g C101-e C102-e
#> 1   Ava      1      0      0      0      1      1      0      0      1      0
#> 2   Ben      0      1      1      0      0      0      0      0      0      0
#> 3 Chloe      0      0      0      0      0      0      1      1      0      2
#> 4 Dylan      0      0      0      1      0      0      0      0      1      0
#>   C103-e C104-e
#> 1      0      0
#> 2      2      0
#> 3      0      0
#> 4      0      2
```

The resulting current-semester workload totals confirm that TA, GR, and
E are all allocated:

    #>    Name TA GR E current_total
    #> 1   Ava  1  2 1             4
    #> 2   Ben  2  0 2             4
    #> 3 Chloe  0  2 2             4
    #> 4 Dylan  1  0 3             4

### Single-semester

The model enforces an annual total of `2 * C` for every individual. For
a single-semester allocation, set `single_semester = TRUE` during
extraction. Only `student_id` and `year` are then required as the first
two columns. Extraction ignores any supplied `past_ta` and `past_gr`
columns and generates `t1 = 0` and `g1 = C` for every individual.

The synthetic `g1 = C` values are uniform, so they shift every annual GR
workload by the same amount and do not change the GR spread. They fill
one semester of the annual equality and leave exactly `C` units per
individual for the current TA, GR, and E allocation. Capacity is
supplied once during extraction and is stored in the resulting input
list for model preparation.

``` r

multirole_students_ex001_sem <- multirole_students_ex001[
  , c("student_id", "year", "Name")
]

multirole_ex001_sem <- extract_multirole_info(
  student_df = multirole_students_ex001_sem,
  d_mat = multirole_demand_ex001,
  p_ta_mat = multirole_prefmat_ex001,
  e_mode = "rr",
  C = c_sem,
  single_semester = TRUE
)

m_multirole_ex001_sem <- prepare_model(
  multirole_ex001_sem,
  assignment = "multirole",
  ta_protected_max = 1,
  ta_min = 1, ta_max = 1,
  gr_min = 1, gr_max = 1
)

result_multirole_ex001_sem <- solve_model(
  m_multirole_ex001_sem,
  with_ROI(solver = "glpk")
)

job_multirole_ex001_sem <- assign_job(
  result_multirole_ex001_sem,
  student_df = multirole_students_ex001_sem,
  course_codes = rownames(multirole_demand_ex001),
  name_col = "Name"
)

job_multirole_ex001_sem
#>    Name C101-t C102-t C103-t C104-t C101-g C102-g C103-g C104-g C101-e C102-e
#> 1   Ava      1      0      0      0      1      0      0      0      2      0
#> 2   Ben      0      1      0      0      0      1      0      0      0      2
#> 3 Chloe      0      0      1      0      0      0      1      0      0      0
#> 4 Dylan      0      0      0      1      0      0      0      1      0      0
#>   C103-e C104-e
#> 1      0      0
#> 2      0      0
#> 3      2      0
#> 4      0      2
```

``` r

ta_cols <- grepl("-t$", names(job_multirole_ex001_sem))
gr_cols <- grepl("-g$", names(job_multirole_ex001_sem))
e_cols <- grepl("-e$", names(job_multirole_ex001_sem))

data.frame(
  Name = job_multirole_ex001_sem$Name,
  TA = rowSums(job_multirole_ex001_sem[, ta_cols, drop = FALSE]),
  GR = rowSums(job_multirole_ex001_sem[, gr_cols, drop = FALSE]),
  E = rowSums(job_multirole_ex001_sem[, e_cols, drop = FALSE]),
  current_total = rowSums(
    job_multirole_ex001_sem[, ta_cols | gr_cols | e_cols, drop = FALSE]
  )
)
#>    Name TA GR E current_total
#> 1   Ava  1  1 2             4
#> 2   Ben  1  1 2             4
#> 3 Chloe  1  1 2             4
#> 4 Dylan  1  1 2             4
```

Each objective weight can be disabled with `NULL` or zero. Its objective
expression is omitted, and spread or protection variables and
constraints are also omitted when their corresponding weights are
disabled.

Standalone constructors include
[`prepare_diversity_model()`](https://Zimmy313.github.io/grouper/reference/prepare_diversity_model.md),
[`prepare_preference_model()`](https://Zimmy313.github.io/grouper/reference/prepare_preference_model.md),
and
[`prepare_multirole_model()`](https://Zimmy313.github.io/grouper/reference/prepare_multirole_model.md).

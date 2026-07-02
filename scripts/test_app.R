library(grouper)
library(ompr)
library(ompr.roi)
library(ROI.plugin.gurobi)
library(ROI.plugin.glpk)
library(ROI.plugin.highs)

df1 <- readRDS("data009-composition.rds")
df_list <- extract_student_info(df1, "diversity",
                                demographic_cols = 2, skills = NULL, 
                                self_formed_groups = 1)
yaml_list <- extract_params_yaml("mdl01_input009.yml", "diversity")

# Purely demographic-diversity based.
m1 <- prepare_model(df_list, yaml_list, "diversity", w1=1.0)
#result <- solve_model(m1, with_ROI(solver="gurobi"))

# tm limit in milliseconds
# https://cran.r-universe.dev/Rglpk/doc/manual.html
#result <- solve_model(m1, with_ROI(solver="glpk", verbose=TRUE, tm_limit=100))
result <- solve_model(m1, with_ROI(solver="glpk", verbose=TRUE, presolve=TRUE, tm_limit=5000))

assigned_groups <- assign_groups(result, "diversity", df1, yaml_list, "student_id")

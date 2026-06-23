library(grouper)
library(ompr)
library(ompr.roi)
library(ROI.plugin.gurobi)
library(ROI.plugin.glpk)
library(tidyverse)

source('df_summary.R')

############### DBA examples ###############
## Example 1

cur_df <- readRDS("data013-composition.rds")

df_list <- extract_student_info(cur_df, "diversity",   self_formed_groups = 1,
                                demographic_cols = 2, skills = NULL)
yaml_list <- extract_params_yaml("mdl01_input013.yml", "diversity")
cur_mdl <- prepare_model(df_list, yaml_list, "diversity")
result <- solve_model(cur_mdl, with_ROI(solver="gurobi", verbose=TRUE))
cur_assigned <- assign_groups(result, assignment = "diversity",
                              dframe=cur_df, yaml_list,
                              group_names="student_id")
summary_dba(cur_assigned, df_list, "group")

## Example 2

df1 <- readRDS("data009-composition.rds")
df_list <- extract_student_info(df1, demographic_cols = 2, skills = NULL, self_formed_groups = 1)
yaml_list <- extract_params_yaml("mdl01_input009.yml")
m1 <- prepare_model(df_list, yaml_list, w1=1.0)
result <- solve_model(m1, with_ROI(solver="gurobi", verbose=TRUE))
assigned_groups <- assign_groups(result, dframe=df1, assignment = "diversity",
                                 group_names = "student_id")
summary_dba(assigned_groups, df_list, "group")

## Example 3

df1 <- readRDS("data010-composition.rds")
df_list <- extract_student_info(df1, demographic_cols = 2, skills = NULL, self_formed_groups = 1)
yaml_list <- extract_params_yaml("mdl01_input010.yml")
m1 <- prepare_model(df_list, yaml_list, w1=1.0)
result <- solve_model(m1, with_ROI(solver="gurobi", verbose=TRUE))
assigned_groups <- assign_groups(result, dframe = df1, assignment = "diversity",
                                 group_names = "student_id")

## Example 4

df1 <- readRDS("data011-composition.rds")
df_list <- extract_student_info(df1, demographic_cols = 2, skills = NULL, self_formed_groups = 1)
yaml_list <- extract_params_yaml("mdl01_input011.yml")
m1 <- prepare_model(df_list, yaml_list, w1=1.0)
result <- solve_model(m1, with_ROI(solver="gurobi", verbose=TRUE))
assigned_groups <- assign_groups(result, dframe = df1, assignment = "diversity",
                                 group_names = "student_id")

## Example 5

df_ex001_list <- extract_student_info(dba_gc_ex001, "diversity",
                                  demographic_cols = 2, skills = 3,
                                  self_formed_groups = 4)
yaml_ex001_list <- extract_params_yaml("mdl01_input_ex001.yml", "diversity")
m1 <- prepare_model(df_ex001_list, yaml_ex001_list, assignment="diversity",
                    w1=1.0, w2=0.0)
result3 <- solve_model(m1, with_ROI(solver="gurobi"))
assign_groups(result3, assignment = "diversity", dframe=dba_gc_ex001,
              group_names="groups")

m2 <- prepare_model(df_ex001_list, yaml_ex001_list, assignment="diversity",
                    w1=0.0, w2=1.0)
result3 <- solve_model(m2, with_ROI(solver="gurobi"))
assigned_groups <- assign_groups(result3, assignment = "diversity", dframe=dba_gc_ex001,
              group_names="groups")

################## PBA Examples ##########################

### Example 1
group_comp_df1 <- readRDS("data006-composition.rds")
group_pref_mat1 <- readRDS("data006-preference.rds")

df_list <- extract_student_info(group_comp_df1, "preference",
                                self_formed_groups = 2,
                                pref_mat = group_pref_mat1)
yaml_list <- extract_params_yaml("mdl02_input06.yml", "preference")
mdl2_6 <- prepare_model(df_list, yaml_list, "preference")
result <- solve_model(mdl2_6, with_ROI(solver="gurobi", verbose=TRUE))
groupr_assigned_df1 <- assign_groups(result, assignment = "preference",
                                     dframe=group_comp_df1, yaml_list,
                                     group_names="group_id")


## Example 2
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

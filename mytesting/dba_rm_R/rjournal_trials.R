library(grouper)
library(ompr)
library(ompr.roi)
library(ROI.plugin.gurobi)
library(tidyverse)

source('df_summary.R')

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
summary_diversity(cur_assigned, df_list, NULL, "group")

## Example 2

df1 <- readRDS("data009-composition.rds")
df_list <- extract_student_info(df1, demographic_cols = 2, skills = NULL, self_formed_groups = 1)
yaml_list <- extract_params_yaml("mdl01_input009.yml")
m1 <- prepare_model(df_list, yaml_list, w1=1.0)
result <- solve_model(m1, with_ROI(solver="gurobi", verbose=TRUE))
assigned_groups <- assign_groups(result, dframe=df1, assignment = "diversity",
                                 group_names = "student_id")
summary_diversity(assigned_groups, df_list, NULL, "group")

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

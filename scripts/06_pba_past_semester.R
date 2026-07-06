# Script for reproducing analyses on PBA for previous semester
# This model was used to form groups and assign topics (with repetitions) to
# self-formed groups that had specified their preferences for topic/subtopic
# combinations.
#
# In these cases, the Gurobi commercial solver tended to find the optimal
# solution faster than glpk.
#
################################################################################
# In the code below, if you wish to use glpk,                                  #
# remember to comment/uncomment the appropriate lines below (one set for each  #
# semester). We recommend setting the time limit for glpk; even if the global  #
# optimal solution is not found, a good feasible one is usually returned.      #
################################################################################
#
# Set working directory to be scripts/ before running.

library(grouper)
library(ompr)
library(ompr.roi)
library(ROI.plugin.gurobi)
library(ROI.plugin.glpk)
library(tidyverse)

## Semester 2120

# Run the model on the dataset, having removed one undersubscribed topic
group_comp_df1 <- readRDS("../data/derived/data005-composition.rds")
group_pref_mat1 <- readRDS("../data/derived/data005-preference.rds")[, -c(1,6)]

df_list <- extract_info(dframe=group_comp_df1, assignment="preference",
                        self_formed_groups = 2,
                        pref_mat = group_pref_mat1)
mdl2_5 <- prepare_model(df_list, assignment="preference", n_topics=4, B=2,
                        nmin=3, nmax=5, rmin=1, rmax=2)

# Choose your solver here:
result <- solve_model(mdl2_5, with_ROI(solver="gurobi", verbose=TRUE))
# result <- solve_model(mdl2_5, with_ROI(solver="glpk", verbose=TRUE))

groupr_assigned_df1 <- assign_groups(result, assignment = "preference",
                                     dframe=group_comp_df1,
                                     params_list = list(n_topics=4, B=2),
                                     group_names="group_id")
total_pref <- summary_pba(groupr_assigned_df1, df_list, 4)

# Extract the manually allocated topics.
allocated_df1 <- readRDS("../data/derived/data005-allocated.rds")

# Calculate mean preference over students
allocated_pref_mean_2120 <- sum(allocated_df1$pref_for_allocated_topic*allocated_df1$size)/sum(allocated_df1$size)
# 8.16
groupr_pref_mean_2120 <- sum(total_pref$total_pref_score)/NROW(group_comp_df1)
# 9.47

## Semester 2210

group_comp_df1 <- readRDS("../data/derived/data006-composition.rds")
group_pref_mat1 <- readRDS("../data/derived/data006-preference.rds")
allocated_df1 <- readRDS("../data/derived/data006-allocated.rds")

df_list <- extract_info(dframe=group_comp_df1, assignment="preference",
                        self_formed_groups = 2,
                        pref_mat = group_pref_mat1)
mdl2_6 <- prepare_model(df_list, assignment="preference", n_topics=7, B=2,
                        nmin=3, nmax=5, rmin=1, rmax=3)

# Choose your solver here:
result <- solve_model(mdl2_6, with_ROI(solver="gurobi", verbose=TRUE))
# result <- solve_model(mdl2_6, with_ROI(solver="glpk", verbose=TRUE, tm_limit = 1.2e5))
groupr_assigned_df1 <- assign_groups(result, assignment = "preference",
                                     dframe=group_comp_df1,
                                     params_list = list(n_topics=7, B=2),
                                     group_names="group_id")
total_pref <- summary_pba(groupr_assigned_df1, df_list, 7)

allocated_pref_mean_2210 <-
 sum(allocated_df1$pref_for_allocated_topic*allocated_df1$size)/sum(allocated_df1$size)
# 13.06
groupr_pref_mean_2210 <- sum(total_pref$total_pref_score)/NROW(group_comp_df1)
# 13.32

## Semester 2220

group_comp_df1 <- readRDS("../data/derived/data007-composition.rds")
group_pref_mat1 <- readRDS("../data/derived/data007-preference.rds")
allocated_df1 <- readRDS("../data/derived/data007-allocated.rds")

df_list <- extract_info(dframe = group_comp_df1, assignment = "preference",
                                self_formed_groups = 2,
                                pref_mat = group_pref_mat1)
mdl2_7 <- prepare_model(df_list, assignment = "preference", n_topics=7, B=2,
                        nmin=3, nmax=5, rmin=1, rmax=3)

# Choose your solver here:
result <- solve_model(mdl2_7, with_ROI(solver="gurobi", verbose=TRUE))
# result <- solve_model(mdl2_7, with_ROI(solver="glpk", verbose=TRUE, tm_limit = 2.4e5))
groupr_assigned_df1 <- assign_groups(result, assignment = "preference",
                                     dframe=group_comp_df1,
                                     params_list = list(n_topics=7, B=2),
                                     group_names="group_id")
total_pref <- summary_pba(groupr_assigned_df1, df_list, 7)

allocated_pref_mean_2220 <-
  sum(allocated_df1$pref_for_allocated_topic*allocated_df1$size)/sum(allocated_df1$size)
# 12.70
groupr_pref_mean_2220 <- sum(total_pref$total_pref_score)/NROW(group_comp_df1)
# 13.51

## Semester 2310

group_comp_df1 <- readRDS("../data/derived/data008-composition.rds")
group_pref_mat1 <- readRDS("../data/derived/data008-preference.rds")
allocated_df1 <- readRDS("../data/derived/data008-allocated.rds")

df_list <- extract_student_info(dframe=group_comp_df1, assignment="preference",
                                self_formed_groups = 2,
                                pref_mat = group_pref_mat1)
mdl2_8 <- prepare_model(df_list, assignment="preference", n_topics=5, B=2,
                        nmin=3, nmax=5, rmin=3, rmax=5)

# Choose your solver here:
result <- solve_model(mdl2_8, with_ROI(solver="gurobi", verbose=TRUE))
# result <- solve_model(mdl2_8, with_ROI(solver="glpk", verbose=TRUE, tm_limit = 2.4e5))
groupr_assigned_df1 <- assign_groups(result, assignment = "preference",
                                     dframe=group_comp_df1,
                                     params_list = list(n_topics=5, B=2),
                                     group_names="group_id")
total_pref <- summary_pba(groupr_assigned_df1, df_list, 5)

allocated_pref_mean_2310 <-  sum(allocated_df1$pref_for_allocated_topic*allocated_df1$size)/sum(allocated_df1$size)
# 9.48
groupr_pref_mean_2310 <- sum(total_pref$total_pref_score)/NROW(group_comp_df1)
# 9.66

# Consolidating comparisons
dsa_tbl <- tibble(
       iteration = c(1,2,3,4),
       manual = c(allocated_pref_mean_2120,
                       allocated_pref_mean_2210,
                       allocated_pref_mean_2220,
                       allocated_pref_mean_2310),
       grouper = c(groupr_pref_mean_2120,
                       groupr_pref_mean_2210,
                       groupr_pref_mean_2220,
                       groupr_pref_mean_2310),
       class_size = c(62, 108, 89, 151),
       n_topics = c(4, 7, 7, 5),
       n_project_teams = c(7, 13 , 11, 18)
         )

dsa_tbl %>% pivot_longer(cols=c("manual", "grouper"),
                         names_to = "assignment_type",
                         values_to="mean_preference") %>%
  ggplot(aes(x=iteration)) +
  geom_line(aes(y=mean_preference, color=assignment_type)) +
  geom_point(aes(y=mean_preference, color=assignment_type)) +
  labs(title="Comparison between grouper assignment and manual assignment",
       subtitle="Preference-based assignment",
       x="Iteration (Semester number)",
       y="Mean preference", col="Assignment type")

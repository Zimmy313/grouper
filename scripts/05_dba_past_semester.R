# Script for reproducing analyses on DBA for previous semester
# This model was used to form groups in an interdisciplinary course, with the
# objective of maximising diversity.
#
# In these cases, the Gurobi commercial solver tended to find the optimal
# solution faster than glpk. The figure in the paper was generated using the
# solution from Gurobi.
#
# Set working directory to be scripts/ before running.

library(grouper)
library(ompr)
library(ompr.roi)
library(ROI.plugin.gurobi)
library(ROI.plugin.glpk)
library(tidyverse)

df1 <- readRDS("../data/derived/dba_ex3_composition.rds")
df_list <- extract_info("diversity",
                        dframe=df1, demographic_cols = 2, skills = NULL,
                        self_formed_groups = 1)
m1 <- prepare_model(df_list, assignment="diversity", w1=1.0, n_topics=5,
                    nmin=4, nmax=5, rmin=1, rmax=1)

# Choose your solver here:
result <- solve_assignment(m1, assignment="diversity",
                           solver="gurobi", dframe=df1,
                           verbose=TRUE, group_names = "student_id")

# tm_limit in milliseconds, https://cran.r-universe.dev/Rglpk/doc/manual.html
result <- solve_assignment(m1, assignment="diversity",
                 solver="glpk", dframe=df1,
                 group_names = "student_id",
                 solver_args = list(verbose=TRUE, tm_limit=5e3))
assigned_groups <- result$output

# Plotting
assigned_groups <- rename(assigned_groups,
                          "grouper_assigned"="topic",
                          "manual_assigned" = "assigned_grouping")
assigned_groups %>%
  select(grouper_assigned, group, coded_major, manual_assigned) %>%
  pivot_longer(cols=c("grouper_assigned", "manual_assigned"), names_to="assign_mtd",
               values_to="assign_value") %>%
  ggplot() +
  geom_bar(aes(x=coded_major, fill=coded_major), show.legend = FALSE) +
  facet_wrap(~assign_mtd + assign_value, nrow=2) +
  labs(title="Comparison between grouper assignment and manual assignment",
       x="Coded major", y="Count",
       subtitle="Diversity-based assignment")

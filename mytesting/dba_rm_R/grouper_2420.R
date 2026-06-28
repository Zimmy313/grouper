suppressPackageStartupMessages({
  library(grouper)
  library(ompr)
  library(ompr.roi)
  library(ROI.plugin.glpk)
  library(dplyr)
  library(ggplot2)
  library(tidyverse)
})


# ## ----load-ay2520, include=FALSE-----------------------------------------------
# # Read anonymized student records and course-role demand.
# students_ay2420 <- read.csv(
#   "data/raw/ay2420/students.csv",
#   stringsAsFactors = FALSE
# )
# demand_ay2420 <- read.csv(
#   "data/raw/ay2420/demand.csv",
#   stringsAsFactors = FALSE
# )
# pref_long_ay2420 <- read.csv(
#   "data/raw/ay2420/preferences_long.csv",
#   stringsAsFactors = FALSE
# )
#
# # Use stable ordering so row and column positions have a fixed meaning.
# students_ay2420 <- students_ay2420[order(students_ay2420$student_id), ]
# demand_ay2420 <- demand_ay2420[order(demand_ay2420$course_code), ]
#
# # Convert long-form preference records into matrix row and column indices.
# pref_long_ay2420$i <- match(pref_long_ay2420$student_id, students_ay2420$student_id)
# pref_long_ay2420$j <- match(pref_long_ay2420$course_code, demand_ay2420$course_code)
#
# # Build the student-by-course preference matrix.
# P_ay2420 <- matrix(
#   -99L,
#   nrow = nrow(students_ay2420),
#   ncol = nrow(demand_ay2420)
# )
# P_ay2420[
#   cbind(pref_long_ay2420$i, pref_long_ay2420$j)
# ] <- pref_long_ay2420$pref_score
#
# # Build the course-by-role demand matrix in the role order expected by the model.
# D_ay2420 <- as.matrix(demand_ay2420[, c("TA", "GR", "E")])
#
# ### Save 2520 datasets
# saveRDS(students_ay2420, file="data2420-phd_students.rds")
# saveRDS(P_ay2420, file="data2420-phd_pref.rds")
# saveRDS(D_ay2420, file="data2420-phd_demand.rds")

### Load 2520 datasets
students_ay2420 <- readRDS("data2420-phd_students.rds")
P_ay2420 <- readRDS("data2420-phd_pref.rds")
D_ay2420 <- readRDS("data2420-phd_demand.rds")
demand_ay2420 <- read.csv(
  "data/raw/ay2420/demand.csv",
  stringsAsFactors = FALSE
)

D2_ay2420 <- D_ay2420[, 1:2]

## ----phd-extract-info---------------------------------------------------------
df_phd <- extract_info(
  assignment = "phd",
  student_df = students_ay2420[, c("student_id", "year", "past_ta", "past_gr")],
  p_mat = P_ay2420,
  d_mat = D2_ay2420,
  e_mode = "rr",
  C = 4
)


## ----phd-prepare-model--------------------------------------------------------
model_phd <- prepare_model(
  df_list = df_phd,
  assignment = "phd",
  alpha = 2,
  beta = 1,
  phi = 1,
  rho = 10,
  t_max_y1 = 1,
  e_max = 1,
  C = 4
)


## ----phd-solve-assignment-----------------------------------------------------
phd_solution <- solve_assignment(
  model = model_phd,
  assignment = "phd",
  solver = "glpk",
  student_df = students_ay2420,
  course_codes = demand_ay2420$course_code,
  name_col = "student_id",
  verbose = TRUE
)

soln2_ay2420 <- as_tibble(phd_solution$output) %>%
  pivot_longer(cols=2:last_col(), names_to = "course_role", values_to = "work_units" ) %>%
  filter(work_units > 0) %>%
  separate_wider_delim(course_role, delim="-", names=c("course", "role"))
write.csv(soln2_ay2420, file="soln2_ay2420.csv", row.names = FALSE)
write.csv(phd_solution$output, file='soln2_wide_ay2420.csv', row.names = FALSE)

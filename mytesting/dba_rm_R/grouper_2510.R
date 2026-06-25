# Please edit grouper.Rmd to modify this file

## ----setup, include=FALSE-----------------------------------------------------

required_pkgs <- c(
  "grouper", "ompr", "ompr.roi", "ROI.plugin.glpk", "dplyr", "ggplot2", "tidyverse"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package not installed: ", pkg)
  }
}

suppressPackageStartupMessages({
  library(grouper)
  library(ompr)
  library(ompr.roi)
  library(ROI.plugin.glpk)
  library(dplyr)
  library(ggplot2)
})


## ----load-ay2520, include=FALSE-----------------------------------------------
# Read anonymized student records and course-role demand.
students_ay2510 <- read.csv(
  "data/raw/ay2510/students.csv",
  stringsAsFactors = FALSE
)
demand_ay2510 <- read.csv(
  "data/raw/ay2510/demand.csv",
  stringsAsFactors = FALSE
)
pref_long_ay2510 <- read.csv(
  "data/raw/ay2510/preferences_long.csv",
  stringsAsFactors = FALSE
)

# Use stable ordering so row and column positions have a fixed meaning.
students_ay2510 <- students_ay2510[order(students_ay2510$student_id), ]
demand_ay2510 <- demand_ay2510[order(demand_ay2510$course_code), ]

# Convert long-form preference records into matrix row and column indices.
pref_long_ay2510$i <- match(pref_long_ay2510$student_id, students_ay2510$student_id)
pref_long_ay2510$j <- match(pref_long_ay2510$course_code, demand_ay2510$course_code)

# Build the student-by-course preference matrix.
P_ay2510 <- matrix(
  -99L,
  nrow = nrow(students_ay2510),
  ncol = nrow(demand_ay2510)
)
P_ay2510[
  cbind(pref_long_ay2510$i, pref_long_ay2510$j)
] <- pref_long_ay2510$pref_score

# Build the course-by-role demand matrix in the role order expected by the model.
D_ay2510 <- as.matrix(demand_ay2510[, c("TA", "GR", "E")])

### Save 2520 datasets
saveRDS(students_ay2510, file="data2510-phd_students.rds")
saveRDS(P_ay2510, file="data2510-phd_pref.rds")
saveRDS(D_ay2510, file="data2510-phd_demand.rds")

### Load 2520 datasets
students_ay2520 <- readRDS("data2520-phd_students.rds")
P_ay2520 <- readRDS("data2520-phd_pref.rds")
D_ay2520 <- readRDS("data2520-phd_demand.rds")

## ----phd-extract-info---------------------------------------------------------
df_phd <- extract_info(
  assignment = "phd",
  student_df = students_ay2510[, c("student_id", "year", "past_ta", "past_gr")],
  p_mat = P_ay2510,
  d_mat = D_ay2510,
  e_mode = "none",
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
  student_df = students_ay2510,
  course_codes = demand_ay2510$course_code,
  name_col = "student_id",
  verbose = TRUE
)

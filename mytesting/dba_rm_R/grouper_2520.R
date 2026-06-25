# Please edit grouper.Rmd to modify this file

## ----setup, include=FALSE-----------------------------------------------------

required_pkgs <- c(
  "grouper", "ompr", "ompr.roi", "ROI.plugin.glpk", "dplyr", "ggplot2"
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


### Load 2520 datasets
students_ay2520 <- readRDS("data2520-phd_students.rds")
P_ay2520 <- readRDS("data2520-phd_pref.rds")
D_ay2520 <- readRDS("data2520-phd_demand.rds")
demand_ay2520 <- read.csv(
  "data/raw/ay2520/demand.csv",
  stringsAsFactors = FALSE
)

## ----phd-extract-info---------------------------------------------------------
df_phd <- extract_info(
  assignment = "phd",
  student_df = students_ay2520[, c("student_id", "year", "past_ta", "past_gr")],
  p_mat = P_ay2520,
  d_mat = D_ay2520,
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
  student_df = students_ay2520,
  course_codes = demand_ay2520$course_code,
  name_col = "student_id",
  verbose = FALSE
)

as_tibble(phd_solution$output) %>%
  pivot_longer(cols=2:last_col(), names_to = "course_role", values_to = "work_units" ) %>%
  filter(work_units > 0) %>%
  separate_wider_delim(course_role, delim="-", names=c("course", "role"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

raw_dir <- "data/raw/ay2520"
alpha <- 2; beta <- 1; phi <- 1; rho <- 10; t_max_y1 <- 1

students <- read_csv(file.path(raw_dir, "students.csv"), show_col_types = FALSE) |>
  arrange(student_id)
demand <- read_csv(file.path(raw_dir, "demand.csv"), show_col_types = FALSE) |>
  arrange(course_code)
pref_long <- read_csv(file.path(raw_dir, "preferences_long.csv"), show_col_types = FALSE)
manual_totals <- read_csv(file.path(raw_dir, "manual_totals.csv"), show_col_types = FALSE) |>
  arrange(student_id)
manual_ta <- read_csv(file.path(raw_dir, "manual_ta_by_course.csv"), show_col_types = FALSE)

pref_long <- pref_long |>
  mutate(
    i = match(student_id, students$student_id),
    j = match(course_code, demand$course_code)
  )

P <- matrix(-99L, nrow = nrow(students), ncol = nrow(demand))
P[cbind(pref_long$i, pref_long$j)] <- pref_long$pref_score

manual_ta <- manual_ta |>
  mutate(
    i = match(student_id, students$student_id),
    j = match(course_code, demand$course_code)
  )

X_ta <- matrix(0, nrow = nrow(students), ncol = nrow(demand))
X_ta[cbind(manual_ta$i, manual_ta$j)] <- manual_ta$ta_units

seniority <- pmin(4, pmax(1, as.numeric(students$year))) - 2
annual_ta <- students$past_ta + manual_totals$manual_ta
ta_spread <- max(annual_ta[seniority >= 0]) - min(annual_ta[seniority >= 0])
pref_sum <- sum(P * X_ta)
seniority_e <- sum(seniority * manual_totals$manual_e)
y1_slack <- sum(pmax(0, manual_totals$manual_ta[seniority == -1] - t_max_y1))

manual_objective <- alpha * ta_spread - beta * pref_sum -
  phi * seniority_e + rho * y1_slack

cat("AY2520 manual objective components\n")
cat("TA spread:", ta_spread, "\n")
cat("TA preference sum:", pref_sum, "\n")
cat("Seniority-weighted E:", seniority_e, "\n")
cat("Year-1 TA slack:", y1_slack, "\n")
cat("Manual objective:", manual_objective, "\n")

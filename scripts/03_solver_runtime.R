suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(grouper)
  library(ompr.roi)
  library(ROI.plugin.glpk)
  library(ROI.plugin.highs)
})

set.seed(1)

raw_dir <- "data/raw/ay2520"
derived_dir <- "data/derived"
dir.create(derived_dir, recursive = TRUE, showWarnings = FALSE)

C <- 4
benchmark_repeats <- 30L

students <- read_csv(file.path(raw_dir, "students.csv"), show_col_types = FALSE) |>
  arrange(student_id)
demand <- read_csv(file.path(raw_dir, "demand.csv"), show_col_types = FALSE) |>
  arrange(course_code)
pref_long <- read_csv(file.path(raw_dir, "preferences_long.csv"), show_col_types = FALSE)

pref_long <- pref_long |>
  mutate(
    i = match(student_id, students$student_id),
    j = match(course_code, demand$course_code)
  )

P <- matrix(-99L, nrow = nrow(students), ncol = nrow(demand))
P[cbind(pref_long$i, pref_long$j)] <- as.integer(pref_long$pref_score)
D <- as.matrix(demand[, c("TA", "GR", "E")])

student_input <- students |>
  transmute(
    student_id,
    year = as.numeric(year),
    past_ta = as.numeric(past_ta),
    past_gr = as.numeric(past_gr)
  )

model_input <- extract_info(
  assignment = "phd",
  student_df = student_input,
  p_mat = P,
  d_mat = D,
  e_mode = "none",
  C = C
)

model <- prepare_model(
  df_list = model_input,
  assignment = "phd",
  alpha = 2,
  beta = 1,
  phi = 1,
  rho = 10,
  t_max_y1 = 1,
  e_max = 1,
  C = C
)

benchmark_solver <- function(solver) {
  rows <- vector("list", benchmark_repeats)

  for (run in seq_len(benchmark_repeats)) {
    timing <- system.time({
      fit <- solve_assignment(
        model = model,
        assignment = "phd",
        solver = solver,
        student_df = student_input,
        course_codes = demand$course_code,
        name_col = "student_id",
        verbose = FALSE
      )
    })

    rows[[run]] <- data.frame(
      Semester = "AY2520",
      Solver = solver,
      Run = run,
      Time_seconds = round(as.numeric(timing[["elapsed"]]), 6),
      Objective = round(as.numeric(fit$model_result$objective_value)[[1]], 4),
      stringsAsFactors = FALSE
    )
  }

  bind_rows(rows)
}

solver_runtime <- bind_rows(
  benchmark_solver("glpk"),
  benchmark_solver("highs")
)

if (!all(solver_runtime$Objective == solver_runtime$Objective[[1]])) {
  stop("Benchmark objectives are not identical across solvers/runs.", call. = FALSE)
}

write_csv(solver_runtime, file.path(derived_dir, "ay2520_solver_runtime.csv"))

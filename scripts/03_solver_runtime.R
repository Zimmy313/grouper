suppressPackageStartupMessages({
  library(ROI.plugin.glpk)
  library(ROI.plugin.highs)
})

source("scripts/multirole_helpers.R")
set.seed(1)

benchmark_repeats <- 30L
problem <- build_multirole_problem("ay2520", e_max = 1)

benchmark_solver <- function(solver) {
  bind_rows(lapply(seq_len(benchmark_repeats), function(run) {
    timing <- system.time(fit <- solve_multirole_problem(problem, solver))
    tibble(
      Semester = "AY2520",
      Solver = solver,
      Run = run,
      Time_seconds = round(as.numeric(timing[["elapsed"]]), 6),
      Objective = round(objective_value(fit$model_result), 4)
    )
  }))
}

write_csv(
  bind_rows(lapply(c("glpk", "highs"), benchmark_solver)),
  "data/derived/ay2520_solver_runtime.csv"
)

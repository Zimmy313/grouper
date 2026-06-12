suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ROI.plugin.glpk)
})

source("scripts/multirole_helpers.R")
set.seed(1)

base_weights <- list(alpha = 2, beta = 1, phi = 1, rho = 10, t_max_y1 = 1)
grid <- list(
  alpha = c(1, 2, 4),
  beta = c(0.75, 1, 1.25),
  phi = c(0.75, 1, 1.25),
  rho = c(7.5, 10, 12.5)
)

run_setting <- function(parameter, value) {
  cat("Solving", parameter, "=", value, "\n")
  weights <- base_weights
  weights[[parameter]] <- value
  case <- run_multirole_case("ay2520", e_max = 1, weights = weights)

  tibble::tibble(
    Parameter = parameter,
    Value = value,
    Objective = objective_value(case$model_result),
    TA_spread = case$model_breakdown$ta_spread,
    TA_preference = case$model_breakdown$ta_pref_sum,
    Seniority_E = case$model_breakdown$seniority_e_sum,
    Year1_slack = case$model_breakdown$y1_slack_sum
  )
}

sensitivity <- bind_rows(lapply(names(grid), function(parameter) {
  bind_rows(lapply(grid[[parameter]], run_setting, parameter = parameter))
}))

cat("AY2520 one-at-a-time hyperparameter sensitivity\n\n")
print(sensitivity, n = Inf)

cat("\nRange by varied parameter\n")
sensitivity |>
  group_by(Parameter) |>
  summarise(
    TA_spread = paste(range(TA_spread), collapse = " to "),
    TA_preference = paste(range(TA_preference), collapse = " to "),
    Seniority_E = paste(range(Seniority_E), collapse = " to "),
    Year1_slack = paste(range(Year1_slack), collapse = " to "),
    .groups = "drop"
  ) |>
  print(n = Inf)

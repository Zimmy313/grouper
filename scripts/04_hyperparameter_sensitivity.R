suppressPackageStartupMessages(library(ROI.plugin.glpk))

source("scripts/multirole_helpers.R")
set.seed(1)

grid <- list(
  alpha_ta = c(1, 2, 4),
  beta_ta = c(0.75, 1, 1.25),
  phi = c(0.75, 1, 1.25),
  rho_ta = c(7.5, 10, 12.5)
)

run_setting <- function(parameter, value) {
  weights <- manuscript_weights()
  weights[[parameter]] <- value
  case <- run_multirole_case("ay2520", e_max = 1, weights = weights)
  tibble(
    Parameter = parameter,
    Value = value,
    Objective = objective_value(case$model_result),
    TA_spread = case$model_breakdown$ta_spread,
    TA_preference = case$model_breakdown$ta_pref_sum,
    Seniority_E = case$model_breakdown$seniority_e_sum,
    Year1_TA_slack = case$model_breakdown$ta_protected_slack_sum
  )
}

sensitivity <- bind_rows(lapply(names(grid), function(parameter) {
  bind_rows(lapply(grid[[parameter]], run_setting, parameter = parameter))
}))

print(sensitivity, n = Inf)
sensitivity |>
  group_by(Parameter) |>
  summarise(
    TA_spread = paste(range(TA_spread), collapse = " to "),
    TA_preference = paste(range(TA_preference), collapse = " to "),
    Seniority_E = paste(range(Seniority_E), collapse = " to "),
    Year1_TA_slack = paste(range(Year1_TA_slack), collapse = " to "),
    .groups = "drop"
  ) |>
  print(n = Inf)

suppressPackageStartupMessages({
  library(tidyr)
  library(ROI.plugin.glpk)
})

source("scripts/multirole_helpers.R")
set.seed(1)

derived_dir <- "data/derived"
weights <- manuscript_weights()
semester_cfg <- tibble(
  Semester = c("AY2420", "AY2510", "AY2520"),
  prefix = c("ay2420", "ay2510", "ay2520"),
  e_max = c(1, 2, 1)
)

semester_summary <- function(case, Semester) {
  inputs <- case$inputs
  tibble(
    Semester = Semester,
    Students = nrow(inputs$students),
    Courses = nrow(inputs$demand),
    TA = sum(inputs$demand$TA),
    GR = sum(inputs$demand$GR),
    E = sum(inputs$demand$E),
    Y1 = sum(inputs$students$year == 1),
    Y2 = sum(inputs$students$year == 2),
    Y3 = sum(inputs$students$year == 3),
    Y4 = sum(inputs$students$year == 4)
  )
}

objective_terms <- function(case, Semester) {
  bind_rows(Model = case$model_breakdown, Manual = case$manual_breakdown, .id = "Schedule") |>
    mutate(
      Semester = Semester,
      ta_fairness_term = weights$alpha_ta * ta_spread,
      ta_preference_term = -weights$beta_ta * ta_pref_sum,
      seniority_e_term = -weights$phi * seniority_e_sum,
      ta_protection_term = weights$rho_ta * ta_protected_slack_sum
    ) |>
    select(
      Semester, Schedule,
      ta_fairness_term, ta_preference_term, seniority_e_term,
      ta_protection_term, objective_recalc,
      ta_spread, ta_pref_sum, seniority_e_sum, ta_protected_slack_sum
    )
}

distribution_data <- function(case) {
  case$inputs$students |>
    select(student_id, year, past_ta, past_gr) |>
    left_join(case$model_totals, by = "student_id") |>
    arrange(year, student_id) |>
    transmute(
      student_id, year,
      current_ta = TA, current_gr = GR, current_e = E,
      past_ta, past_gr
    ) |>
    pivot_longer(
      cols = c(current_ta, current_gr, current_e, past_ta, past_gr),
      names_to = "component",
      values_to = "units"
    ) |>
    mutate(
      component = recode(
        component,
        current_ta = "Current TA",
        current_gr = "Current GR",
        current_e = "Current E",
        past_ta = "Past TA",
        past_gr = "Past GR"
      )
    )
}

cases <- lapply(seq_len(nrow(semester_cfg)), function(i) {
  cfg <- semester_cfg[i, ]
  case <- run_multirole_case(cfg$prefix, cfg$e_max, weights)
  list(
    Semester = cfg$Semester,
    dataset = semester_summary(case, cfg$Semester),
    objective_compare = tibble(
      Semester = cfg$Semester,
      Model_objective = objective_value(case$model_result),
      Manual_objective = case$manual_breakdown$objective_recalc
    ),
    objective_terms = objective_terms(case, cfg$Semester),
    distribution = distribution_data(case)
  )
})

write_csv(bind_rows(lapply(cases, `[[`, "dataset")),
          file.path(derived_dir, "multi_role_dataset_summary.csv"))
write_csv(bind_rows(lapply(cases, `[[`, "objective_compare")),
          file.path(derived_dir, "multi_role_objective_comparison.csv"))
write_csv(bind_rows(lapply(cases, `[[`, "objective_terms")),
          file.path(derived_dir, "multi_role_objective_terms.csv"))
write_csv(cases[[which(semester_cfg$Semester == "AY2520")]]$distribution,
          file.path(derived_dir, "ay2520_distribution_long.csv"))

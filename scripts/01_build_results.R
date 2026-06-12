suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ROI.plugin.glpk)
})

source("scripts/multirole_helpers.R")
set.seed(1)

derived_dir <- "data/derived"
dir.create(derived_dir, recursive = TRUE, showWarnings = FALSE)

weights <- list(alpha = 2, beta = 1, phi = 1, rho = 10, t_max_y1 = 1)
semester_cfg <- tibble::tibble(
  Semester = c("AY2420", "AY2510", "AY2520"),
  prefix = c("ay2420", "ay2510", "ay2520"),
  e_max = c(1, 2, 1)
)

build_semester_results <- function(Semester, prefix, e_max) {
  case <- run_multirole_case(prefix, e_max, weights)
  inputs <- case$inputs

  dataset <- tibble::tibble(
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

  objective_compare <- tibble::tibble(
    Semester = Semester,
    Model_objective = objective_value(case$model_result),
    Manual_objective = case$manual_breakdown$objective_recalc
  )

  objective_terms <- bind_rows(
    Model = case$model_breakdown,
    Manual = case$manual_breakdown,
    .id = "Schedule"
  ) |>
    mutate(
      Semester = Semester,
      fairness_term = weights$alpha * ta_spread,
      preference_term = -weights$beta * ta_pref_sum,
      seniority_e_term = -weights$phi * seniority_e_sum,
      y1_slack_term = weights$rho * y1_slack_sum
    ) |>
    select(
      Semester,
      Schedule,
      fairness_term,
      preference_term,
      seniority_e_term,
      y1_slack_term,
      objective_recalc,
      ta_spread,
      ta_pref_sum,
      seniority_e_sum,
      y1_slack_sum
    )

  distribution_long <- NULL
  if (Semester == "AY2520") {
    distribution_long <- inputs$students |>
      select(student_id, year, past_ta, past_gr) |>
      left_join(case$model_totals, by = "student_id") |>
      arrange(year, student_id) |>
      transmute(
        student_id,
        year,
        current_ta = TA,
        current_gr = GR,
        current_e = E,
        past_ta,
        past_gr
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

  list(
    dataset = dataset,
    objective_compare = objective_compare,
    objective_terms = objective_terms,
    distribution_long = distribution_long
  )
}

results <- lapply(seq_len(nrow(semester_cfg)), function(i) {
  build_semester_results(
    Semester = semester_cfg$Semester[[i]],
    prefix = semester_cfg$prefix[[i]],
    e_max = semester_cfg$e_max[[i]]
  )
})

write_csv(
  bind_rows(lapply(results, `[[`, "dataset")),
  file.path(derived_dir, "multi_role_dataset_summary.csv")
)
write_csv(
  bind_rows(lapply(results, `[[`, "objective_compare")),
  file.path(derived_dir, "multi_role_objective_comparison.csv")
)
write_csv(
  bind_rows(lapply(results, `[[`, "objective_terms")),
  file.path(derived_dir, "multi_role_objective_terms.csv")
)
write_csv(
  results[[which(semester_cfg$Semester == "AY2520")]]$distribution_long,
  file.path(derived_dir, "ay2520_distribution_long.csv")
)

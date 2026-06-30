suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(grouper)
  library(ompr)
  library(ompr.roi)
})

manuscript_weights <- function(alpha_ta = 2, beta_ta = 1, phi = 1,
                               rho_ta = 10) {
  list(
    alpha_ta = alpha_ta,
    beta_ta = beta_ta,
    phi = phi,
    rho_ta = rho_ta,
    protected_year_ta = 1,
    ta_protected_max = 1
  )
}

objective_value <- function(model_result) {
  as.numeric(model_result$objective_value)[[1]]
}

build_multirole_problem <- function(prefix, e_max, weights = manuscript_weights(),
                                    raw_dir = "data/raw", C = 4) {
  semester_dir <- file.path(raw_dir, prefix)
  students <- read_csv(file.path(semester_dir, "students.csv"), show_col_types = FALSE) |>
    arrange(student_id)
  demand <- read_csv(file.path(semester_dir, "demand.csv"), show_col_types = FALSE) |>
    arrange(course_code)
  pref_idx <- read_csv(
    file.path(semester_dir, "preferences_long.csv"),
    show_col_types = FALSE
  ) |>
    mutate(
      i = match(student_id, students$student_id),
      j = match(course_code, demand$course_code)
    )
  P <- matrix(-99L, nrow = nrow(students), ncol = nrow(demand))
  P[cbind(pref_idx$i, pref_idx$j)] <- as.integer(pref_idx$pref_score)

  inputs <- list(
    students = students,
    demand = demand,
    P = P,
    D = as.matrix(demand[, c("TA", "GR", "E")]),
    manual_totals = read_csv(
      file.path(semester_dir, "manual_totals.csv"),
      show_col_types = FALSE
    ) |>
      arrange(student_id),
    manual_ta = read_csv(
      file.path(semester_dir, "manual_ta_by_course.csv"),
      show_col_types = FALSE
    ),
    course_codes = demand$course_code
  )
  student_input <- students |>
    transmute(
      student_id,
      year = as.numeric(year),
      past_ta = as.numeric(past_ta),
      past_gr = as.numeric(past_gr)
    )
  model_input <- extract_info(
    assignment = "multirole",
    student_df = student_input,
    d_mat = inputs$D,
    p_ta_mat = inputs$P,
    e_mode = "none",
    C = C
  )
  model <- prepare_model(
    model_input,
    assignment = "multirole",
    alpha_ta = weights$alpha_ta,
    alpha_gr = NULL,
    beta_ta = weights$beta_ta,
    beta_gr = NULL,
    phi = weights$phi,
    rho_ta = weights$rho_ta,
    rho_gr = NULL,
    protected_year_ta = weights$protected_year_ta,
    ta_protected_max = weights$ta_protected_max,
    e_max = e_max
  )
  list(
    inputs = inputs,
    student_input = student_input,
    model_input = model_input,
    model = model
  )
}

solve_multirole_problem <- function(problem, solver = "glpk") {
  solve_assignment(
    model = problem$model,
    assignment = "multirole",
    solver = solver,
    student_df = problem$student_input,
    course_codes = problem$inputs$course_codes,
    name_col = "student_id",
    verbose = FALSE
  )
}

manual_pref_sum <- function(manual_ta, students, demand, P) {
  idx <- manual_ta |>
    mutate(
      i = match(student_id, students$student_id),
      j = match(course_code, demand$course_code)
    )
  sum(idx$ta_units * P[cbind(idx$i, idx$j)])
}

objective_components <- function(ta, e, pref_sum, t1, s, year, weights) {
  annual_ta <- t1 + ta
  protected <- year == weights$protected_year_ta
  ta_spread <- max(annual_ta[!protected]) - min(annual_ta[!protected])
  seniority_e_sum <- sum(s * e)
  ta_protected_slack_sum <- sum(pmax(0, ta[protected] - weights$ta_protected_max))

  tibble(
    ta_spread = ta_spread,
    ta_pref_sum = pref_sum,
    seniority_e_sum = seniority_e_sum,
    ta_protected_slack_sum = ta_protected_slack_sum,
    objective_recalc = weights$alpha_ta * ta_spread -
      weights$beta_ta * pref_sum -
      weights$phi * seniority_e_sum +
      weights$rho_ta * ta_protected_slack_sum
  )
}

run_multirole_case <- function(prefix, e_max, weights = manuscript_weights(),
                               raw_dir = "data/raw", C = 4, solver = "glpk") {
  problem <- build_multirole_problem(prefix, e_max, weights, raw_dir, C)
  fit <- solve_multirole_problem(problem, solver)
  inputs <- problem$inputs
  model_input <- problem$model_input
  model_totals <- tibble(
    student_id = as.character(fit$output$Name),
    TA = rowSums(fit$output[, grepl("-t$", names(fit$output)), drop = FALSE]),
    GR = rowSums(fit$output[, grepl("-g$", names(fit$output)), drop = FALSE]),
    E = rowSums(fit$output[, grepl("-e$", names(fit$output)), drop = FALSE])
  ) |>
    arrange(student_id)
  ta_solution <- ompr::get_solution(fit$model_result, X[i, j, r]) |>
    filter(r == 1, value > 1e-8)
  model_ta_pref_sum <- sum(
    ta_solution$value * inputs$P[cbind(ta_solution$i, ta_solution$j)]
  )

  list(
    inputs = inputs,
    student_input = problem$student_input,
    model_input = model_input,
    model_result = fit$model_result,
    output = fit$output,
    model_totals = model_totals,
    model_breakdown = objective_components(
      model_totals$TA,
      model_totals$E,
      model_ta_pref_sum,
      model_input$t1,
      model_input$s,
      model_input$year,
      weights
    ),
    manual_breakdown = objective_components(
      inputs$manual_totals$manual_ta,
      inputs$manual_totals$manual_e,
      manual_pref_sum(inputs$manual_ta, inputs$students, inputs$demand, inputs$P),
      model_input$t1,
      model_input$s,
      model_input$year,
      weights
    )
  )
}

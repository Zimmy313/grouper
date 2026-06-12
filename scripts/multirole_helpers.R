suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(grouper)
  library(ompr)
  library(ompr.roi)
})

read_semester_inputs <- function(prefix, raw_dir = "data/raw") {
  semester_dir <- file.path(raw_dir, prefix)

  students <- read_csv(file.path(semester_dir, "students.csv"), show_col_types = FALSE) |>
    arrange(student_id)
  demand <- read_csv(file.path(semester_dir, "demand.csv"), show_col_types = FALSE) |>
    arrange(course_code)
  pref_long <- read_csv(file.path(semester_dir, "preferences_long.csv"), show_col_types = FALSE)
  manual_totals <- read_csv(file.path(semester_dir, "manual_totals.csv"), show_col_types = FALSE) |>
    arrange(student_id)
  manual_ta <- read_csv(file.path(semester_dir, "manual_ta_by_course.csv"), show_col_types = FALSE)

  pref_long <- pref_long |>
    mutate(
      i = match(student_id, students$student_id),
      j = match(course_code, demand$course_code)
    )

  P <- matrix(-99L, nrow = nrow(students), ncol = nrow(demand))
  P[cbind(pref_long$i, pref_long$j)] <- as.integer(pref_long$pref_score)

  list(
    students = students,
    demand = demand,
    P = P,
    D = as.matrix(demand[, c("TA", "GR", "E")]),
    manual_totals = manual_totals,
    manual_ta = manual_ta,
    course_codes = demand$course_code
  )
}

student_model_input <- function(students) {
  students |>
    transmute(
      student_id,
      year = as.numeric(year),
      past_ta = as.numeric(past_ta),
      past_gr = as.numeric(past_gr)
    )
}

objective_value <- function(model_result) {
  as.numeric(model_result$objective_value)[[1]]
}

scalar_value <- function(x) {
  if (is.data.frame(x)) {
    return(as.numeric(x$value[[1]]))
  }
  as.numeric(x)[[1]]
}

compute_obj_components <- function(ta_by_student, e_by_student, ta_pref_sum,
                                   t1, s, weights) {
  idx_non_y1 <- which(s >= 0)
  idx_y1 <- which(s == -1)
  year_ta <- t1 + ta_by_student
  ta_spread <- max(year_ta[idx_non_y1]) - min(year_ta[idx_non_y1])
  seniority_e_sum <- sum(s * e_by_student)
  y1_slack_sum <- sum(pmax(0, ta_by_student[idx_y1] - weights$t_max_y1))

  tibble::tibble(
    ta_spread = ta_spread,
    ta_pref_sum = ta_pref_sum,
    seniority_e_sum = seniority_e_sum,
    y1_slack_sum = y1_slack_sum,
    objective_recalc = weights$alpha * ta_spread -
      weights$beta * ta_pref_sum -
      weights$phi * seniority_e_sum +
      weights$rho * y1_slack_sum
  )
}

solution_totals <- function(job_output) {
  ta_cols <- grepl("-t$", names(job_output))
  gr_cols <- grepl("-g$", names(job_output))
  e_cols <- grepl("-e$", names(job_output))

  tibble::tibble(
    student_id = as.character(job_output$Name),
    TA = rowSums(job_output[, ta_cols, drop = FALSE]),
    GR = rowSums(job_output[, gr_cols, drop = FALSE]),
    E = rowSums(job_output[, e_cols, drop = FALSE])
  ) |>
    arrange(student_id)
}

ta_solution <- function(model_result, P) {
  ompr::get_solution(model_result, X[i, j, r]) |>
    filter(r == 1, value > 1e-8) |>
    transmute(
      i = as.integer(i),
      j = as.integer(j),
      units = as.numeric(value),
      pref_score = P[cbind(i, j)]
    )
}

manual_pref_sum <- function(manual_ta, students, demand, P) {
  manual_ta <- manual_ta |>
    mutate(
      i = match(student_id, students$student_id),
      j = match(course_code, demand$course_code)
    )

  sum(manual_ta$ta_units * P[cbind(manual_ta$i, manual_ta$j)])
}

run_multirole_case <- function(prefix, e_max, weights, raw_dir = "data/raw",
                               C = 4, solver = "glpk") {
  inputs <- read_semester_inputs(prefix, raw_dir)
  student_input <- student_model_input(inputs$students)

  model_input <- extract_info(
    assignment = "phd",
    student_df = student_input,
    p_mat = inputs$P,
    d_mat = inputs$D,
    e_mode = "none",
    C = C
  )

  model <- prepare_model(
    df_list = model_input,
    assignment = "phd",
    alpha = weights$alpha,
    beta = weights$beta,
    phi = weights$phi,
    rho = weights$rho,
    t_max_y1 = weights$t_max_y1,
    e_max = e_max,
    C = C
  )

  fit <- solve_assignment(
    model = model,
    assignment = "phd",
    solver = solver,
    student_df = student_input,
    course_codes = inputs$course_codes,
    name_col = "student_id",
    verbose = FALSE
  )

  model_result <- fit$model_result
  model_totals <- solution_totals(fit$output)
  ta_sol <- ta_solution(model_result, inputs$P)
  model_pref_sum <- sum(ta_sol$units * ta_sol$pref_score)
  manual_pref <- manual_pref_sum(inputs$manual_ta, inputs$students, inputs$demand, inputs$P)

  model_breakdown <- compute_obj_components(
    ta_by_student = model_totals$TA,
    e_by_student = model_totals$E,
    ta_pref_sum = model_pref_sum,
    t1 = model_input$t1,
    s = model_input$s,
    weights = weights
  )

  manual_breakdown <- compute_obj_components(
    ta_by_student = inputs$manual_totals$manual_ta,
    e_by_student = inputs$manual_totals$manual_e,
    ta_pref_sum = manual_pref,
    t1 = model_input$t1,
    s = model_input$s,
    weights = weights
  )

  list(
    inputs = inputs,
    student_input = student_input,
    model_input = model_input,
    model_result = model_result,
    output = fit$output,
    model_totals = model_totals,
    ta_solution = ta_sol,
    model_breakdown = model_breakdown,
    manual_breakdown = manual_breakdown
  )
}

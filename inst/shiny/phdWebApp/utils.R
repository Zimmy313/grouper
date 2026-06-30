`%>%` <- dplyr::`%>%`

# ---- Text Normalisation Helpers ----
# Standardise names for robust join keys across uploads.
standardise_name <- function(x) {
  x <- as.character(x)
  x <- stringr::str_to_upper(x)
  x <- stringr::str_replace_all(x, "[^A-Z ]", "")
  stringr::str_squish(x)
}

# Normalise course codes to uppercase without outer whitespace.
norm_code <- function(x) {
  toupper(trimws(as.character(x)))
}

# Convert empty / sentinel preference values to NA.
clean_pref_code <- function(x) {
  out <- norm_code(x)
  out[out %in% c("", "-", "NIL", "NA", "N/A", "NONE")] <- NA_character_
  out
}


# ---- File Reading & Template Checks ----
read_uploaded_table <- function(path) {
  as.data.frame(
    readxl::read_excel(path, sheet = 1, .name_repair = "minimal"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

validate_exact_columns <- function(df, expected_cols, label) {
  if (!identical(names(df), expected_cols)) {
    stop(label, " tab must match the template columns.")
  }

  invisible(TRUE)
}

validate_current_semester_file <- function(path) {
  expected_sheets <- c("students", "demand")
  sheet_names <- readxl::excel_sheets(path)

  if (!setequal(sheet_names, expected_sheets) || length(sheet_names) != 2) {
    stop("Current semester file must contain exactly the template sheets.")
  }

  students <- as.data.frame(
    readxl::read_excel(path, sheet = "students", .name_repair = "minimal"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  demand <- as.data.frame(
    readxl::read_excel(path, sheet = "demand", .name_repair = "minimal"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  validate_exact_columns(
    students,
    expected_cols = c("student_id", "Name", "year", "first", "second", "third"),
    label = "students"
  )
  validate_exact_columns(
    demand,
    expected_cols = c("course_code", "TA", "GR"),
    label = "demand"
  )

  list(students = students, demand = demand)
}

# ---- Core Parsing Helpers ----

summarise_past_workload <- function(previous_output) {
  ta_cols <- grep("-t$", names(previous_output), value = TRUE, ignore.case = TRUE)
  gr_cols <- grep("-g$", names(previous_output), value = TRUE, ignore.case = TRUE)
  stopifnot(length(ta_cols) > 0, length(gr_cols) > 0)

  ta_mat <- suppressWarnings(data.matrix(previous_output[, ta_cols, drop = FALSE]))
  gr_mat <- suppressWarnings(data.matrix(previous_output[, gr_cols, drop = FALSE]))
  ta_sum <- rowSums(ta_mat, na.rm = TRUE)
  gr_sum <- rowSums(gr_mat, na.rm = TRUE)

  out <- data.frame(
    name_key = standardise_name(previous_output$Name),
    past_ta = ta_sum,
    past_gr = gr_sum,
    stringsAsFactors = FALSE
  )

  out <- out[out$name_key != "", , drop = FALSE]

  dplyr::as_tibble(out) %>%
    dplyr::group_by(.data$name_key) %>%
    dplyr::summarise(
      past_ta = sum(.data$past_ta, na.rm = TRUE),
      past_gr = sum(.data$past_gr, na.rm = TRUE),
      .groups = "drop"
    )
}

# Pad previous workload to the semester capacity when the uploaded output is short.
pad_past_workload_capacity <- function(students_joined, C) {
  past_total <- as.numeric(students_joined$past_ta) + as.numeric(students_joined$past_gr)
  deficit <- pmax(0, C - past_total)
  students_joined$past_gr <- as.numeric(students_joined$past_gr) + deficit
  students_joined$past_ta <- as.numeric(students_joined$past_ta)
  students_joined
}

build_preference_matrix <- function(students_clean, course_codes) {
  ns <- nrow(students_clean)
  nj <- length(course_codes)

  p_mat <- matrix(-99L, nrow = ns, ncol = nj)
  colnames(p_mat) <- course_codes

  for (i in seq_len(ns)) {
    choices <- c(
      third = students_clean$third[[i]],
      second = students_clean$second[[i]],
      first = students_clean$first[[i]]
    )
    scores <- c(third = 1L, second = 2L, first = 3L)

    for (nm in names(choices)) {
      code <- choices[[nm]]
      if (is.na(code) || code == "") {
        next
      }
      j <- match(code, course_codes)
      if (!is.na(j)) {
        p_mat[i, j] <- scores[[nm]]
      }
    }
  }

  p_mat
}


# ---- Model Input Assembly ----
prepare_multirole_run_inputs <- function(students, demand, previous_output = NULL,
                                         C = 4, single_semester = FALSE,
                                         s = c(-1, 0, 1, 2)) {
  C <- as.integer(round(C))

  students_clean <- students %>%
    dplyr::transmute(
      student_id = .data$student_id,
      Name = stringr::str_squish(as.character(.data$Name)),
      year = suppressWarnings(as.numeric(.data$year)),
      first = clean_pref_code(.data$first),
      second = clean_pref_code(.data$second),
      third = clean_pref_code(.data$third)
    )
  students_clean$name_key <- standardise_name(students_clean$Name)
  students_clean$year <- as.integer(round(students_clean$year))

  demand_clean <- demand %>%
    dplyr::transmute(
      course_code = norm_code(.data$course_code),
      TA = suppressWarnings(as.numeric(.data$TA)),
      GR = suppressWarnings(as.numeric(.data$GR))
    )

  demand_clean$TA <- as.integer(round(demand_clean$TA))
  demand_clean$GR <- as.integer(round(demand_clean$GR))

  ns <- nrow(students_clean)
  total_e <- ns * C - sum(demand_clean$TA) - sum(demand_clean$GR)

  if (single_semester) {
    students_joined <- students_clean
    students_joined$past_ta <- 0
    students_joined$past_gr <- C

    student_input <- students_joined %>%
      dplyr::transmute(
        student_id = .data$student_id,
        year = .data$year
      )
  } else {
    past_summary <- summarise_past_workload(previous_output)
    students_joined <- students_clean %>%
      dplyr::left_join(past_summary, by = "name_key")

    students_joined$past_ta[is.na(students_joined$past_ta)] <- 0
    students_joined$past_gr[is.na(students_joined$past_gr)] <- 0
    students_joined <- pad_past_workload_capacity(students_joined, C)

    student_input <- students_joined %>%
      dplyr::transmute(
        student_id = .data$student_id,
        year = .data$year,
        past_ta = as.numeric(.data$past_ta),
        past_gr = as.numeric(.data$past_gr)
      )
  }

  course_codes <- demand_clean$course_code
  p_mat <- build_preference_matrix(students_joined, course_codes)

  df_list <- grouper::extract_multirole_info(
    student_df = as.data.frame(student_input, stringsAsFactors = FALSE),
    d_mat = as.matrix(demand_clean[, c("TA", "GR")]),
    p_ta_mat = p_mat,
    p_gr_mat = p_mat,
    e_mode = "rr",
    C = C,
    s = s,
    single_semester = single_semester
  )

  demand_clean$E <- as.integer(round(df_list$d[, "E"]))

  list(
    students = students_joined %>% dplyr::select("student_id", "Name", "year", "past_ta", "past_gr"),
    demand = demand_clean,
    course_codes = course_codes,
    p_ta_mat = p_mat,
    p_gr_mat = p_mat,
    d_mat = df_list$d,
    df_list = df_list,
    total_e = total_e,
    single_semester = single_semester
  )
}


# ---- Solver Control ----
make_roi_control <- function(solver = c("gurobi", "glpk", "highs"),
                             time_limit = 0, iteration_limit = 0) {
  solver <- match.arg(solver)
  plugin_pkg <- switch(
    solver,
    gurobi = "ROI.plugin.gurobi",
    glpk = "ROI.plugin.glpk",
    highs = "ROI.plugin.highs"
  )
  requireNamespace(plugin_pkg)

  roi_args <- list(solver = solver, verbose = TRUE)

  if (solver == "gurobi") {
    if (is.numeric(time_limit) && length(time_limit) == 1 && !is.na(time_limit) && time_limit > 0) {
      roi_args$TimeLimit <- time_limit
    }
    if (is.numeric(iteration_limit) && length(iteration_limit) == 1 &&
        !is.na(iteration_limit) && iteration_limit > 0) {
      roi_args$IterationLimit <- as.integer(round(iteration_limit))
    }

  }

  do.call(ompr.roi::with_ROI, roi_args)
}


# ---- Post-solve Summaries & Diagnostics ----
# Build per-student TA/GR/E summary directly from assign_job() output.
summarise_assignment_from_job_output <- function(assignment_tbl, students_df) {
  ta_cols <- grep("-t$", names(assignment_tbl), value = TRUE, ignore.case = TRUE)
  gr_cols <- grep("-g$", names(assignment_tbl), value = TRUE, ignore.case = TRUE)
  e_cols <- grep("-e$", names(assignment_tbl), value = TRUE, ignore.case = TRUE)

  ta_total <- rowSums(suppressWarnings(data.matrix(assignment_tbl[, ta_cols, drop = FALSE])), na.rm = TRUE)
  gr_total <- rowSums(suppressWarnings(data.matrix(assignment_tbl[, gr_cols, drop = FALSE])), na.rm = TRUE)
  e_total <- rowSums(suppressWarnings(data.matrix(assignment_tbl[, e_cols, drop = FALSE])), na.rm = TRUE)

  data.frame(
    student_id = students_df$student_id,
    student_name = students_df$Name,
    year = students_df$year,
    TA = as.integer(round(ta_total)),
    GR = as.integer(round(gr_total)),
    E = as.integer(round(e_total)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

compute_role_preference_attainment <- function(solution, p_mat, role_id,
                                               role_label, total_demand) {
  role_sol <- solution[
    solution$r == role_id & solution$value > 1e-8,
    c("i", "j", "value"),
    drop = FALSE
  ]

  units <- c(First = 0, Second = 0, Third = 0, Unranked = 0)

  if (nrow(role_sol) > 0) {
    for (k in seq_len(nrow(role_sol))) {
      i <- role_sol$i[[k]]
      j <- role_sol$j[[k]]
      v <- role_sol$value[[k]]

      score <- p_mat[[i, j]]
      if (is.na(score)) {
        units[["Unranked"]] <- units[["Unranked"]] + v
      } else if (score >= 3) {
        units[["First"]] <- units[["First"]] + v
      } else if (score == 2) {
        units[["Second"]] <- units[["Second"]] + v
      } else if (score == 1) {
        units[["Third"]] <- units[["Third"]] + v
      } else {
        units[["Unranked"]] <- units[["Unranked"]] + v
      }
    }
  }

  out <- data.frame(
    role = role_label,
    preference_rank = c("First", "Second", "Third", "Unranked"),
    units = as.numeric(units[c("First", "Second", "Third", "Unranked")]),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  if (is.numeric(total_demand) && length(total_demand) == 1 && total_demand > 0) {
    out$pct_of_role_demand <- round(100 * out$units / total_demand, 1)
  } else {
    out$pct_of_role_demand <- NA_real_
  }

  out
}

compute_preference_attainment <- function(model_result, p_ta_mat, p_gr_mat,
                                          total_ta_demand, total_gr_demand) {
  sol <- ompr::get_solution(model_result, X[i, j, r])

  rbind(
    compute_role_preference_attainment(
      solution = sol,
      p_mat = p_ta_mat,
      role_id = 1,
      role_label = "TA",
      total_demand = total_ta_demand
    ),
    compute_role_preference_attainment(
      solution = sol,
      p_mat = p_gr_mat,
      role_id = 2,
      role_label = "GR",
      total_demand = total_gr_demand
    )
  )
}

compute_student_diagnostics <- function(alloc_summary, t1, g1) {
  student_df <- alloc_summary
  student_df$past_TA <- as.numeric(t1)
  student_df$past_GR <- as.numeric(g1)
  student_df$current_TA <- as.numeric(student_df$TA)
  student_df$current_GR <- as.numeric(student_df$GR)
  student_df$current_E <- as.numeric(student_df$E)

  student_df$annual_TA <- student_df$past_TA + student_df$current_TA
  student_df$annual_GR <- student_df$past_GR + student_df$current_GR
  student_df$current_total <- student_df$current_TA + student_df$current_GR + student_df$current_E

  out <- student_df[, c(
    "student_id", "student_name", "year",
    "past_TA", "past_GR",
    "current_TA", "current_GR", "current_E",
    "current_total", "annual_TA", "annual_GR"
  )]

  out <- out[order(out$year, out$student_id), , drop = FALSE]
  rownames(out) <- NULL
  out
}

safe_extract_scalar <- function(x) {
  if (is.data.frame(x)) {
    if (!"value" %in% names(x) || nrow(x) == 0) {
      return(NA_real_)
    }
    return(as.numeric(x$value[[1]]))
  }

  val <- suppressWarnings(as.numeric(x))
  if (length(val) == 0) {
    return(NA_real_)
  }
  val[[1]]
}

extract_objective_value <- function(model_result) {
  obj <- suppressWarnings(as.numeric(model_result$objective_value))
  if (length(obj) > 0 && !is.na(obj[[1]])) {
    return(obj[[1]])
  }

  fallback <- tryCatch(
    as.numeric(model_result$additional_solver_output$ROI$message$objval),
    error = function(e) NA_real_
  )

  if (length(fallback) == 0 || is.na(fallback[[1]])) {
    return(NA_real_)
  }

  fallback[[1]]
}

safe_solution_scalar <- function(model_result, name) {
  tryCatch(
    switch(
      name,
      Tmax = safe_extract_scalar(ompr::get_solution(model_result, Tmax)),
      Tmin = safe_extract_scalar(ompr::get_solution(model_result, Tmin)),
      Gmax = safe_extract_scalar(ompr::get_solution(model_result, Gmax)),
      Gmin = safe_extract_scalar(ompr::get_solution(model_result, Gmin)),
      NA_real_
    ),
    error = function(e) NA_real_
  )
}

component_status <- function(x) {
  if (!is.null(x) && !is.na(x) && x > 0) {
    return("active")
  }
  "disabled"
}

format_summary_value <- function(x) {
  if (is.na(x)) {
    return(NA_character_)
  }
  format(round(x, 4), trim = TRUE)
}

compute_run_summary <- function(model_result, settings = list()) {
  tmax <- safe_solution_scalar(model_result, "Tmax")
  tmin <- safe_solution_scalar(model_result, "Tmin")
  gmax <- safe_solution_scalar(model_result, "Gmax")
  gmin <- safe_solution_scalar(model_result, "Gmin")
  ta_spread <- if (!is.na(tmax) && !is.na(tmin)) tmax - tmin else NA_real_
  gr_spread <- if (!is.na(gmax) && !is.na(gmin)) gmax - gmin else NA_real_

  get_setting <- function(name) {
    value <- settings[[name]]
    if (is.null(value)) NA_real_ else value
  }

  data.frame(
    metric = c(
      "Status", "Objective",
      "Tmax", "Tmin", "TA spread",
      "Gmax", "Gmin", "GR spread",
      "TA fairness", "GR fairness",
      "TA preference", "GR preference",
      "E scoring", "TA protection", "GR protection"
    ),
    value = c(
      as.character(model_result$status),
      format_summary_value(extract_objective_value(model_result)),
      format_summary_value(tmax),
      format_summary_value(tmin),
      format_summary_value(ta_spread),
      format_summary_value(gmax),
      format_summary_value(gmin),
      format_summary_value(gr_spread),
      component_status(get_setting("alpha_ta")),
      component_status(get_setting("alpha_gr")),
      component_status(get_setting("beta_ta")),
      component_status(get_setting("beta_gr")),
      component_status(get_setting("phi")),
      component_status(get_setting("rho_ta")),
      component_status(get_setting("rho_gr"))
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

plot_workload_distribution <- function(student_diag, C = 4, single_semester = FALSE) {
  plot_df <- student_diag[order(student_diag$year, student_diag$student_id), , drop = FALSE]
  plot_df$student_label <- paste0(plot_df$student_id, " - ", plot_df$student_name)
  plot_df$year <- factor(plot_df$year, levels = sort(unique(plot_df$year)))

  long_df <- rbind(
    data.frame(student_label = plot_df$student_label, year = plot_df$year,
               component = "Sem2_TA", units = plot_df$current_TA),
    data.frame(student_label = plot_df$student_label, year = plot_df$year,
               component = "Sem2_GR", units = plot_df$current_GR),
    data.frame(student_label = plot_df$student_label, year = plot_df$year,
               component = "Sem2_E", units = plot_df$current_E),
    data.frame(student_label = plot_df$student_label, year = plot_df$year,
               component = "Sem1_TA", units = plot_df$past_TA),
    data.frame(student_label = plot_df$student_label, year = plot_df$year,
               component = "Sem1_GR", units = plot_df$past_GR)
  )

  long_df$component <- factor(
    long_df$component,
    levels = c("Sem2_TA", "Sem2_GR", "Sem2_E", "Sem1_TA", "Sem1_GR")
  )

  fill_values <- c(
    Sem2_TA = "#0072B2",
    Sem2_GR = "#E66100",
    Sem2_E = "#0D9E00",
    Sem1_TA = "#8BBAD9",
    Sem1_GR = "#F2AA7A"
  )

  current_is_capacity <- all(abs(plot_df$current_TA + plot_df$current_GR + plot_df$current_E - C) < 1e-8)
  subtitle <- if (single_semester) {
    paste0(
      "Current semester allocation stacked below synthetic past workload ",
      "(past TA = 0, past GR = C)"
    )
  } else {
    "Current semester allocation stacked below past semester workload"
  }

  p <- ggplot2::ggplot(
    long_df,
    ggplot2::aes(x = .data$student_label, y = .data$units, fill = .data$component)
  ) +
    ggplot2::geom_col(
      width = 0.84,
      color = "white",
      linewidth = 0.2,
      position = ggplot2::position_stack(reverse = TRUE)
    ) +
    ggplot2::scale_fill_manual(
      values = fill_values,
      breaks = c("Sem2_TA", "Sem2_GR", "Sem2_E", "Sem1_TA", "Sem1_GR"),
      labels = c("Current TA", "Current GR", "Current E", "Past TA", "Past GR"),
      name = "Component",
      drop = FALSE
    ) +
    ggplot2::labs(
      x = "Student",
      y = "Workload Units",
      title = "Year-Long Workload Distribution by Student",
      subtitle = subtitle
    ) +
    ggplot2::facet_wrap(~year, scales = "free_x", ncol = 4) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, vjust = 0.5, hjust = 1),
      panel.grid.major.x = ggplot2::element_blank(),
      legend.position = "top"
    )

  if (current_is_capacity) {
    p <- p + ggplot2::geom_hline(yintercept = C, linetype = "dashed", color = "grey35")
  }

  p
}

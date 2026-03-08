prepare_phd_model <- function(df_list, t_max_y1 = 1, e_max = NULL,
                              alpha = 2, beta = 1, phi = 1, rho = 10) {
  # keep role order fixed
  job_names <- c("TA", "GR", "E")

  # extract inputs
  Ns <- df_list$Ns
  Nj <- df_list$Nj
  P  <- df_list$P   # preference matrix [i, j]
  d  <- df_list$d   # demand matrix [j, r], r = 1:3 for TA, GR, E
  s  <- df_list$s   # seniority
  t1 <- df_list$t1  # previous semester TA workload
  g1 <- df_list$g1  # previous semester GR workload

  idx_y1     <- which(s == -1)
  idx_non_y1 <- which(s >= 0)

  # basic validation for optional E cap
  if (!is.null(e_max)) {
    if (!is.numeric(e_max) || length(e_max) != 1 || is.na(e_max) || e_max < 0) {
      stop("e_max must be NULL or a single non-negative number.")
    }
  }

  model <- ompr::MIPModel() %>%

    # assignment vars
    ompr::add_variable(
      X[i, j, r],
      i = 1:Ns, j = 1:Nj, r = 1:3,
      type = "integer", lb = 0
    ) %>%

    # spread vars for yearly TA among non-Y1 students
    ompr::add_variable(Tmax, type = "continuous", lb = 0) %>%
    ompr::add_variable(Tmin, type = "continuous", lb = 0) %>%

    # slack for Y1 TA soft bound
    ompr::add_variable(w[i], i = idx_y1, type = "continuous", lb = 0) %>%

    # objective
    ompr::set_objective(
      alpha * (Tmax - Tmin) -
        beta * ompr::sum_over(P[i, j] * X[i, j, 1], i = 1:Ns, j = 1:Nj) -
        phi  * ompr::sum_over(s[i] * X[i, j, 3], i = 1:Ns, j = 1:Nj) +
        rho  * ompr::sum_over(w[i], i = idx_y1),
      sense = "min"
    ) %>%

    # demand satisfaction for each job and role
    ompr::add_constraint(
      ompr::sum_over(X[i, j, r], i = 1:Ns) == d[j, r],
      j = 1:Nj, r = 1:3
    ) %>%

    # yearly TA spread constraints for non-Year-1 students:
    # T_i = t1[i] + sum_j X[i,j,TA]
    ompr::add_constraint(
      t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj) <= Tmax,
      i = idx_non_y1
    ) %>%
    ompr::add_constraint(
      t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj) >= Tmin,
      i = idx_non_y1
    ) %>%

    # total workload cap:
    # T_i + G_i + e_i^(2) <= 8
    ompr::add_constraint(
      (t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj)) +
      (g1[i] + ompr::sum_over(X[i, j, 2], j = 1:Nj)) +
               ompr::sum_over(X[i, j, 3], j = 1:Nj) <= 8,
      i = 1:Ns
    ) %>%

    # Year 1 soft TA bound on current semester TA workload
    ompr::add_constraint(
      ompr::sum_over(X[i, j, 1], j = 1:Nj) <= t_max_y1 + w[i],
      i = idx_y1
    )

  # optional per-student cap on E units
  if (!is.null(e_max)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 3], j = 1:Nj) <= e_max,
        i = 1:Ns
      )
  }

  model
}


# Extract student-level TA/GR/E assignments from solved PhD model
extract_phd_assignment <- function(model_result,
                                   student_df,
                                   id_col = "S/No.",
                                   name_col = "Name",
                                   seniority_col = 'seniority',
                                   role_names = c("TA", "GR", "E"),
                                   integer_output = TRUE) {
  if (!all(c(id_col, name_col) %in% names(student_df))) {
    stop("id_col and/or name_col not found in student_df.")
  }
  if (length(role_names) != 3) {
    stop("role_names must have length 3 in the order of model roles (TA, GR, E).")
  }

  student_map <- student_df %>%
    dplyr::transmute(
      i = dplyr::row_number(),
      student_id = .data[[id_col]],
      student_name = .data[[name_col]],
      seniority = .data[[seniority_col]]
    )

  alloc_df <- ompr::get_solution(model_result, X[i, j, r]) %>%
    dplyr::filter(.data$value > 1e-8) %>%
    dplyr::group_by(.data$i, .data$r) %>%
    dplyr::summarise(units = sum(.data$value), .groups = "drop") %>%
    dplyr::mutate(
      role = factor(.data$r, levels = 1:3, labels = role_names)
    ) %>%
    dplyr::select(.data$i, .data$role, .data$units) %>%
    tidyr::pivot_wider(
      names_from = .data$role,
      values_from = .data$units,
      values_fill = 0
    )

  out <- student_map %>%
    dplyr::left_join(alloc_df, by = "i")

  for (nm in role_names) {
    if (!nm %in% names(out)) {
      out[[nm]] <- 0
    }
  }

  if (isTRUE(integer_output)) {
    out[role_names] <- lapply(
      out[role_names],
      function(x) as.integer(round(replace(x, is.na(x), 0)))
    )
  } else {
    out[role_names] <- lapply(
      out[role_names],
      function(x) as.numeric(replace(x, is.na(x), 0))
    )
  }

  out %>%
    dplyr::select("student_id", "student_name", "seniority", dplyr::all_of(role_names)) %>%
    dplyr::arrange(.data$student_id)
}


# Plot per-student workload distribution for the full year
plot_phd_year_distribution <- function(current_alloc_df,
                                       t1 = NULL,
                                       g1 = NULL,
                                       student_id_col = "student_id",
                                       student_name_col = "student_name",
                                       facet_by_seniority = FALSE,
                                       seniority_col = NULL,
                                       seniority = NULL,
                                       facet_ncol = 4) {
  required_cols <- c(student_id_col, student_name_col, "TA", "GR", "E")
  missing_cols <- setdiff(required_cols, names(current_alloc_df))
  if (length(missing_cols) > 0) {
    stop(
      "current_alloc_df is missing required columns: ",
      paste(missing_cols, collapse = ", ")
    )
  }

  has_past <- !(is.null(t1) && is.null(g1))
  if (xor(is.null(t1), is.null(g1))) {
    stop("Provide both t1 and g1, or provide neither.")
  }
  if (has_past && (length(t1) != nrow(current_alloc_df) || length(g1) != nrow(current_alloc_df))) {
    stop("t1 and g1 must have length equal to nrow(current_alloc_df).")
  }

  if (!is.logical(facet_by_seniority) || length(facet_by_seniority) != 1 || is.na(facet_by_seniority)) {
    stop("facet_by_seniority must be TRUE or FALSE.")
  }
  if (!is.null(facet_ncol) && (!is.numeric(facet_ncol) || length(facet_ncol) != 1 || is.na(facet_ncol) || facet_ncol < 1)) {
    stop("facet_ncol must be NULL or a single positive integer.")
  }

  seniority_vec <- NULL
  if (isTRUE(facet_by_seniority)) {
    if (!is.null(seniority)) {
      if (length(seniority) != nrow(current_alloc_df)) {
        stop("seniority must have length equal to nrow(current_alloc_df).")
      }
      seniority_vec <- seniority
    } else {
      if (is.null(seniority_col)) {
        if ("seniority" %in% names(current_alloc_df)) {
          seniority_col <- "seniority"
        } else {
          stop("Set seniority_col (or provide seniority vector) when facet_by_seniority = TRUE.")
        }
      }
      if (!seniority_col %in% names(current_alloc_df)) {
        stop("seniority_col not found in current_alloc_df.")
      }
      seniority_vec <- current_alloc_df[[seniority_col]]
    }
  }

  base_df <- current_alloc_df %>%
    dplyr::transmute(
      student_id = .data[[student_id_col]],
      student_name = .data[[student_name_col]],
      current_TA = as.numeric(.data$TA),
      current_GR = as.numeric(.data$GR),
      current_E  = as.numeric(.data$E)
    ) %>%
    dplyr::arrange(.data$student_id) %>%
    dplyr::mutate(student_label = paste0(.data$student_id, " - ", .data$student_name))

  if (isTRUE(facet_by_seniority)) {
    ordered_idx <- order(current_alloc_df[[student_id_col]])
    seniority_vec <- seniority_vec[ordered_idx]

    if (is.numeric(seniority_vec)) {
      seniority_levels <- sort(unique(seniority_vec))
    } else {
      seniority_levels <- unique(as.character(seniority_vec))
    }

    base_df$seniority <- factor(as.character(seniority_vec), levels = as.character(seniority_levels))
  } else {
    base_df$seniority <- factor("All")
  }

  job_colors <- c(TA = "#0072B2", GR = "#e61b00", E = "#0d9e00")

  if (has_past) {
    plot_df <- base_df %>%
      dplyr::mutate(
        past_TA = as.numeric(t1),
        past_GR = as.numeric(g1)
      )

    long_df <- dplyr::bind_rows(
      plot_df %>% dplyr::transmute(student_label, seniority = .data$seniority, stack_component = "Sem2_TA", units = .data$current_TA),
      plot_df %>% dplyr::transmute(student_label, seniority = .data$seniority, stack_component = "Sem2_GR", units = .data$current_GR),
      plot_df %>% dplyr::transmute(student_label, seniority = .data$seniority, stack_component = "Sem2_E",  units = .data$current_E),
      plot_df %>% dplyr::transmute(student_label, seniority = .data$seniority, stack_component = "Sem1_TA", units = .data$past_TA),
      plot_df %>% dplyr::transmute(student_label, seniority = .data$seniority, stack_component = "Sem1_GR", units = .data$past_GR)
    ) %>%
      dplyr::mutate(
        stack_component = factor(
          .data$stack_component,
          levels = c("Sem2_TA", "Sem2_GR", "Sem2_E", "Sem1_TA", "Sem1_GR")
        )
      )

    fill_values <- c(
      Sem2_TA = job_colors[["TA"]],
      Sem2_GR = job_colors[["GR"]],
      Sem2_E  = job_colors[["E"]],
      Sem1_TA = job_colors[["TA"]],
      Sem1_GR = job_colors[["GR"]]
    )

    sem2_is_four <- all(abs(plot_df$current_TA + plot_df$current_GR + plot_df$current_E - 4) < 1e-8)
    subtitle_txt <- if (sem2_is_four) {
      "Bottom 4 units: Semester 2 (current) | Top 4 units: Semester 1 (past)"
    } else {
      "Bottom stack: Semester 2 (current) | Top stack: Semester 1 (past)"
    }

    p <- ggplot2::ggplot(
      long_df,
      ggplot2::aes(x = .data$student_label, y = .data$units, fill = .data$stack_component)
    ) +
      ggplot2::geom_col(
        width = 0.85,
        color = "white",
        linewidth = 0.2,
        position = ggplot2::position_stack(reverse = TRUE)
      ) +
      ggplot2::scale_fill_manual(
        values = fill_values,
        breaks = c("Sem2_TA", "Sem2_GR", "Sem2_E"),
        labels = c("TA", "GR", "E"),
        name = "Job",
        drop = FALSE
      ) +
      ggplot2::labs(
        x = "Student",
        y = "Workload Units",
        title = "Year-Long Work Distribution by Student",
        subtitle = subtitle_txt
      ) +
      ggplot2::theme_minimal(base_size = 11) +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(angle = 90, vjust = 0.5, hjust = 1),
        panel.grid.major.x = ggplot2::element_blank()
      )

    if (sem2_is_four) {
      p <- p + ggplot2::geom_hline(yintercept = 4, linetype = "dashed", color = "grey35")
    }

    if (isTRUE(facet_by_seniority)) {
      p <- p + ggplot2::facet_wrap(~seniority, scales = "free_x", ncol = facet_ncol)
    }

    return(p)
  }

  long_df <- dplyr::bind_rows(
    base_df %>% dplyr::transmute(student_label, seniority = .data$seniority, job = "TA", units = .data$current_TA),
    base_df %>% dplyr::transmute(student_label, seniority = .data$seniority, job = "GR", units = .data$current_GR),
    base_df %>% dplyr::transmute(student_label, seniority = .data$seniority, job = "E",  units = .data$current_E)
  ) %>%
    dplyr::mutate(job = factor(.data$job, levels = c("TA", "GR", "E")))

  p <- ggplot2::ggplot(long_df, ggplot2::aes(x = .data$student_label, y = .data$units, fill = .data$job)) +
    ggplot2::geom_col(
      width = 0.85,
      color = "white",
      linewidth = 0.2,
      position = ggplot2::position_stack(reverse = TRUE)
    ) +
    ggplot2::scale_fill_manual(values = job_colors, drop = FALSE) +
    ggplot2::labs(
      x = "Student",
      y = "Workload Units",
      fill = "Job",
      title = "Current-Semester Work Distribution by Student"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, vjust = 0.5, hjust = 1),
      panel.grid.major.x = ggplot2::element_blank()
    )

  if (isTRUE(facet_by_seniority)) {
    p <- p + ggplot2::facet_wrap(~seniority, scales = "free_x", ncol = facet_ncol)
  }

  p
}


extract_phd_info <- function(df){
    
}

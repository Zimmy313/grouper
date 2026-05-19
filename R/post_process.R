#' Assigns model result to the original data frame.
#'
#' From the result of [ompr::solve_model()], this function attaches the
#' derived groupings to the original dataframe comprising students.
#'
#' @param model_result The output solution objection.
#' @param dframe The original dataframe used in [extract_student_info()].
#' @param assignment Character string indicating the type of model that this
#'   dataset is for. The argument is either 'preference' or 'diversity'. Partial
#'   matching is fine.
#' @param params_list The list of parameters from the YAML file, i.e. the output
#'   of [extract_params_yaml()]. This is only required for the preference-based
#'   assignment.
#' @param group_names A character string. It denotes the column name in the
#'   original dataframe containing the self-formed groups. Note that we need the
#'   string here, not the integer position, since we are going to join with it.
#'
#' @importFrom rlang .data
#'
#' @returns A data frame with the group assignments attached to the original
#' group composition dataframe.
#' @export
#'
assign_groups <- function(model_result,
                          assignment=c("diversity", "preference"),
                          dframe,
                          params_list,
                          group_names) {
  assignment <- match.arg(assignment)
  if(assignment == "diversity") {

    out_df <- ompr::get_solution(model_result, x[g,t,r]) %>%
      dplyr::filter(.data$value>0) %>%
      dplyr::select("t", "r", "g") %>%
      dplyr::rename("group"="g", "topic"="t", "rep"="r") %>%
      dplyr::arrange(.data$topic, .data$rep, .data$group) %>%
      dplyr::left_join(dframe, by=c("group"=group_names))

    return(out_df)
  } else if (assignment == "preference") {
    # message("incomplete")
    group_sizes <- dframe %>%
      dplyr::group_by(.data[[group_names]]) %>%
      dplyr::summarise(size = length(.data$id), .groups = "drop")
    n_topics <- params_list[["n_topics"]]
    B <- params_list[["B"]]

    topic_df <- data.frame(topic = 1:(n_topics*B),
                          topic2 = rep(1:n_topics, B),
                          subtopic=rep(1:B, each=n_topics))

    out_df <- ompr::get_solution(model_result, x[g,t,r]) %>%
                dplyr::filter(.data$value>0) %>%
                dplyr::select("t", "r", "g") %>%
                dplyr::rename("group"="g", "topic"="t", "rep"="r") %>%
                dplyr::left_join(group_sizes, by=c("group"=group_names)) %>%
                dplyr::left_join(topic_df, by="topic") %>%
                dplyr::select("topic2", "subtopic", "rep", "group", "size")  %>%
                dplyr::group_by(.data$topic2, .data$subtopic) %>%
                dplyr::mutate(rep=match(.data$rep, unique(.data$rep)))
    out_df <- as.data.frame(dplyr::ungroup(out_df))

    return(out_df)
  } else {
    stop("assignment argument should be either 'diversity' or 'preference'.")
  }
}


#' Convert PhD solver allocation to manual-style wide table
#'
#' Creates one row per student and one column per course-role pair, with units
#' allocated by the solver.
#'
#' @param model_result Result object from `ompr::solve_model()` for the PhD model.
#' @param student_df A data frame that contains student name information. Every
#'   row is a unique student.
#' @param course_codes Character vector of course codes in the same order as
#'   `p_mat` columns (and `d_mat` rows).
#' @param name_col Student name column name in `student_df`.
#'
#' @returns A data frame with columns:
#'   `Name`, then all `<course>-t`, all `<course>-g`, all `<course>-e`.
#'
#' @export
assign_job <- function(model_result,
                       student_df,
                       course_codes,
                       name_col = "Name") {
  if (!name_col %in% names(student_df)) {
    stop("name_col not found in student_df.")
  }

  Ns <- nrow(student_df)
  course_codes <- as.character(course_codes)
  Nj <- length(course_codes)

  alloc <- ompr::get_solution(model_result, X[i, j, r])
  alloc <- alloc[alloc$value > 1e-8, c("i", "j", "r", "value"), drop = FALSE]

  ta_mat <- matrix(0, nrow = Ns, ncol = Nj)
  gr_mat <- matrix(0, nrow = Ns, ncol = Nj)
  e_mat  <- matrix(0, nrow = Ns, ncol = Nj)

  if (nrow(alloc) > 0) {
    for (k in seq_len(nrow(alloc))) {
      i <- alloc$i[k]
      j <- alloc$j[k]
      r <- alloc$r[k]
      v <- alloc$value[k]

      if (r == 1) ta_mat[i, j] <- ta_mat[i, j] + v
      if (r == 2) gr_mat[i, j] <- gr_mat[i, j] + v
      if (r == 3) e_mat[i, j]  <- e_mat[i, j] + v
    }
  }

  ta_df <- as.data.frame(matrix(as.integer(round(ta_mat)), nrow = Ns, ncol = Nj))
  gr_df <- as.data.frame(matrix(as.integer(round(gr_mat)), nrow = Ns, ncol = Nj))
  e_df  <- as.data.frame(matrix(as.integer(round(e_mat)),  nrow = Ns, ncol = Nj))

  names(ta_df) <- paste0(course_codes, "-t")
  names(gr_df) <- paste0(course_codes, "-g")
  names(e_df)  <- paste0(course_codes, "-e")

  out <- cbind(
    data.frame(Name = student_df[[name_col]], stringsAsFactors = FALSE),
    ta_df,
    gr_df,
    e_df
  )

  rownames(out) <- NULL
  out
}


solver_plugin_package <- function(solver) {
  switch(
    solver,
    glpk = "ROI.plugin.glpk",
    highs = "ROI.plugin.highs",
    gurobi = "ROI.plugin.gurobi"
  )
}


require_roi_solver <- function(solver) {
  if (!requireNamespace("ompr.roi", quietly = TRUE)) {
    stop(
      "Solving requires package 'ompr.roi'. Install it and retry.",
      call. = FALSE
    )
  }

  plugin_pkg <- solver_plugin_package(solver)
  if (!requireNamespace(plugin_pkg, quietly = TRUE)) {
    stop(
      "Solver '", solver, "' requires package '", plugin_pkg,
      "'. Install it and retry.",
      call. = FALSE
    )
  }
}


validate_required_args <- function(assignment, args) {
  required <- switch(
    assignment,
    diversity = c("dframe", "group_names"),
    preference = c("dframe", "params_list", "group_names"),
    phd = c("student_df", "course_codes")
  )

  missing_args <- required[vapply(
    required,
    function(x) is.null(args[[x]]),
    logical(1)
  )]

  if (length(missing_args) > 0) {
    stop(
      "Missing required argument(s) for assignment = '", assignment, "': ",
      paste(missing_args, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
}


validate_solver_limit <- function(x, nm) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 0) {
    stop(nm, " must be NULL or a single non-negative number.", call. = FALSE)
  }
  x
}


build_roi_args <- function(solver, verbose, time_limit, iteration_limit,
                           solver_args) {
  if (!is.list(solver_args)) {
    stop("solver_args must be a list.", call. = FALSE)
  }
  if ("solver" %in% names(solver_args)) {
    stop("solver_args cannot include 'solver'. Use the solver argument instead.",
         call. = FALSE)
  }

  roi_args <- c(list(solver = solver, verbose = verbose), solver_args)

  if (solver == "gurobi") {
    if (!is.null(time_limit)) {
      roi_args$TimeLimit <- validate_solver_limit(time_limit, "time_limit")
    }
    if (!is.null(iteration_limit)) {
      roi_args$IterationLimit <- as.integer(round(
        validate_solver_limit(iteration_limit, "iteration_limit")
      ))
    }
  }

  roi_args
}


#' Solve a prepared model and post-process the assignment
#'
#' Solves an existing `ompr` model with an ROI-backed solver, then routes the
#' solver result through [assign_groups()] or [assign_job()] depending on the
#' assignment type.
#'
#' @param model A prepared `ompr` model, usually from [prepare_model()].
#' @param assignment Character string indicating model type. Must be one of
#'   `"diversity"`, `"preference"`, or `"phd"`.
#' @param solver Solver to use through `ompr.roi`. Must be one of `"glpk"`,
#'   `"highs"`, or `"gurobi"`.
#' @param dframe The original dataframe used in [extract_student_info()]. Required
#'   for `assignment = "diversity"` and `assignment = "preference"`.
#' @param params_list The list of parameters from [extract_params_yaml()].
#'   Required for `assignment = "preference"`.
#' @param group_names A character string denoting the self-formed group column in
#'   `dframe`. Required for `assignment = "diversity"` and
#'   `assignment = "preference"`.
#' @param student_df A data frame that contains PhD student name information.
#'   Required for `assignment = "phd"`.
#' @param course_codes Character vector of PhD course codes in model order.
#'   Required for `assignment = "phd"`.
#' @param name_col Student name column name in `student_df`.
#' @param verbose Logical value passed to `ompr.roi::with_ROI()`.
#' @param time_limit,iteration_limit Optional Gurobi controls. These are applied
#'   only when `solver = "gurobi"`.
#' @param solver_args Additional named arguments passed to
#'   `ompr.roi::with_ROI()`.
#'
#' @returns A list with two elements:
#'   \itemize{
#'   \item \code{model_result}: the raw result from [ompr::solve_model()]
#'   \item \code{output}: the post-processed assignment table
#'   }
#'
#' @export
solve_assignment <- function(model,
                             assignment = c("diversity", "preference", "phd"),
                             solver = c("glpk", "highs", "gurobi"),
                             dframe = NULL,
                             params_list = NULL,
                             group_names = NULL,
                             student_df = NULL,
                             course_codes = NULL,
                             name_col = "Name",
                             verbose = TRUE,
                             time_limit = NULL,
                             iteration_limit = NULL,
                             solver_args = list()) {
  assignment <- match.arg(assignment)
  solver <- match.arg(solver)

  validate_required_args(
    assignment = assignment,
    args = list(
      dframe = dframe,
      params_list = params_list,
      group_names = group_names,
      student_df = student_df,
      course_codes = course_codes
    )
  )

  require_roi_solver(solver)

  roi_args <- build_roi_args(
    solver = solver,
    verbose = verbose,
    time_limit = time_limit,
    iteration_limit = iteration_limit,
    solver_args = solver_args
  )
  roi_control <- do.call(ompr.roi::with_ROI, roi_args)
  model_result <- ompr::solve_model(model, roi_control)

  output <- if (assignment == "phd") {
    assign_job(
      model_result = model_result,
      student_df = student_df,
      course_codes = course_codes,
      name_col = name_col
    )
  } else {
    assign_groups(
      model_result = model_result,
      assignment = assignment,
      dframe = dframe,
      params_list = params_list,
      group_names = group_names
    )
  }

  list(
    model_result = model_result,
    output = output
  )
}

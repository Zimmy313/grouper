test_that("assign_groups works for diversity and preference outputs", {
  skip_if_not_installed("ompr.roi")
  skip_if_not_installed("ROI.plugin.glpk")

  div_df <- extract_student_info(
    dba_gc_ex001,
    assignment = "diversity",
    self_formed_groups = 4,
    demographic_cols = 2,
    skills = 3
  )
  div_params <- extract_params_yaml(
    system.file("extdata", "dba_params_ex001.yml", package = "grouper"),
    assignment = "diversity"
  )
  div_model <- prepare_model(div_df, div_params, assignment = "diversity", w1 = 1, w2 = 0)
  div_result <- ompr::solve_model(div_model, ompr.roi::with_ROI(solver = "glpk"))

  div_out <- assign_groups(
    model_result = div_result,
    assignment = "diversity",
    dframe = dba_gc_ex001,
    group_names = "groups"
  )
  expect_true(all(c("group", "topic", "rep") %in% names(div_out)))

  pref_df <- extract_student_info(
    pba_gc_ex002,
    assignment = "preference",
    self_formed_groups = 2,
    pref_mat = pba_prefmat_ex002
  )
  pref_params <- extract_params_yaml(
    system.file("extdata", "pba_params_ex002.yml", package = "grouper"),
    assignment = "preference"
  )
  pref_model <- prepare_model(pref_df, pref_params, assignment = "preference")
  pref_result <- ompr::solve_model(pref_model, ompr.roi::with_ROI(solver = "glpk"))

  pref_out <- assign_groups(
    model_result = pref_result,
    assignment = "preference",
    dframe = pba_gc_ex002,
    params_list = pref_params,
    group_names = "grouping"
  )
  expect_true(all(c("topic2", "subtopic", "rep", "group", "size") %in% names(pref_out)))
})

test_that("assign_job converts PhD solver output to manual-style table", {
  skip_if_not_installed("ompr.roi")
  skip_if_not_installed("ROI.plugin.glpk")

  phd_df <- extract_phd_info(
    student_df = multirole_students_ex001,
    p_mat = multirole_prefmat_ex001,
    d_mat = multirole_demand_ex001,
    e_mode = "none",
    C = 4
  )

  phd_model <- prepare_model(phd_df, assignment = "phd", t_max_y1 = 1, C = 4)
  phd_result <- ompr::solve_model(phd_model, ompr.roi::with_ROI(solver = "glpk"))

  job <- assign_job(
    model_result = phd_result,
    student_df = multirole_students_ex001,
    course_codes = rownames(multirole_demand_ex001),
    name_col = "Name"
  )

  expect_true("Name" %in% names(job))
  expect_true(any(grepl("-t$", names(job))))
  expect_true(any(grepl("-g$", names(job))))
  expect_true(any(grepl("-e$", names(job))))
  expect_equal(nrow(job), nrow(multirole_students_ex001))
})

test_that("solve_assignment wraps diversity solving and post-processing", {
  skip_if_not_installed("ompr.roi")
  skip_if_not_installed("ROI.plugin.glpk")

  div_df <- extract_student_info(
    dba_gc_ex001,
    assignment = "diversity",
    self_formed_groups = 4,
    demographic_cols = 2,
    skills = 3
  )
  div_params <- extract_params_yaml(
    system.file("extdata", "dba_params_ex001.yml", package = "grouper"),
    assignment = "diversity"
  )
  div_model <- prepare_model(div_df, div_params, assignment = "diversity", w1 = 1, w2 = 0)

  wrapped <- solve_assignment(
    model = div_model,
    assignment = "diversity",
    solver = "glpk",
    dframe = dba_gc_ex001,
    group_names = "groups",
    verbose = FALSE
  )
  manual <- assign_groups(
    model_result = wrapped$model_result,
    assignment = "diversity",
    dframe = dba_gc_ex001,
    group_names = "groups"
  )

  expect_named(wrapped, c("model_result", "output"))
  expect_equal(wrapped$output, manual)
})

test_that("solve_assignment wraps preference solving and post-processing", {
  skip_if_not_installed("ompr.roi")
  skip_if_not_installed("ROI.plugin.glpk")

  pref_df <- extract_student_info(
    pba_gc_ex002,
    assignment = "preference",
    self_formed_groups = 2,
    pref_mat = pba_prefmat_ex002
  )
  pref_params <- extract_params_yaml(
    system.file("extdata", "pba_params_ex002.yml", package = "grouper"),
    assignment = "preference"
  )
  pref_model <- prepare_model(pref_df, pref_params, assignment = "preference")

  wrapped <- solve_assignment(
    model = pref_model,
    assignment = "preference",
    solver = "glpk",
    dframe = pba_gc_ex002,
    params_list = pref_params,
    group_names = "grouping",
    verbose = FALSE
  )
  manual <- assign_groups(
    model_result = wrapped$model_result,
    assignment = "preference",
    dframe = pba_gc_ex002,
    params_list = pref_params,
    group_names = "grouping"
  )

  expect_named(wrapped, c("model_result", "output"))
  expect_equal(wrapped$output, manual)
})

test_that("solve_assignment wraps PhD solving and post-processing", {
  skip_if_not_installed("ompr.roi")
  skip_if_not_installed("ROI.plugin.glpk")

  phd_df <- extract_phd_info(
    student_df = multirole_students_ex001,
    p_mat = multirole_prefmat_ex001,
    d_mat = multirole_demand_ex001,
    e_mode = "none",
    C = 4
  )
  phd_model <- prepare_model(phd_df, assignment = "phd", t_max_y1 = 1, C = 4)

  wrapped <- solve_assignment(
    model = phd_model,
    assignment = "phd",
    solver = "glpk",
    student_df = multirole_students_ex001,
    course_codes = rownames(multirole_demand_ex001),
    name_col = "Name",
    verbose = FALSE
  )
  manual <- assign_job(
    model_result = wrapped$model_result,
    student_df = multirole_students_ex001,
    course_codes = rownames(multirole_demand_ex001),
    name_col = "Name"
  )

  expect_named(wrapped, c("model_result", "output"))
  expect_equal(wrapped$output, manual)
})

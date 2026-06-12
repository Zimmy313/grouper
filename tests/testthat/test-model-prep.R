test_that("prepare_model wrapper dispatches and validates arguments", {
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

  m_div <- prepare_model(div_df, div_params, assignment = "diversity", w1 = 1, w2 = 0)
  expect_s3_class(m_div, "linear_optimization_model")
  m_div_yaml_precedence <- prepare_model(
    div_df,
    div_params,
    assignment = "diversity",
    w1 = 1,
    w2 = 0,
    n_topics = 999,
    R = 999,
    nmin = 1,
    nmax = 1,
    rmin = 1,
    rmax = 1
  )
  expect_s3_class(m_div_yaml_precedence, "linear_optimization_model")

  m_div_no_yaml <- prepare_model(
    div_df,
    assignment = "diversity",
    w1 = 1,
    w2 = 0,
    n_topics = 2,
    R = 1,
    nmin = 2,
    nmax = 2,
    rmin = 1,
    rmax = 1
  )
  expect_s3_class(m_div_no_yaml, "linear_optimization_model")

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

  m_pref <- prepare_model(pref_df, pref_params, assignment = "preference")
  expect_s3_class(m_pref, "linear_optimization_model")
  m_pref_yaml_precedence <- prepare_model(
    pref_df,
    pref_params,
    assignment = "preference",
    n_topics = 999,
    B = 999,
    R = 999,
    nmin = 1,
    nmax = 1,
    rmin = 1,
    rmax = 1
  )
  expect_s3_class(m_pref_yaml_precedence, "linear_optimization_model")

  m_pref_no_yaml <- prepare_model(
    pref_df,
    assignment = "preference",
    n_topics = 2,
    B = 2,
    R = 1,
    nmin = 2,
    nmax = 2,
    rmin = 1,
    rmax = 1
  )
  expect_s3_class(m_pref_no_yaml, "linear_optimization_model")

  phd_df <- extract_phd_info(
    student_df = phd_students_ex001,
    p_mat = phd_prefmat_ex001,
    d_mat = phd_demand_ex001,
    e_mode = "none",
    C = 4
  )

  m_phd <- prepare_model(phd_df, assignment = "phd", t_max_y1 = 1, C = 4)
  expect_s3_class(m_phd, "linear_optimization_model")

  m_phd_year_2 <- prepare_model(
    phd_df,
    assignment = "phd",
    t_max_y1 = 1,
    protected_year = 2,
    C = 4
  )
  expect_s3_class(m_phd_year_2, "linear_optimization_model")
  expect_equal(grep("^w\\[", ompr::variable_keys(m_phd_year_2), value = TRUE), "w[2]")

  expect_error(
    prepare_model(
      div_df,
      assignment = "diversity",
      R = 1,
      nmin = 2,
      nmax = 2,
      rmin = 1,
      rmax = 1
    ),
    "Missing required parameters.*n_topics"
  )
  expect_error(
    prepare_model(
      pref_df,
      assignment = "preference",
      n_topics = 2,
      R = 1,
      nmin = 2,
      nmax = 2,
      rmin = 1,
      rmax = 1
    ),
    "Missing required parameters.*B"
  )
})

test_that("prepare_phd_model validates optional bound consistency", {
  phd_df <- extract_phd_info(
    student_df = phd_students_ex001,
    p_mat = phd_prefmat_ex001,
    d_mat = phd_demand_ex001,
    e_mode = "none",
    C = 4
  )

  expect_error(
    prepare_phd_model(phd_df, ta_min = 2, ta_max = 1),
    "ta_min cannot be greater than ta_max"
  )
  expect_error(
    prepare_phd_model(phd_df, gr_min = 2, gr_max = 1),
    "gr_min cannot be greater than gr_max"
  )
  expect_error(
    prepare_phd_model(phd_df, e_min = 2, e_max = 1),
    "e_min cannot be greater than e_max"
  )
})

test_that("custom seniority scores do not redefine year-based model groups", {
  default_df <- extract_phd_info(
    student_df = phd_students_ex001,
    p_mat = phd_prefmat_ex001,
    d_mat = phd_demand_ex001,
    e_mode = "none"
  )
  custom_df <- extract_phd_info(
    student_df = phd_students_ex001,
    p_mat = phd_prefmat_ex001,
    d_mat = phd_demand_ex001,
    e_mode = "none",
    s = c(100, -1, -2, -3)
  )

  default_model <- prepare_phd_model(default_df)
  custom_model <- prepare_phd_model(custom_df)

  expect_equal(ompr::variable_keys(custom_model), ompr::variable_keys(default_model))
  expect_equal(ompr::nconstraints(custom_model), ompr::nconstraints(default_model))
  expect_true("w[1]" %in% ompr::variable_keys(custom_model))
  expect_false("w[2]" %in% ompr::variable_keys(custom_model))
})

test_that("prepare_phd_model defaults to Year 1 protection", {
  phd_df <- extract_phd_info(
    student_df = phd_students_ex001,
    p_mat = phd_prefmat_ex001,
    d_mat = phd_demand_ex001,
    e_mode = "none"
  )

  default_model <- prepare_phd_model(phd_df)
  explicit_model <- prepare_phd_model(phd_df, protected_year = 1)

  expect_equal(ompr::variable_keys(default_model), ompr::variable_keys(explicit_model))
  expect_equal(ompr::nconstraints(default_model), ompr::nconstraints(explicit_model))
  expect_equal(grep("^w\\[", ompr::variable_keys(default_model), value = TRUE), "w[1]")
})

test_that("prepare_phd_model protects exactly the selected year", {
  phd_df <- extract_phd_info(
    student_df = phd_students_ex001,
    p_mat = phd_prefmat_ex001,
    d_mat = phd_demand_ex001,
    e_mode = "none"
  )

  for (protected_year in 1:4) {
    model <- prepare_phd_model(phd_df, protected_year = protected_year)
    slack_keys <- grep("^w\\[", ompr::variable_keys(model), value = TRUE)

    expect_equal(slack_keys, paste0("w[", protected_year, "]"))
  }
})

test_that("prepare_phd_model includes every unprotected year in fairness", {
  students <- phd_students_ex001
  students$year <- c(1, 1, 3, 4)
  phd_df <- extract_phd_info(
    student_df = students,
    p_mat = phd_prefmat_ex001,
    d_mat = phd_demand_ex001,
    e_mode = "none"
  )

  model <- prepare_phd_model(phd_df, protected_year = 3)

  expect_equal(grep("^w\\[", ompr::variable_keys(model), value = TRUE), "w[3]")
  expect_equal(ompr::nconstraints(model), 23)
})

test_that("prepare_phd_model validates protected_year", {
  phd_df <- extract_phd_info(
    student_df = phd_students_ex001,
    p_mat = phd_prefmat_ex001,
    d_mat = phd_demand_ex001,
    e_mode = "none"
  )

  invalid_values <- list(
    c(1, 2),
    1.5,
    "1",
    NA_real_,
    NaN,
    Inf,
    0,
    5
  )

  for (protected_year in invalid_values) {
    expect_error(
      prepare_phd_model(phd_df, protected_year = protected_year),
      "single whole number from 1 to 4"
    )
  }
})

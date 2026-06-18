multirole_inputs <- function(p_ta_mat = multirole_prefmat_ex001,
                             p_gr_mat = multirole_prefmat_ex001,
                             e_mode = "none",
                             student_df = multirole_students_ex001,
                             C = 4,
                             single_semester = FALSE) {
  extract_multirole_info(
    student_df = student_df,
    d_mat = multirole_demand_ex001,
    p_ta_mat = p_ta_mat,
    p_gr_mat = p_gr_mat,
    e_mode = e_mode,
    C = C,
    single_semester = single_semester
  )
}

objective_coefficients <- function(model) {
  stats::setNames(
    as.numeric(ompr::objective_function(model)$solution),
    ompr::variable_keys(model)
  )
}

test_that("extract_multirole_info returns aligned role-specific inputs", {
  x <- multirole_inputs(e_mode = "rr")

  expect_named(
    x,
    c("Ns", "Nj", "C", "P_ta", "P_gr", "d", "s", "year", "t1", "g1")
  )
  expect_equal(x$Ns, nrow(multirole_students_ex001))
  expect_equal(x$Nj, nrow(multirole_demand_ex001))
  expect_equal(x$C, 4)
  expect_equal(x$P_ta, multirole_prefmat_ex001)
  expect_equal(x$P_gr, multirole_prefmat_ex001)
  expect_equal(dim(x$d), c(4, 3))
  expect_equal(colnames(x$d), c("TA", "GR", "E"))
  expect_equal(x$s, c(-1, 0, 1, 2))
  expect_equal(x$year, 1:4)
  expect_equal(x$t1, multirole_students_ex001$past_ta)
  expect_equal(x$g1, multirole_students_ex001$past_gr)
})

test_that("single-semester extraction generates and stores prior workload", {
  students_without_past <- multirole_students_ex001[
    , c("student_id", "year", "Name")
  ]
  no_past <- multirole_inputs(
    student_df = students_without_past,
    C = 5,
    single_semester = TRUE
  )

  expect_equal(no_past$C, 5)
  expect_equal(no_past$t1, rep(0, no_past$Ns))
  expect_equal(no_past$g1, rep(5, no_past$Ns))

  students_with_changed_past <- multirole_students_ex001
  students_with_changed_past$past_ta <- 99
  students_with_changed_past$past_gr <- -99
  ignored_past <- multirole_inputs(
    student_df = students_with_changed_past,
    C = 3,
    single_semester = TRUE
  )

  expect_equal(ignored_past$t1, rep(0, ignored_past$Ns))
  expect_equal(ignored_past$g1, rep(3, ignored_past$Ns))
})

test_that("extract_multirole_info accepts omitted preference matrices", {
  neither <- multirole_inputs(p_ta_mat = NULL, p_gr_mat = NULL)
  ta_only <- multirole_inputs(p_gr_mat = NULL)
  gr_only <- multirole_inputs(p_ta_mat = NULL)

  expect_null(neither$P_ta)
  expect_null(neither$P_gr)
  expect_equal(ta_only$P_ta, multirole_prefmat_ex001)
  expect_null(ta_only$P_gr)
  expect_null(gr_only$P_ta)
  expect_equal(gr_only$P_gr, multirole_prefmat_ex001)
})

test_that("extract_info dispatches to the multi-role extractor", {
  direct <- multirole_inputs()
  wrapped <- extract_info(
    assignment = "multirole",
    student_df = multirole_students_ex001,
    d_mat = multirole_demand_ex001,
    p_ta_mat = multirole_prefmat_ex001,
    p_gr_mat = multirole_prefmat_ex001,
    e_mode = "none",
    C = 4
  )

  expect_equal(wrapped, direct)
})

test_that("zero and NULL weights remove model components", {
  x <- multirole_inputs()
  disabled <- prepare_multirole_model(
    x,
    alpha_ta = 0, alpha_gr = NULL,
    beta_ta = 0, beta_gr = NULL,
    phi = 0,
    rho_ta = 0, rho_gr = NULL
  )

  expect_equal(length(ompr::variable_keys(disabled)), x$Ns * x$Nj * 3)
  expect_equal(ompr::nconstraints(disabled), x$Nj * 3 + x$Ns)
  expect_false(any(grepl(
    "^(Tmax|Tmin|Gmax|Gmin|w_ta|w_gr)",
    ompr::variable_keys(disabled)
  )))
  expect_true(all(objective_coefficients(disabled) == 0))
})

test_that("each active objective component contributes only its own structure", {
  x <- multirole_inputs()

  ta_spread <- prepare_multirole_model(
    x,
    alpha_ta = 2, alpha_gr = 0,
    beta_ta = 0, beta_gr = 0, phi = 0,
    rho_ta = 0, rho_gr = 0
  )
  expect_true(all(c("Tmax", "Tmin") %in% ompr::variable_keys(ta_spread)))
  expect_false(any(c("Gmax", "Gmin") %in% ompr::variable_keys(ta_spread)))
  expect_equal(ompr::nconstraints(ta_spread), 24)

  gr_spread <- prepare_multirole_model(
    x,
    alpha_ta = 0, alpha_gr = 3,
    beta_ta = 0, beta_gr = 0, phi = 0,
    rho_ta = 0, rho_gr = 0
  )
  expect_true(all(c("Gmax", "Gmin") %in% ompr::variable_keys(gr_spread)))
  expect_false(any(c("Tmax", "Tmin") %in% ompr::variable_keys(gr_spread)))
  expect_equal(ompr::nconstraints(gr_spread), 24)

  preferences <- prepare_multirole_model(
    x,
    alpha_ta = 0, alpha_gr = 0,
    beta_ta = 2, beta_gr = 3, phi = 0,
    rho_ta = 0, rho_gr = 0
  )
  pref_coef <- objective_coefficients(preferences)
  expect_true(any(pref_coef[grepl(",1\\]$", names(pref_coef))] != 0))
  expect_true(any(pref_coef[grepl(",2\\]$", names(pref_coef))] != 0))
  expect_true(all(pref_coef[grepl(",3\\]$", names(pref_coef))] == 0))
  expect_equal(ompr::nconstraints(preferences), 16)

  e_score <- prepare_multirole_model(
    x,
    alpha_ta = 0, alpha_gr = 0,
    beta_ta = 0, beta_gr = 0, phi = 4,
    rho_ta = 0, rho_gr = 0
  )
  e_coef <- objective_coefficients(e_score)
  expect_true(any(e_coef[grepl(",3\\]$", names(e_coef))] != 0))
  expect_true(all(e_coef[!grepl(",3\\]$", names(e_coef))] == 0))
})

test_that("protection blocks are independent and control fairness membership", {
  x <- multirole_inputs()
  protected <- prepare_multirole_model(
    x,
    alpha_ta = 1, alpha_gr = 1,
    beta_ta = 0, beta_gr = 0, phi = 0,
    rho_ta = 5, rho_gr = 7,
    protected_year_ta = 2,
    protected_year_gr = 3
  )

  expect_true("w_ta[2]" %in% ompr::variable_keys(protected))
  expect_true("w_gr[3]" %in% ompr::variable_keys(protected))
  expect_equal(ompr::nconstraints(protected), 30)

  unprotected <- prepare_multirole_model(
    x,
    alpha_ta = 1, alpha_gr = 1,
    beta_ta = 0, beta_gr = 0, phi = 0,
    rho_ta = 0, rho_gr = 0,
    protected_year_ta = 2,
    protected_year_gr = 3
  )

  expect_false(any(grepl("^w_(ta|gr)", ompr::variable_keys(unprotected))))
  expect_equal(ompr::nconstraints(unprotected), 32)
})

test_that("disabled preference weights allow omitted matrices", {
  no_preferences <- multirole_inputs(p_ta_mat = NULL, p_gr_mat = NULL)

  expect_s3_class(
    prepare_multirole_model(
      no_preferences,
      beta_ta = 0,
      beta_gr = 0
    ),
    "linear_optimization_model"
  )
})

test_that("disabled protection accepts omitted thresholds", {
  x <- multirole_inputs()

  expect_s3_class(
    prepare_multirole_model(
      x,
      rho_ta = 0,
      rho_gr = 0,
      ta_protected_max = NULL,
      gr_protected_max = NULL
    ),
    "linear_optimization_model"
  )
})

test_that("prepare_model dispatches to the multi-role constructor", {
  x <- multirole_inputs()
  direct <- prepare_multirole_model(x)
  wrapped <- prepare_model(x, assignment = "multirole")

  expect_s3_class(wrapped, "linear_optimization_model")
  expect_equal(ompr::variable_keys(wrapped), ompr::variable_keys(direct))
  expect_equal(ompr::nconstraints(wrapped), ompr::nconstraints(direct))
})

test_that("prepare_multirole_model uses capacity stored by extraction", {
  skip_if_not_installed("ompr.roi")
  skip_if_not_installed("ROI.plugin.glpk")

  students_without_past <- multirole_students_ex001[
    , c("student_id", "year", "Name")
  ]
  x <- multirole_inputs(
    student_df = students_without_past,
    e_mode = "rr",
    C = 5,
    single_semester = TRUE
  )
  model <- prepare_multirole_model(x)
  result <- ompr::solve_model(model, ompr.roi::with_ROI(solver = "glpk"))

  expect_equal(result$status, "success")
  expect_error(
    prepare_multirole_model(x, C = 4),
    "unused argument"
  )
})

test_that("solve_assignment supports multi-role post-processing", {
  skip_if_not_installed("ompr.roi")
  skip_if_not_installed("ROI.plugin.glpk")

  x <- multirole_inputs(e_mode = "rr")
  model <- prepare_multirole_model(x)
  wrapped <- solve_assignment(
    model = model,
    assignment = "multirole",
    solver = "glpk",
    student_df = multirole_students_ex001,
    course_codes = rownames(multirole_demand_ex001),
    verbose = FALSE
  )

  expect_named(wrapped, c("model_result", "output"))
  expect_equal(nrow(wrapped$output), nrow(multirole_students_ex001))
  expect_true(any(grepl("-t$", names(wrapped$output))))
  expect_true(any(grepl("-g$", names(wrapped$output))))
  expect_true(any(grepl("-e$", names(wrapped$output))))
})

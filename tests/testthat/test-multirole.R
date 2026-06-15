multirole_inputs <- function(p_ta_mat = multirole_prefmat_ex001,
                             p_gr_mat = multirole_prefmat_ex001,
                             e_mode = "none") {
  extract_multirole_info(
    student_df = multirole_students_ex001,
    d_mat = multirole_demand_ex001,
    p_ta_mat = p_ta_mat,
    p_gr_mat = p_gr_mat,
    e_mode = e_mode,
    C = 4
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
    c("Ns", "Nj", "P_ta", "P_gr", "d", "s", "year", "t1", "g1")
  )
  expect_equal(x$Ns, nrow(multirole_students_ex001))
  expect_equal(x$Nj, nrow(multirole_demand_ex001))
  expect_equal(x$P_ta, multirole_prefmat_ex001)
  expect_equal(x$P_gr, multirole_prefmat_ex001)
  expect_equal(dim(x$d), c(4, 3))
  expect_equal(colnames(x$d), c("TA", "GR", "E"))
  expect_equal(x$s, c(-1, 0, 1, 2))
  expect_equal(x$year, 1:4)
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

test_that("extract_multirole_info validates supplied matrices", {
  bad_dim <- multirole_prefmat_ex001[-1, , drop = FALSE]
  bad_value <- multirole_prefmat_ex001
  bad_value[1, 1] <- Inf

  expect_error(
    multirole_inputs(p_ta_mat = bad_dim),
    "p_ta_mat.*dimensions Ns x Nj"
  )
  expect_error(
    multirole_inputs(p_gr_mat = bad_value),
    "p_gr_mat.*finite numeric matrix"
  )
  expect_error(
    multirole_inputs(p_ta_mat = as.data.frame(multirole_prefmat_ex001)),
    "p_ta_mat.*finite numeric matrix"
  )
  expect_error(
    extract_multirole_info(
      multirole_students_ex001,
      cbind(multirole_demand_ex001, E = 0, extra = 0)
    ),
    "d_mat must be a finite numeric matrix with 2 or 3 columns"
  )
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

test_that("active preference weights require their matrices", {
  no_preferences <- multirole_inputs(p_ta_mat = NULL, p_gr_mat = NULL)

  expect_error(
    prepare_multirole_model(no_preferences),
    "df_list\\$P_ta is required"
  )
  expect_error(
    prepare_multirole_model(
      no_preferences,
      beta_ta = 0,
      beta_gr = 1
    ),
    "df_list\\$P_gr is required"
  )
  expect_s3_class(
    prepare_multirole_model(
      no_preferences,
      beta_ta = 0,
      beta_gr = 0
    ),
    "linear_optimization_model"
  )
})

test_that("prepare_multirole_model validates weights, years, and bounds", {
  x <- multirole_inputs()
  bad_weights <- list(-1, c(1, 2), "1", NA_real_, NaN, Inf)
  for (value in bad_weights) {
    expect_error(
      prepare_multirole_model(x, alpha_gr = value),
      "alpha_gr must be NULL or a single finite non-negative number"
    )
  }

  bad_years <- list(0, 5, 1.5, c(1, 2), "1", NA_real_, NaN, Inf)
  for (value in bad_years) {
    expect_error(
      prepare_multirole_model(x, protected_year_gr = value),
      "protected_year_gr must be a single whole number from 1 to 4"
    )
  }

  expect_error(
    prepare_multirole_model(x, ta_protected_max = -1),
    "ta_protected_max.*non-negative"
  )
  expect_error(
    prepare_multirole_model(x, gr_min = 2, gr_max = 1),
    "gr_min cannot be greater than gr_max"
  )

  expect_error(
    prepare_multirole_model(x, ta_protected_max = NULL),
    "ta_protected_max is required when rho_ta is active"
  )
  expect_error(
    prepare_multirole_model(
      x,
      rho_gr = 1,
      gr_protected_max = NULL
    ),
    "gr_protected_max is required when rho_gr is active"
  )

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

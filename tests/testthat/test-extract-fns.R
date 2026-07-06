test_that("extract_student_info works for diversity and preference", {
  div <- extract_student_info(
    dba_gc_ex001,
    assignment = "diversity",
    self_formed_groups = 4,
    demographic_cols = 2,
    skills = 3
  )

  expect_equal(div$N, 4)
  expect_equal(div$G, 4)
  expect_equal(dim(div$m), c(4, 4))
  expect_equal(dim(div$d), c(4, 4))
  expect_length(div$s, 4)

  pref <- extract_student_info(
    pba_gc_ex002,
    assignment = "preference",
    self_formed_groups = 2,
    pref_mat = pba_prefmat_ex002
  )

  expect_equal(pref$N, 8)
  expect_equal(pref$G, 4)
  expect_equal(dim(pref$m), c(8, 4))
  expect_equal(pref$n, c(2, 2, 2, 2))
  expect_equal(dim(pref$p), c(4, 4))
})

test_that("extract_student_info validates preference and dissimilarity inputs", {
  expect_error(
    extract_student_info(
      pba_gc_ex002,
      assignment = "preference",
      self_formed_groups = 2
    ),
    "Missing preference matrix"
  )

  bad_d <- matrix(c(0, 1, 0, 0), nrow = 2)
  expect_error(
    extract_student_info(
      dba_gc_ex001,
      assignment = "diversity",
      self_formed_groups = 4,
      skills = 3,
      d_mat = bad_d
    ),
    "not symmetric"
  )
})

test_that("extract_phd_info returns aligned PhD inputs and computes E in rr mode", {
  x <- extract_phd_info(
    student_df = multirole_students_ex001,
    p_mat = multirole_prefmat_ex001,
    d_mat = multirole_demand_ex001,
    e_mode = "rr",
    C = 4
  )

  expect_equal(x$Ns, nrow(multirole_students_ex001))
  expect_equal(x$Nj, ncol(multirole_prefmat_ex001))
  expect_equal(dim(x$P), c(4, 4))
  expect_equal(dim(x$d), c(4, 3))
  expect_equal(colnames(x$d), c("TA", "GR", "E"))
  expect_true(sum(x$d[, "E"]) >= 0)
  expect_equal(x$s, c(-1, 0, 1, 2))
  expect_equal(x$year, c(1L, 2L, 3L, 4L))
  expect_equal(unname(x$P), unname(multirole_prefmat_ex001))
})

test_that("extract_phd_info maps custom seniority scores by capped year", {
  students <- multirole_students_ex001
  students$year <- c(0, 2, 3, 5)

  x <- extract_phd_info(
    student_df = students,
    p_mat = multirole_prefmat_ex001,
    d_mat = multirole_demand_ex001,
    e_mode = "none",
    s = c(0, 1, 3, 6)
  )

  expect_equal(x$year, c(1L, 2L, 3L, 4L))
  expect_equal(x$s, c(0, 1, 3, 6))
})

test_that("extract_phd_info supports none mode", {
  x_none <- extract_phd_info(
    student_df = multirole_students_ex001,
    p_mat = multirole_prefmat_ex001,
    d_mat = multirole_demand_ex001,
    e_mode = "none",
    C = 4
  )
  expect_true(all(x_none$d[, "E"] == 0))
})

test_that("extract_params_yaml parses diversity and preference parameter files", {
  d <- extract_params_yaml(
    system.file("extdata", "dba_params_ex001.yml", package = "grouper"),
    assignment = "diversity"
  )
  expect_true(all(c("n_topics", "nmin", "nmax", "rmin", "rmax") %in% names(d)))
  expect_equal(NROW(d$nmin), d$n_topics)
  expect_equal(NCOL(d$nmin), d$rmax)

  p <- extract_params_yaml(
    system.file("extdata", "pba_params_ex002.yml", package = "grouper"),
    assignment = "preference"
  )
  expect_true(all(c("n_topics", "nmin", "nmax", "rmin", "rmax") %in% names(p)))
  expect_equal(NROW(p$nmin), p$B * p$n_topics)
  expect_equal(NCOL(p$nmin), p$rmax)
})

test_that("extract_info wrapper dispatches to student extractors", {
  div_direct <- extract_student_info(
    dba_gc_ex001,
    assignment = "diversity",
    self_formed_groups = 4,
    demographic_cols = 2,
    skills = 3
  )
  div_wrap <- extract_info(
    assignment = "diversity",
    dframe = dba_gc_ex001,
    self_formed_groups = 4,
    demographic_cols = 2,
    skills = 3
  )
  expect_equal(div_wrap, div_direct)

  pref_direct <- extract_student_info(
    pba_gc_ex002,
    assignment = "preference",
    self_formed_groups = 2,
    pref_mat = pba_prefmat_ex002
  )
  pref_wrap <- extract_info(
    assignment = "preference",
    dframe = pba_gc_ex002,
    self_formed_groups = 2,
    pref_mat = pba_prefmat_ex002
  )
  expect_equal(pref_wrap, pref_direct)
})

test_that("extract_info wrapper dispatches to phd extractor", {
  phd_wrap <- extract_info(
    assignment = "phd",
    student_df = multirole_students_ex001,
    p_mat = multirole_prefmat_ex001,
    d_mat = multirole_demand_ex001,
    e_mode = "none",
    C = 4
  )

  expect_true(all(c("Ns", "Nj", "P", "d", "s", "year", "t1", "g1") %in% names(phd_wrap)))
  expect_equal(phd_wrap$Ns, nrow(multirole_students_ex001))
  expect_equal(phd_wrap$Nj, ncol(multirole_prefmat_ex001))
  expect_equal(dim(phd_wrap$P), c(4, 4))
  expect_equal(dim(phd_wrap$d), c(4, 3))
})

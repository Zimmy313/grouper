#' Prepare the diversity-based assignment model
#'
#' @param df_list The output list from [extract_student_info()] for
#'   `assignment = "diversity"`.
#' @param yaml_list The output list from [extract_params_yaml()] for
#'   `assignment = "diversity"`.
#' @param w1,w2 Numeric values between 0 and 1. Should sum to 1. These weights
#'   correspond to the importance given to the diversity- and skill-based
#'   portions in the objective function.
#'
#' @returns An ompr model.
#' @export
prepare_diversity_model <- function(df_list, yaml_list, w1 = 0.5, w2 = 0.5) {
  N <- df_list$N
  G <- df_list$G
  m <- df_list$m
  d <- df_list$d
  s <- df_list$s

  n_topics <- yaml_list$n_topics
  #R <- yaml_list$R
  nmin <- yaml_list$nmin
  nmax <- yaml_list$nmax
  rmin <- yaml_list$rmin
  rmax <- yaml_list$rmax
  R <- rmax

  model <- ompr::MIPModel() %>%
    # DEFINE DECISION VARIABLES
    ompr::add_variable(x[g,t,r], g=1:G, t=1:n_topics, r=1:R, type="binary") %>%
    ompr::add_variable(z[i,j,t,r], i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R, type="binary") %>%
    ompr::add_variable(a[t,r], t=1:n_topics, r=1:R, type="binary")

  if(is.null(s)) {
    model <- model %>%
      # DEFINE OBJECTIVE FUNCTION
      ompr::set_objective(
        # MAXIMISE DIVERSITY
        ompr::sum_over(z[i,j,t,r]*d[i,j], i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R), "max") %>%
      # DEFINE CONSTRAINTS (EACH GROUP ASSIGNED A TOPIC-REP)
      ompr::add_constraint(ompr::sum_over(x[g,t,r], t=1:n_topics, r=1:R)==1, g=1:G) %>%
      # DEFINE CONSTRAINTS (WHETHER 2 STUDENTS IN SAME TOPIC-REP)
      ompr::add_constraint(z[i,j,t,r]<=ompr::sum_over(m[i,g]*x[g,t,r], g=1:G), i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(z[i,j,t,r]<=ompr::sum_over(m[j,g]*x[g,t,r], g=1:G), i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(z[i,j,t,r]>=ompr::sum_over(m[i,g]*x[g,t,r], g=1:G) + ompr::sum_over(m[j,g]*x[g,t,r], g=1:G)-1, i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R) %>%
      # DEFINE CONSTRAINTS (MIN AND MAX NO. OF REPETITIONS PER TOPIC)
      ompr::add_constraint(a[t,r]>=x[g,t,r], g=1:G, t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(a[t,r]<=ompr::sum_over(x[g,t,r], g=1:G), t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(ompr::sum_over(a[t,r], r=1:R)>=rmin, t=1:n_topics) %>%
      ompr::add_constraint(ompr::sum_over(a[t,r], r=1:R)<=rmax, t=1:n_topics) %>%
      # DEFINE CONSTRAINTS (MIN AND MAX NO. OF STUDENTS PER TOPIC-REPETITION)
      ompr::add_constraint(ompr::sum_over(m[i,g]*x[g,t,r], i=1:N, g=1:G)>=a[t,r]*nmin[t,r], t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(ompr::sum_over(m[i,g]*x[g,t,r], i=1:N, g=1:G)<=a[t,r]*nmax[t,r], t=1:n_topics, r=1:R)
  } else {
    model <- model %>%
      ompr::add_variable(smin, type="continuous", lb=0) %>%
      ompr::add_variable(smax, type="continuous", lb=0) %>%
      # DEFINE OBJECTIVE FUNCTION
      ompr::set_objective(
        # MAXIMISE DIVERSITY
        w1*ompr::sum_over(z[i,j,t,r]*d[i,j], i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R)+
          # MINIMIZE SKILL VARIABILITY
          w2*(smin-smax), "max") %>%
      # DEFINE CONSTRAINTS (EACH GROUP ASSIGNED A TOPIC-REP)
      ompr::add_constraint(ompr::sum_over(x[g,t,r], t=1:n_topics, r=1:R)==1, g=1:G) %>%
      # DEFINE CONSTRAINTS (WHETHER 2 STUDENTS IN SAME TOPIC-REP)
      ompr::add_constraint(z[i,j,t,r]<=ompr::sum_over(m[i,g]*x[g,t,r], g=1:G), i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(z[i,j,t,r]<=ompr::sum_over(m[j,g]*x[g,t,r], g=1:G), i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(z[i,j,t,r]>=ompr::sum_over(m[i,g]*x[g,t,r], g=1:G) + ompr::sum_over(m[j,g]*x[g,t,r], g=1:G)-1, i=1:(N-1), j=(i+1):N, t=1:n_topics, r=1:R) %>%
      # DEFINE CONSTRAINTS (MIN AND MAX NO. OF REPETITIONS PER TOPIC)
      ompr::add_constraint(a[t,r]>=x[g,t,r], g=1:G, t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(a[t,r]<=ompr::sum_over(x[g,t,r], g=1:G), t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(ompr::sum_over(a[t,r], r=1:R)>=rmin, t=1:n_topics) %>%
      ompr::add_constraint(ompr::sum_over(a[t,r], r=1:R)<=rmax, t=1:n_topics) %>%
      # DEFINE CONSTRAINTS (MIN AND MAX NO. OF STUDENTS PER TOPIC-REPETITION)
      ompr::add_constraint(ompr::sum_over(m[i,g]*x[g,t,r], i=1:N, g=1:G)>=a[t,r]*nmin[t,r], t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(ompr::sum_over(m[i,g]*x[g,t,r], i=1:N, g=1:G)<=a[t,r]*nmax[t,r], t=1:n_topics, r=1:R) %>%
      # DEFINE CONSTRAINTS (SKILL VARIABILITY)
      ompr::add_constraint(ompr::sum_over(m[i,g]*x[g,t,r]*s[i], i=1:N, g=1:G)>=smin, t=1:n_topics, r=1:R) %>%
      ompr::add_constraint(ompr::sum_over(m[i,g]*x[g,t,r]*s[i], i=1:N, g=1:G)<=smax, t=1:n_topics, r=1:R)
  }

  model
}


#' Prepare the preference-based assignment model
#'
#' @param df_list The output list from [extract_student_info()] for
#'   `assignment = "preference"`.
#' @param yaml_list The output list from [extract_params_yaml()] for
#'   `assignment = "preference"`.
#'
#' @returns An ompr model.
#' @export
prepare_preference_model <- function(df_list, yaml_list) {
  N <- df_list$N
  G <- df_list$G
  m <- df_list$m
  n <- df_list$n
  p <- df_list$p

  T <- yaml_list$n_topics
  B <- yaml_list$B
  R <- yaml_list$R
  nmin <- yaml_list$nmin
  nmax <- yaml_list$nmax
  rmin <- yaml_list$rmin
  rmax <- yaml_list$rmax

  ompr::MIPModel() %>%
    # DEFINE DECISION VARIABLES
    ompr::add_variable(x[g,t,r], g=1:G, t=1:(B*T), r=1:R, type="binary") %>%
    ompr::add_variable(a[t,r], t=1:(B*T), r=1:R, type="binary") %>%
    # DEFINE OBJECTIVE FUNCTION
    ompr::set_objective(ompr::sum_over(x[g,t,r]*n[g]*p[g,t], g=1:G, t=1:(B*T), r=1:R), "max") %>%
    # DEFINE CONSTRAINTS (EACH GROUP ASSIGNED A TOPIC-REP)
    ompr::add_constraint(ompr::sum_over(x[g,t,r], t=1:(B*T), r=1:R)==1, g=1:G) %>%
    # DEFINE CONSTRAINTS (MIN NO. OF REPETITIONS PER TOPIC)
    ompr::add_constraint(a[t,r]>=x[g,t,r], g=1:G, t=1:(B*T), r=1:R) %>%
    ompr::add_constraint(a[t,r]<=ompr::sum_over(x[g,t,r], g=1:G), t=1:(B*T), r=1:R) %>%
    ompr::add_constraint(ompr::sum_over(a[t,r], r=1:R)>=rmin, t=1:T) %>%
    ompr::add_constraint(ompr::sum_over(a[t,r], r=1:R)<=rmax, t=1:T) %>%
    # DEFINE CONSTRAINTS (BALANCED NO. OF REPETITIONS FOR SUBGROUPS)
    ompr::add_constraint(ompr::sum_over(a[t,r], r=1:R)==ompr::sum_over(a[(b*T+t),r], r=1:R), t=1:T, b=min(1,B-1):max(0,B-1)) %>%
    # DEFINE CONSTRAINTS (MIN AND MAX NO. OF STUDENTS PER TOPIC-REPETITION)
    ompr::add_constraint(ompr::sum_over(m[i,g]*x[g,t,r], i=1:N, g=1:G)>=a[t,r]*nmin[t,r], t=1:(B*T), r=1:R) %>%
    ompr::add_constraint(ompr::sum_over(m[i,g]*x[g,t,r], i=1:N, g=1:G)<=a[t,r]*nmax[t,r], t=1:(B*T), r=1:R)
}



#' Prepare the PhD workload allocation model
#'
#' Builds a mixed-integer optimisation model for assigning TA, GR, and E units
#' across students and courses.
#'
#' @param df_list A list of model inputs, typically from [extract_phd_info()].
#'   Required elements are:
#'   \itemize{
#'   \item \code{Ns}: number of students
#'   \item \code{Nj}: number of courses
#'   \item \code{P}: preference matrix \code{[i, j]}
#'   \item \code{d}: demand matrix \code{[j, r]} where \code{r = 1:3} for TA, GR, E
#'   \item \code{s}: student-level E-allocation score vector
#'   \item \code{year}: year-of-study vector, with values from 1 to 4
#'   \item \code{t1}: past TA workload vector
#'   \item \code{g1}: past GR workload vector
#'   }
#' @param t_max_y1 Maximum current-semester TA load for students in the
#'   protected year before slack is used. The argument name is retained for
#'   backward compatibility.
#' @param e_max Optional upper bound on per-student E units in current semester.
#' @param ta_min,ta_max Optional lower/upper bounds on per-student TA units in
#'   current semester.
#' @param gr_min,gr_max Optional lower/upper bounds on per-student GR units in
#'   current semester.
#' @param e_min Optional lower bound on per-student E units in current semester.
#' @param alpha Objective weight on TA spread \code{(Tmax - Tmin)}.
#' @param beta Objective weight on TA preference term.
#' @param phi Objective weight on the score-weighted E term. When `phi > 0`,
#'   larger values in `df_list$s` make E allocation more attractive.
#' @param rho Objective weight on protected-cohort TA slack penalties.
#' @param C Semester workload capacity per student. The model fixes annual
#'   workload at \code{2 * C} via \code{T_i + G_i + e_i^(2) == 2 * C}.
#'   Default is \code{4}.
#' @param protected_year A single whole number from 1 to 4 identifying the
#'   year-of-study cohort that receives the soft TA-load protection. Students
#'   from all other years are included in the TA fairness spread. Defaults to
#'   Year 1.
#'
#' @details
#' Index alignment is critical: \code{P[i, j]}, \code{d[j, ]}, \code{s[i]},
#' \code{year[i]}, \code{t1[i]}, and \code{g1[i]} must refer to the same
#' student/course ordering. Protection and TA fairness groups are based on
#' `year`; `s` is used only in the E-allocation objective term.
#'
#' @return An \code{ompr} model object ready for \code{ompr::solve_model()}.
#' @export
prepare_phd_model <- function(df_list, t_max_y1 = 1, e_max = NULL,
                              ta_min = NULL, ta_max = NULL,
                              gr_min = NULL, gr_max = NULL,
                              e_min = NULL,
                              alpha = 2, beta = 1, phi = 1, rho = 10,
                              C = 4, protected_year = 1) {
  # keep role order fixed: 1 = TA, 2 = GR, 3 = E

  # extract inputs
  Ns <- df_list$Ns
  Nj <- df_list$Nj
  P  <- df_list$P   # preference matrix [i, j]
  d  <- df_list$d   # demand matrix [j, r], r = 1:3 for TA, GR, E
  s  <- df_list$s   # E-allocation scores
  year <- df_list$year
  t1 <- df_list$t1  # previous semester TA workload
  g1 <- df_list$g1  # previous semester GR workload

  if (!is.numeric(protected_year) ||
      length(protected_year) != 1 ||
      !is.finite(protected_year) ||
      protected_year %% 1 != 0 ||
      protected_year < 1 ||
      protected_year > 4) {
    stop("protected_year must be a single whole number from 1 to 4.")
  }
  protected_year <- as.integer(protected_year)

  idx_protected <- which(year == protected_year)
  idx_fairness <- which(year != protected_year)

  # check optional workload bounds
  validate_optional_bound <- function(x, nm) {
    if (!is.null(x) && (!is.numeric(x) || length(x) != 1 || is.na(x) || x < 0)) {
      stop(nm, " must be NULL or a single non-negative number.")
    }
  }
  validate_optional_bound(e_max, "e_max")
  validate_optional_bound(ta_min, "ta_min")
  validate_optional_bound(ta_max, "ta_max")
  validate_optional_bound(gr_min, "gr_min")
  validate_optional_bound(gr_max, "gr_max")
  validate_optional_bound(e_min, "e_min")

  if (!is.null(ta_min) && !is.null(ta_max) && ta_min > ta_max) {
    stop("ta_min cannot be greater than ta_max.")
  }
  if (!is.null(gr_min) && !is.null(gr_max) && gr_min > gr_max) {
    stop("gr_min cannot be greater than gr_max.")
  }
  if (!is.null(e_min) && !is.null(e_max) && e_min > e_max) {
    stop("e_min cannot be greater than e_max.")
  }

  model <- ompr::MIPModel() %>%
    # assignment vars
    ompr::add_variable(
      X[i, j, r],
      i = 1:Ns, j = 1:Nj, r = 1:3,
      type = "integer", lb = 0
    ) %>%
    # spread vars for yearly TA among unprotected students
    ompr::add_variable(Tmax, type = "continuous", lb = 0) %>%
    ompr::add_variable(Tmin, type = "continuous", lb = 0) %>%
    # slack for the protected cohort's TA soft bound
    ompr::add_variable(w[i], i = idx_protected, type = "continuous", lb = 0) %>%
    ompr::set_objective(
      alpha * (Tmax - Tmin) -
        beta * ompr::sum_over(P[i, j] * X[i, j, 1], i = 1:Ns, j = 1:Nj) -
        phi  * ompr::sum_over(s[i] * X[i, j, 3], i = 1:Ns, j = 1:Nj) +
        rho  * ompr::sum_over(w[i], i = idx_protected),
      sense = "min"
    ) %>%
    # demand satisfaction for each job and role
    ompr::add_constraint(
      ompr::sum_over(X[i, j, r], i = 1:Ns) == d[j, r],
      j = 1:Nj, r = 1:3
    ) %>%
    # yearly TA spread constraints for unprotected students:
    # T_i = t1[i] + sum_j X[i,j,TA]
    ompr::add_constraint(
      t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj) <= Tmax,
      i = idx_fairness
    ) %>%
    ompr::add_constraint(
      t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj) >= Tmin,
      i = idx_fairness
    ) %>%
    # annual workload cap from semester capacity C:
    # T_i + G_i + e_i^(2) == 2 * C
    ompr::add_constraint(
      (t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj)) +
      (g1[i] + ompr::sum_over(X[i, j, 2], j = 1:Nj)) +
               ompr::sum_over(X[i, j, 3], j = 1:Nj) == 2 * C,
      i = 1:Ns
    ) %>%
    # protected cohort soft TA bound on current semester TA workload
    ompr::add_constraint(
      ompr::sum_over(X[i, j, 1], j = 1:Nj) <= t_max_y1 + w[i],
      i = idx_protected
    )

  # optional per-student lower/upper bound on TA units
  if (!is.null(ta_min)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 1], j = 1:Nj) >= ta_min,
        i = 1:Ns
      )
  }
  if (!is.null(ta_max)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 1], j = 1:Nj) <= ta_max,
        i = 1:Ns
      )
  }

  # optional per-student lower/upper bound on GR units
  if (!is.null(gr_min)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 2], j = 1:Nj) >= gr_min,
        i = 1:Ns
      )
  }
  if (!is.null(gr_max)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 2], j = 1:Nj) <= gr_max,
        i = 1:Ns
      )
  }

  # optional per-student lower/upper bound on E units
  if (!is.null(e_min)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 3], j = 1:Nj) >= e_min,
        i = 1:Ns
      )
  }
  if (!is.null(e_max)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 3], j = 1:Nj) <= e_max,
        i = 1:Ns
      )
  }

  model
}


#' Prepare the multi-role workload allocation model
#'
#' Builds a mixed-integer model for assigning TA, GR, and lighter E duties
#' while balancing role-specific workload, preferences, and cohort protection.
#'
#' @param df_list A model input list from [extract_multirole_info()].
#' @param ta_protected_max,gr_protected_max Non-negative soft upper limits on
#'   current-semester TA or GR workload for the corresponding protected cohort.
#'   A value may be `NULL` when the corresponding `rho_*` term is disabled.
#' @param e_max Optional upper bound on per-individual E units.
#' @param ta_min,ta_max Optional lower and upper bounds on per-individual TA
#'   units.
#' @param gr_min,gr_max Optional lower and upper bounds on per-individual GR
#'   units.
#' @param e_min Optional lower bound on per-individual E units.
#' @param alpha_ta,alpha_gr Non-negative weights for annual TA and GR workload
#'   spread.
#' @param beta_ta,beta_gr Non-negative weights for TA and GR preferences.
#' @param phi Non-negative weight for score-guided E allocation.
#' @param rho_ta,rho_gr Non-negative penalties for TA and GR protected-cohort
#'   slack.
#' @param C Semester workload capacity per individual. Annual total workload is
#'   fixed at `2 * C`.
#' @param protected_year_ta,protected_year_gr Whole numbers from 1 to 4
#'   identifying the TA- and GR-protected cohorts.
#'
#' @details
#' Any objective weight set to `NULL` or zero is disabled. Disabled preference
#' and E terms are omitted from the objective. Disabling a spread term also
#' omits its two spread variables and fairness constraints. Disabling a
#' protection penalty omits that role's slack variables and soft-limit
#' constraints, and includes every individual in that role's fairness spread.
#'
#' When a preference term is active, the corresponding `P_ta` or `P_gr`
#' element must be present in `df_list`.
#'
#' @returns An `ompr` model.
#'
#' @examples
#' inputs <- extract_multirole_info(
#'   student_df = multirole_students_ex001,
#'   d_mat = multirole_demand_ex001,
#'   p_ta_mat = multirole_prefmat_ex001,
#'   p_gr_mat = multirole_prefmat_ex001,
#'   e_mode = "rr"
#' )
#' model <- prepare_multirole_model(
#'   inputs,
#'   alpha_gr = 1,
#'   beta_gr = 1,
#'   rho_gr = 10
#' )
#'
#' @export
prepare_multirole_model <- function(
    df_list,
    ta_protected_max = 1, gr_protected_max = 1,
    e_max = NULL,
    ta_min = NULL, ta_max = NULL,
    gr_min = NULL, gr_max = NULL,
    e_min = NULL,
    alpha_ta = 2, alpha_gr = NULL,
    beta_ta = 1, beta_gr = NULL,
    phi = 1,
    rho_ta = 10, rho_gr = NULL,
    C = 4,
    protected_year_ta = 1, protected_year_gr = 1) {
  Ns <- df_list$Ns
  Nj <- df_list$Nj
  P_ta <- df_list$P_ta
  P_gr <- df_list$P_gr
  d <- df_list$d
  s <- df_list$s
  year <- df_list$year
  t1 <- df_list$t1
  g1 <- df_list$g1

  validate_weight <- function(x, nm) {
    if (!is.null(x) &&
        (!is.numeric(x) || length(x) != 1 || !is.finite(x) || x < 0)) {
      stop(nm, " must be NULL or a single finite non-negative number.")
    }
  }
  weights <- list(
    alpha_ta = alpha_ta, alpha_gr = alpha_gr,
    beta_ta = beta_ta, beta_gr = beta_gr,
    phi = phi, rho_ta = rho_ta, rho_gr = rho_gr
  )
  for (nm in names(weights)) {
    validate_weight(weights[[nm]], nm)
  }

  is_active <- function(x) !is.null(x) && x > 0
  active_alpha_ta <- is_active(alpha_ta)
  active_alpha_gr <- is_active(alpha_gr)
  active_beta_ta <- is_active(beta_ta)
  active_beta_gr <- is_active(beta_gr)
  active_phi <- is_active(phi)
  active_rho_ta <- is_active(rho_ta)
  active_rho_gr <- is_active(rho_gr)

  validate_year <- function(x, nm) {
    if (!is.numeric(x) || length(x) != 1 || !is.finite(x) ||
        x %% 1 != 0 || x < 1 || x > 4) {
      stop(nm, " must be a single whole number from 1 to 4.")
    }
    as.integer(x)
  }
  protected_year_ta <- validate_year(protected_year_ta, "protected_year_ta")
  protected_year_gr <- validate_year(protected_year_gr, "protected_year_gr")

  validate_optional_bound <- function(x, nm) {
    if (!is.null(x) &&
        (!is.numeric(x) || length(x) != 1 || !is.finite(x) || x < 0)) {
      stop(nm, " must be NULL or a single finite non-negative number.")
    }
  }
  bounds <- list(
    ta_protected_max = ta_protected_max,
    gr_protected_max = gr_protected_max,
    e_max = e_max,
    ta_min = ta_min, ta_max = ta_max,
    gr_min = gr_min, gr_max = gr_max,
    e_min = e_min
  )
  for (nm in names(bounds)) {
    validate_optional_bound(bounds[[nm]], nm)
  }

  if (active_rho_ta && is.null(ta_protected_max)) {
    stop("ta_protected_max is required when rho_ta is active.")
  }
  if (active_rho_gr && is.null(gr_protected_max)) {
    stop("gr_protected_max is required when rho_gr is active.")
  }
  if (!is.null(ta_min) && !is.null(ta_max) && ta_min > ta_max) {
    stop("ta_min cannot be greater than ta_max.")
  }
  if (!is.null(gr_min) && !is.null(gr_max) && gr_min > gr_max) {
    stop("gr_min cannot be greater than gr_max.")
  }
  if (!is.null(e_min) && !is.null(e_max) && e_min > e_max) {
    stop("e_min cannot be greater than e_max.")
  }

  require_active_preference <- function(x, nm, active) {
    if (active && is.null(x)) {
      stop(nm, " is required when its preference weight is active.")
    }
  }
  require_active_preference(P_ta, "df_list$P_ta", active_beta_ta)
  require_active_preference(P_gr, "df_list$P_gr", active_beta_gr)

  idx_protected_ta <- which(year == protected_year_ta)
  idx_protected_gr <- which(year == protected_year_gr)
  idx_fairness_ta <- if (active_rho_ta) {
    which(year != protected_year_ta)
  } else {
    seq_len(Ns)
  }
  idx_fairness_gr <- if (active_rho_gr) {
    which(year != protected_year_gr)
  } else {
    seq_len(Ns)
  }

  model <- ompr::MIPModel() %>%
    ompr::add_variable(
      X[i, j, r],
      i = 1:Ns, j = 1:Nj, r = 1:3,
      type = "integer", lb = 0
    )

  if (active_alpha_ta) {
    model <- model %>%
      ompr::add_variable(Tmax, type = "continuous", lb = 0) %>%
      ompr::add_variable(Tmin, type = "continuous", lb = 0)
  }
  if (active_alpha_gr) {
    model <- model %>%
      ompr::add_variable(Gmax, type = "continuous", lb = 0) %>%
      ompr::add_variable(Gmin, type = "continuous", lb = 0)
  }
  if (active_rho_ta) {
    model <- model %>%
      ompr::add_variable(
        w_ta[i], i = idx_protected_ta,
        type = "continuous", lb = 0
      )
  }
  if (active_rho_gr) {
    model <- model %>%
      ompr::add_variable(
        w_gr[i], i = idx_protected_gr,
        type = "continuous", lb = 0
      )
  }

  objective_expr <- quote(0)
  append_objective <- function(current, term) call("+", current, term)

  if (active_alpha_ta) {
    objective_expr <- append_objective(
      objective_expr,
      substitute(A * (Tmax - Tmin), list(A = alpha_ta))
    )
  }
  if (active_alpha_gr) {
    objective_expr <- append_objective(
      objective_expr,
      substitute(A * (Gmax - Gmin), list(A = alpha_gr))
    )
  }
  if (active_beta_ta) {
    objective_expr <- append_objective(
      objective_expr,
      substitute(
        -B * ompr::sum_expr(
          P[i, j] * X[i, j, 1], i = 1:NS, j = 1:NJ
        ),
        list(B = beta_ta, P = P_ta, NS = Ns, NJ = Nj)
      )
    )
  }
  if (active_beta_gr) {
    objective_expr <- append_objective(
      objective_expr,
      substitute(
        -B * ompr::sum_expr(
          P[i, j] * X[i, j, 2], i = 1:NS, j = 1:NJ
        ),
        list(B = beta_gr, P = P_gr, NS = Ns, NJ = Nj)
      )
    )
  }
  if (active_phi) {
    objective_expr <- append_objective(
      objective_expr,
      substitute(
        -PHI * ompr::sum_expr(
          S[i] * X[i, j, 3], i = 1:NS, j = 1:NJ
        ),
        list(PHI = phi, S = s, NS = Ns, NJ = Nj)
      )
    )
  }
  if (active_rho_ta) {
    objective_expr <- append_objective(
      objective_expr,
      substitute(
        RHO * ompr::sum_expr(w_ta[i], i = IDX),
        list(RHO = rho_ta, IDX = idx_protected_ta)
      )
    )
  }
  if (active_rho_gr) {
    objective_expr <- append_objective(
      objective_expr,
      substitute(
        RHO * ompr::sum_expr(w_gr[i], i = IDX),
        list(RHO = rho_gr, IDX = idx_protected_gr)
      )
    )
  }

  model <- ompr::set_objective_(
    model,
    expression = objective_expr,
    sense = "min"
  ) %>%
    ompr::add_constraint(
      ompr::sum_over(X[i, j, r], i = 1:Ns) == d[j, r],
      j = 1:Nj, r = 1:3
    ) %>%
    ompr::add_constraint(
      (t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj)) +
        (g1[i] + ompr::sum_over(X[i, j, 2], j = 1:Nj)) +
        ompr::sum_over(X[i, j, 3], j = 1:Nj) == 2 * C,
      i = 1:Ns
    )

  if (active_alpha_ta) {
    model <- model %>%
      ompr::add_constraint(
        t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj) <= Tmax,
        i = idx_fairness_ta
      ) %>%
      ompr::add_constraint(
        t1[i] + ompr::sum_over(X[i, j, 1], j = 1:Nj) >= Tmin,
        i = idx_fairness_ta
      )
  }
  if (active_alpha_gr) {
    model <- model %>%
      ompr::add_constraint(
        g1[i] + ompr::sum_over(X[i, j, 2], j = 1:Nj) <= Gmax,
        i = idx_fairness_gr
      ) %>%
      ompr::add_constraint(
        g1[i] + ompr::sum_over(X[i, j, 2], j = 1:Nj) >= Gmin,
        i = idx_fairness_gr
      )
  }
  if (active_rho_ta) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 1], j = 1:Nj) <=
          ta_protected_max + w_ta[i],
        i = idx_protected_ta
      )
  }
  if (active_rho_gr) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 2], j = 1:Nj) <=
          gr_protected_max + w_gr[i],
        i = idx_protected_gr
      )
  }

  if (!is.null(ta_min)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 1], j = 1:Nj) >= ta_min,
        i = 1:Ns
      )
  }
  if (!is.null(ta_max)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 1], j = 1:Nj) <= ta_max,
        i = 1:Ns
      )
  }
  if (!is.null(gr_min)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 2], j = 1:Nj) >= gr_min,
        i = 1:Ns
      )
  }
  if (!is.null(gr_max)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 2], j = 1:Nj) <= gr_max,
        i = 1:Ns
      )
  }
  if (!is.null(e_min)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 3], j = 1:Nj) >= e_min,
        i = 1:Ns
      )
  }
  if (!is.null(e_max)) {
    model <- model %>%
      ompr::add_constraint(
        ompr::sum_over(X[i, j, 3], j = 1:Nj) <= e_max,
        i = 1:Ns
      )
  }

  model
}


prepare_model_params_from_dots <- function(assignment, dots) {
  required_fields <- if (assignment == "diversity") {
    c("n_topics", "R", "nmin", "nmax", "rmin", "rmax")
  } else {
    c("n_topics", "B", "R", "nmin", "nmax", "rmin", "rmax")
  }

  missing_fields <- required_fields[vapply(
    required_fields,
    function(x) is.null(dots[[x]]),
    logical(1)
  )]

  if (length(missing_fields) > 0) {
    stop(
      "Missing required parameters for assignment = '", assignment, "': ",
      paste(missing_fields, collapse = ", "), "."
    )
  }

  if (assignment == "diversity") {
    nmin <- matrix(
      data = dots$nmin,
      nrow = dots$n_topics,
      ncol = dots$R,
      byrow = TRUE
    )
    nmax <- matrix(
      data = dots$nmax,
      nrow = dots$n_topics,
      ncol = dots$R,
      byrow = TRUE
    )

    return(list(
      n_topics = dots$n_topics,
      R = dots$R,
      nmin = nmin,
      nmax = nmax,
      rmin = dots$rmin,
      rmax = dots$rmax
    ))
  }

  nmin <- matrix(
    data = dots$nmin,
    nrow = dots$B * dots$n_topics,
    ncol = dots$R,
    byrow = TRUE
  )
  nmax <- matrix(
    data = dots$nmax,
    nrow = dots$B * dots$n_topics,
    ncol = dots$R,
    byrow = TRUE
  )

  list(
    n_topics = dots$n_topics,
    B = dots$B,
    R = dots$R,
    nmin = nmin,
    nmax = nmax,
    rmin = dots$rmin,
    rmax = dots$rmax
  )
}


#' Initialise optimisation model (wrapper)
#'
#' @param df_list Model input list.
#' @param yaml_list Parameter list from [extract_params_yaml()]. Optional for
#'   `assignment = "diversity"` and `assignment = "preference"` for backward
#'   compatibility. If supplied, this list is used directly. Ignored for
#'   `assignment = "phd"` and `assignment = "multirole"`.
#' @param assignment Character string indicating model type. Must be one of
#'   `"diversity"`, `"preference"`, `"phd"`, or `"multirole"`.
#' @param w1,w2 Numeric values between 0 and 1. Should sum to 1. Used only for
#'   `assignment = "diversity"`.
#' @param ... Additional arguments:
#'   * For `assignment = "diversity"` when `yaml_list` is `NULL`: supply
#'     `n_topics`, `R`, `nmin`, `nmax`, `rmin`, and `rmax`.
#'   * For `assignment = "preference"` when `yaml_list` is `NULL`: supply
#'     `n_topics`, `B`, `R`, `nmin`, `nmax`, `rmin`, and `rmax`.
#'   * For `assignment = "phd"`: passed to [prepare_phd_model()], including
#'     `protected_year` when a cohort other than Year 1 should receive the soft
#'     TA-load protection.
#'   * For `assignment = "multirole"`: passed to
#'     [prepare_multirole_model()].
#'
#' @returns An ompr model.
#' @export
prepare_model <- function(df_list, yaml_list = NULL,
                          assignment = c(
                            "diversity", "preference", "phd", "multirole"
                          ),
                          w1 = 0.5, w2 = 0.5, ...) {
  assignment <- match.arg(assignment)
  dots <- list(...)

  if (assignment == "diversity") {
    params_list <- if (is.null(yaml_list)) {
      prepare_model_params_from_dots(assignment = assignment, dots = dots)
    } else {
      yaml_list
    }
    return(prepare_diversity_model(df_list, params_list, w1 = w1, w2 = w2))
  }

  if (assignment == "preference") {
    params_list <- if (is.null(yaml_list)) {
      prepare_model_params_from_dots(assignment = assignment, dots = dots)
    } else {
      yaml_list
    }
    return(prepare_preference_model(df_list, params_list))
  }

  if (assignment == "multirole") {
    return(do.call(
      prepare_multirole_model,
      c(list(df_list = df_list), dots)
    ))
  }

  do.call(prepare_phd_model, c(list(df_list = df_list), dots))
}

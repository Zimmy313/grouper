#' Compute total pairwise diversity for a set of students
#'
#' @param id Integer vector of student indices into `dmat`.
#' @param dmat Numeric distance matrix (students × students).
#'
#' @returns Scalar: sum of upper-triangle distances among `id`.
#' @keywords internal
compute_diversity <- function(id, dmat) {
  sum(dmat[id, id])/2
}

#' Summarise a DBA result by topic-repetition group
#'
#' @param df_result Data frame returned by [solve_assignment()] for a diversity
#'   model. Must contain columns `topic`, `rep`, and the column named by
#'   `id_col`.
#' @param df_list Input list from [extract_student_info()]. Must contain `d`
#'   (distance matrix) and optionally `s` (skill vector).
#' @param id_col Character. Name of the student-ID column in `df_result`.
#'
#' @returns A grouped summary tibble with columns `topic`, `rep`, `n`, and
#'   `total_diversity` (plus `total_skill` when `df_list$s` is present).
#' @keywords internal
summary_dba <- function(df_result, df_list, id_col) {
  if(is.null(df_list$s)) {
    df_result %>% group_by(topic, rep) %>%
      summarise(n=n(),
                total_diversity = compute_diversity(.data[[id_col]], df_list$d),
                .groups = "drop")
  } else {
    df_result %>% group_by(topic, rep) %>%
      summarise(n=n(),
                total_skill = sum(df_list$s[.data[[id_col]]]),
                total_diversity = compute_diversity(.data[[id_col]], df_list$d),
                .groups = "drop")
  }
}

#' Look up a group's preference score for a topic-subtopic combination
#'
#' @param group_num Integer. Group index (row of `pref_mat`).
#' @param topic Integer. Base topic index.
#' @param subtopic Integer. Subtopic (subgroup) index.
#' @param pref_mat Numeric preference matrix (groups × topic-subtopic columns).
#' @param n_topics Integer. Number of base topics.
#'
#' @returns Scalar preference score.
#' @keywords internal
get_group_pref_score <- function(group_num, topic, subtopic, pref_mat, n_topics) {
  col_num <- (subtopic - 1)*n_topics + topic
  pref_mat[group_num, col_num]
}

#' Summarise a PBA result by topic-subtopic-repetition group
#'
#' @param df_result Data frame returned by [solve_assignment()] for a preference
#'   model. Must contain columns `group`, `topic2`, `subtopic`, and `rep`.
#' @param df_list Input list from [extract_student_info()] for
#'   `assignment = "preference"`. Must contain `p` (preference matrix).
#' @param n_topics Integer. Number of base topics.
#'
#' @returns A grouped summary tibble with columns `topic2`, `subtopic`, `rep`,
#'   `n`, and `total_pref_score`.
#' @keywords internal
summary_pba <- function(df_result, df_list, n_topics) {
   df_result$pref_scores <- mapply(get_group_pref_score,
                                   group_num = df_result$group,
                                   topic = df_result$topic2,
                                   subtopic = df_result$subtopic,
                                   MoreArgs = list(pref_mat = df_list$p,
                                                   n_topics = n_topics)
         )
   df_result %>%
     group_by(topic2, subtopic, rep) %>%
     summarise(n=n(), total_pref_score = sum(pref_scores), .groups="drop")
}

#' Convert a preference matrix to rank-based scores
#'
#' Transforms raw preference ranks so that higher values indicate stronger
#' preference. A rank of 1 maps to `n_topics * B`, rank 2 to `n_topics * B - 1`,
#' and so on.
#'
#' @param pref_mat Numeric matrix of preference ranks (groups × columns).
#' @param n_topics Integer. Number of base topics.
#' @param B Integer. Number of subtopic subgroups per topic.
#'
#' @returns Numeric matrix of the same dimensions as `pref_mat`.
#' @keywords internal
convert_pref_mat <- function(pref_mat, n_topics, B) {
  t(apply(pref_mat, 1, function(x) n_topics*B - (x-1)))
}

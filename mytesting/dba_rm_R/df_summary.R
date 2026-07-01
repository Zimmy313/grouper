compute_diversity <- function(id, dmat) {
  sum(dmat[id, id])/2
}

summary_dba <- function(df_result, df_list, id_col) {
  # check for topic, rep, id columns

  if(is.null(df_list$s)) {
    df_result %>% group_by(topic, rep) %>%
      summarise(n=n(),
                total_diversity = compute_diversity(.data[[id_col]], df_list$d),
                .groups = "drop")
  } else {
    df_result %>% group_by(topic, rep) %>%
      summarise(n=n(),
                total_skill = sum(df_list$s[.data[[id]]]),
                total_diversity = total_diversity(.data[[id]], df_list$d),
                .groups = "drop")
  }
}

get_group_pref_score <- function(group_num, topic, subtopic, pref_mat, n_topics) {
  col_num <- (subtopic - 1)*n_topics + topic
  pref_mat[group_num, col_num]
}

summary_pba <- function(df_result, df_list, yaml_list) {
   df_result$pref_scores <- mapply(get_group_pref_score,
                                   group_num = df_result$group,
                                   topic = df_result$topic2,
                                   subtopic = df_result$subtopic,
                                   MoreArgs = list(pref_mat = df_list$p,
                                                   n_topics = yaml_list$n_topics)
         )
   df_result %>%
     group_by(topic2, subtopic, rep) %>%
     summarise(n=n(), total_pref_score = sum(pref_scores), .groups="drop")
}

convert_pref_mat <- function(pref_mat, n_topics, B) {
  t(apply(pref_mat, 1, function(x) n_topics*B - (x-1)))
}


# tmp_groups %>% group_by(topic, rep) %>%
#   summarise(n=n(), total_skill = sum(skill),
#             total_diversity = total_diversity(id, df_ex001_list$d),
#             .groups = "drop")

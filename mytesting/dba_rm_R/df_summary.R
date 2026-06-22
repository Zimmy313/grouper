total_diversity <- function(id, dmat) {
  sum(dmat[id, id])/2
}

summary_diversity <- function(df_result, df_list, skill, id) {
  # check for topic, rep, id columns

  if(is.null(skill)) {
    df_result %>% group_by(topic, rep) %>%
      summarise(n=n(),
                total_diversity = total_diversity(.data[[id]], df_list$d),
                .groups = "drop")
  } else {
    df_result %>% group_by(topic, rep) %>%
      summarise(n=n(),
                total_skill = sum(.data[[skill]]),
                total_diversity = total_diversity(.data[[id]], df_list$d),
                .groups = "drop")
  }
}


# tmp_groups %>% group_by(topic, rep) %>%
#   summarise(n=n(), total_skill = sum(skill),
#             total_diversity = total_diversity(id, df_ex001_list$d),
#             .groups = "drop")

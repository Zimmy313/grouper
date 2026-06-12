suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
})

derived_dir <- "data/derived"
fig_dir <- "figures"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

model_manual_colors <- c("Model" = "#0072B2", "Manual" = "#e61b00")

job_palette <- c(
  "TA" = "#0072B2",
  "GR" = "#e61b00",
  "E" = "#56B4E9"
)

dist_long <- readr::read_csv(file.path(derived_dir, "ay2520_distribution_long.csv"), show_col_types = FALSE) |>
  mutate(
    student_order = as.integer(gsub("\\D", "", student_id)),
    student_order_key = as.character(student_order),
    student_label = sprintf("%02d", student_order),
    year = factor(year, levels = sort(unique(year)))
  ) |>
  arrange(year, student_order_key) |>
  mutate(
    student_plot = paste0(year, "_", student_label),
    student_plot = factor(student_plot, levels = unique(student_plot)),
    stack_component = recode(
      component,
      "Current TA" = "Sem2_TA",
      "Current GR" = "Sem2_GR",
      "Current E" = "Sem2_E",
      "Past TA" = "Sem1_TA",
      "Past GR" = "Sem1_GR"
    ),
    stack_component = factor(
      stack_component,
      levels = c("Sem2_TA", "Sem2_GR", "Sem2_E", "Sem1_TA", "Sem1_GR")
    )
  )

dist_palette <- c(
  "Sem2_TA" = job_palette[["TA"]],
  "Sem2_GR" = job_palette[["GR"]],
  "Sem2_E" = job_palette[["E"]],
  "Sem1_TA" = job_palette[["TA"]],
  "Sem1_GR" = job_palette[["GR"]]
)

p_dist <- ggplot(dist_long, aes(x = student_plot, y = units, fill = stack_component)) +
  geom_col(
    width = 0.85,
    color = "white",
    linewidth = 0.2,
    position = position_stack(reverse = TRUE)
  ) +
  geom_hline(yintercept = 4, linetype = "dashed", linewidth = 0.4, color = "#6B6B6B") +
  facet_wrap(~year, scales = "free_x", ncol = 4) +
  scale_x_discrete(labels = function(x) sub("^[0-9]+_", "", x)) +
  scale_fill_manual(
    values = dist_palette,
    breaks = c("Sem2_TA", "Sem2_GR", "Sem2_E"),
    labels = c("TA", "GR", "E"),
    name = "Job",
    drop = FALSE
  ) +
  labs(
    x = "Student",
    y = "Workload Units",
    title = "Year-Long Work Distribution by Student",
    subtitle = "AY2520 baseline (model_0, anonymized)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "right",
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
    panel.grid.major.x = element_blank()
  )

ggsave(
  filename = file.path(fig_dir, "ay2520_distribution.pdf"),
  plot = p_dist,
  width = 8.4,
  height = 4.8,
  units = "in"
)

objective_long <- readr::read_csv(
  file.path(derived_dir, "multi_role_objective_comparison.csv"),
  show_col_types = FALSE
) |>
  pivot_longer(
    cols = -Semester,
    names_to = "Schedule",
    values_to = "objective"
  ) |>
  mutate(
    Schedule = recode(
      Schedule,
      Model_objective = "Model",
      Manual_objective = "Manual"
    ),
    Schedule = factor(Schedule, levels = c("Model", "Manual")),
    objective = abs(objective)
  )

p_objective <- ggplot(
  objective_long,
  aes(x = Semester, y = objective, fill = Schedule)
) +
  geom_hline(yintercept = 0, linewidth = 0.3, color = "#6B6B6B") +
  geom_col(
    position = position_dodge(width = 0.72),
    width = 0.62,
    color = "white",
    linewidth = 0.2
  ) +
  scale_fill_manual(values = model_manual_colors, name = "Schedule") +
  labs(
    x = "Semester",
    y = "Absolute objective value",
    title = "Model and Manual Schedules Under the Same Objective"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.grid.major.x = element_blank()
  )

ggsave(
  filename = file.path(fig_dir, "multi_role_objective_comparison.pdf"),
  plot = p_objective,
  width = 6.6,
  height = 4.0,
  units = "in"
)

objective_terms <- readr::read_csv(
  file.path(derived_dir, "multi_role_objective_terms.csv"),
  show_col_types = FALSE
)
largest_gap_semester <- readr::read_csv(
  file.path(derived_dir, "multi_role_objective_comparison.csv"),
  show_col_types = FALSE
) |>
  mutate(gap = Manual_objective - Model_objective) |>
  arrange(desc(abs(gap))) |>
  slice(1) |>
  pull(Semester)

term_gap <- objective_terms |>
  filter(Semester == largest_gap_semester) |>
  select(Schedule, fairness_term, preference_term, seniority_e_term, y1_slack_term) |>
  pivot_longer(-Schedule, names_to = "term", values_to = "value") |>
  pivot_wider(names_from = Schedule, values_from = value) |>
  mutate(
    manual_minus_model = Manual - Model,
    term = recode(
      term,
      fairness_term = "Fairness",
      preference_term = "Preference",
      seniority_e_term = "Seniority-E",
      y1_slack_term = "Year-1 slack"
    ),
    term = factor(term, levels = c("Preference", "Fairness", "Seniority-E", "Year-1 slack")),
    direction = if_else(manual_minus_model >= 0, "Higher in manual", "Lower in manual"),
    label_hjust = if_else(manual_minus_model >= 0, -0.15, 1.15)
  )

p_terms <- ggplot(term_gap, aes(x = term, y = manual_minus_model, fill = direction)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#6B6B6B", linewidth = 0.35) +
  geom_col(width = 0.62) +
  geom_text(aes(label = round(manual_minus_model, 1), hjust = label_hjust), size = 3) +
  coord_flip(clip = "off") +
  scale_fill_manual(
    values = c("Higher in manual" = model_manual_colors[["Manual"]], "Lower in manual" = model_manual_colors[["Model"]]),
    name = NULL
  ) +
  labs(
    x = NULL,
    y = "Weighted term difference (Manual - Model)",
    title = paste0(largest_gap_semester, " Objective-Term Gap"),
    subtitle = "Positive values increase the manual objective relative to the model"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.margin = margin(5.5, 28, 5.5, 5.5)
  )

ggsave(
  filename = file.path(fig_dir, "multi_role_objective_term_gap.pdf"),
  plot = p_terms,
  width = 6.8,
  height = 3.8,
  units = "in"
)

source("scripts/multirole_helpers.R")

weights <- manuscript_weights()
problem <- build_multirole_problem("ay2520", e_max = 1, weights = weights)
inputs <- problem$inputs
model_input <- problem$model_input

manual <- objective_components(
  inputs$manual_totals$manual_ta,
  inputs$manual_totals$manual_e,
  manual_pref_sum(inputs$manual_ta, inputs$students, inputs$demand, inputs$P),
  model_input$t1,
  model_input$s,
  model_input$year,
  weights
)

print(tibble(
  metric = c(
    "TA spread", "TA preference sum", "Seniority-weighted E",
    "Year-1 TA slack", "Manual objective"
  ),
  value = c(
    manual$ta_spread, manual$ta_pref_sum, manual$seniority_e_sum,
    manual$ta_protected_slack_sum, manual$objective_recalc
  )
))

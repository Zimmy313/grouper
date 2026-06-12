# Figure files for R Journal submission

This folder contains:

- `workflow.png`: static package architecture figure (manually maintained).
- `ay2520_distribution.pdf`: generated workload-distribution figure for the
  AY2520 example.
- `multi_role_objective_comparison.pdf`: generated comparison of model and
  manual absolute objective values across the three semesters.
- `multi_role_objective_term_gap.pdf`: generated AY2420 weighted objective-term
  gap figure for the largest model-manual objective gap.
- `grouper_webapp_home.png`: screenshot of the Shiny frontend home page.
- `grouper_webapp_multirole_results.png`: screenshot of the multi-role
  workload results view.

Generate or refresh these files by running:

```r
source("scripts/01_build_results.R")
source("scripts/02_build_plots.R")
```

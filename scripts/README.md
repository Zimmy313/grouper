# Reproducibility scripts

Run the main multi-role workflow from the article root:

1. `Rscript scripts/01_build_results.R`
2. `Rscript scripts/02_build_plots.R`
3. `Rscript scripts/03_solver_runtime.R`

Optional checks:

- `Rscript scripts/03_manual_objective.R`
- `Rscript scripts/04_hyperparameter_sensitivity.R`

Files:

- `01_build_results.R`: solves AY2420, AY2510, and AY2520 with the manuscript
  policy and writes derived result tables.
- `02_build_plots.R`: rebuilds the multi-role figures from `data/derived/`.
- `03_solver_runtime.R`: benchmarks GLPK and HiGHS on AY2520.
- `03_manual_objective.R`: prints the AY2520 manual objective components.
- `04_hyperparameter_sensitivity.R`: prints one-at-a-time sensitivity summaries.
- `multirole_helpers.R`: shared multi-role data, model, and objective helpers.

Past-semester DBA/PBA scripts:

- `05_dba_past_semester.R`
- `06_pba_past_semester.R`

These scripts assume the working directory is `scripts/` and may require editing
the solver lines depending on whether Gurobi or GLPK is available.

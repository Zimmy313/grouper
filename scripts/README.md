# Reproducibility scripts

Run scripts from `LATEX/rj1/` in this order:

1. `Rscript scripts/01_build_results.R`
2. `Rscript scripts/02_build_plots.R`
3. `Rscript scripts/03_solver_runtime.R`
4. Optional check: `Rscript scripts/03_manual_objective.R`
5. Optional check: `Rscript scripts/04_hyperparameter_sensitivity.R`

What each script does:

- `01_build_results.R`: reads the cleaned anonymized AY2420, AY2510, and AY2520
  inputs in `data/raw/<semester>/`, runs the GLPK multi-role workload
  optimization for all three semesters, and writes the manuscript result tables
  plus AY2520 workload-distribution data to `data/derived/`.
- `02_build_plots.R`: reads the retained derived data and writes
  `figures/ay2520_distribution.pdf` and
  `figures/multi_role_objective_comparison.pdf`, which compares absolute
  objective values, plus the AY2420 objective-term gap figure for the largest
  model-manual objective gap.
- `03_solver_runtime.R`: repeats the AY2520 solve 30 times for each open-source
  solver (`GLPK` and `HiGHS`) and writes `data/derived/ay2520_solver_runtime.csv`.
- `03_manual_objective.R`: reads the AY2520 raw inputs plus manual-allocation
  raw files, recomputes the manual objective under the manuscript parameters,
  and prints the objective components without writing results.
- `04_hyperparameter_sensitivity.R`: varies `alpha`, `beta`, `phi`, and `rho`
  one at a time around the AY2520 manuscript setting and prints sensitivity
  summaries without writing results.
- `multirole_helpers.R`: shared helper functions used by the result and
  sensitivity scripts.

# Consolidated Shiny frontend

This directory contains the complete source needed to run the consolidated
`grouper` web application described in the article. It is copied from the
package source under `inst/shiny/` and organized here as:

- `app.R`: unified user interface and server logic for diversity-based,
  preference-based, and multi-role workload allocation.
- `R/dba_utils.R`: validation helpers used by the diversity-based module.
- `R/multirole_utils.R`: input validation, preprocessing, solving, diagnostics,
  and plotting helpers used by the multi-role module.
- `assets/current_semester_template.xlsx`: downloadable input template used by
  the multi-role module.

The preference-based module is implemented directly in `app.R` and does not
source a separate helper file. Standalone legacy applications and their example
or test files are not required by the consolidated application and are
therefore not duplicated here.

Run the application from `LATEX/rj1/` with:

```r
shiny::runApp("frontend")
```

The application requires `grouper`, `shiny`, `bslib`, `DT`, `magrittr`,
`dplyr`, `ggplot2`, `readxl`, `stringr`, `ompr`, `ompr.roi`, and `writexl`.
At least one supported ROI solver plugin must also be installed. The interface
supports `ROI.plugin.glpk`, `ROI.plugin.highs`, and `ROI.plugin.gurobi`, subject
to the solver software and licensing available on the host system.

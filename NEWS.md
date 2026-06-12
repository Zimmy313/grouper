# grouper 0.6.2
* Unified all three shiny apps into a single app with 3 tabs.
* Added wrapper function for solving and post-processing in one step.
* Added configurable four-value seniority scoring for the PhD model's
  E-allocation objective while retaining year-based cohort constraints.
* Clarified that PhD preference matrices may use user-defined numeric scores.
* Added `protected_year` to choose which Year 1-4 cohort receives the PhD
  model's soft TA-load protection.

# grouper 0.6.1
* Added wrapper functions for extracting information.
* Added unit tests for main functions under R/
* Added shiny app for PhD workload allocation model.

# grouper 0.6.0
* Added a PhD workload allocation model, with associated extraction and post-processing functions.
* Modularized model preparation and added a wrapper for easier use.
* Updated `data/` testing datasets for the PhD model.
* Added a PhD-model vignette and expanded sanity checks to include a sample workflow.
* Deployed the pkgdown website.

# grouper 0.5.1
* Added functionality to choose solver
* Added status message to shiny app

# grouper 0.5.0

* Added shiny apps (one for dba and one for pba) to inst/shiny/ folder

# grouper 0.4.0

* Added functionality to use custom dissimilarity matrix in DBA
* Vignette examples added for above, and to demonstrate use of arrays in YAML
  file.

# grouper 0.3.0

* Removed gurobi from Suggests
* Datasets in mytesting updated
* Quarto documents in mytesting/ updated

# grouper 0.2.0

* Name change from groupr to grouper.

# grouper 0.1.0

* Initial version of package.

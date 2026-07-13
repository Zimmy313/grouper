# Supplementary files for the grouper R Journal article

This folder contains the supplementary data and scripts for reproducing the analyses reported in the article.

To use these files, extract the contents of `supplementary.zip` into the article root, meaning the same folder that contains `grouper.Rmd`. If `data/` or `scripts/` already exists, merge the extracted folders with the existing ones. The resulting layout should include `scripts/...` and `data/...` directly under the article root. Do not replace the existing `data/` folder, because it contains files used by the article render, and do not extract the zip into the `scripts/` or `data/` folder.

From the article root, run the main reproducibility scripts with:

```r
source("scripts/01_build_results.R")
source("scripts/02_build_plots.R")
source("scripts/03_solver_runtime.R")
```

See `data/README.md` and `scripts/README.md` for file-level details.

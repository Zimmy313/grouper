# Supplementary data files

These files are supplementary data for the `grouper` R Journal article. To use them, extract `supplementary.zip` into the article root, meaning the same folder that contains `grouper.Rmd`. If `data/` already exists, merge the extracted folder with the existing one. This keeps paths such as `data/raw/...`, `data/derived/...`, and `scripts/...` valid.

The raw files intentionally contain no names, emails, intake dates, original course codes, or workbook metadata.

After `supplementary.zip` is extracted into the article root, the combined `raw/` folder contains cleaned, anonymized inputs for AY2420, AY2510, and AY2520. Each semester folder follows the same schema:

- `students.csv`: anonymized student IDs and workload fields (`year`, `past_ta`, `past_gr`).
- `demand.csv`: anonymized course-level demand by role (`TA`, `GR`, `E`) with synthetic course codes (`C01`, `C02`, ...).
- `preferences_long.csv`: long-form preference scores by `student_id`-`course_code`.
- `manual_totals.csv`: anonymized manual allocation totals by student.
- `manual_ta_by_course.csv`: anonymized manual TA units by student-course pair.

The `derived/` folder contains outputs regenerated from the raw files by the scripts:

- `multi_role_objective_comparison.csv`: model and manual objective values under the same policy weights.
- `multi_role_objective_terms.csv`: objective-term breakdowns for model and manual schedules.
- `ay2520_distribution_long.csv`: student-level workload data used for the workload-distribution figure.
- `data005-*` to `data008-*` and `dba_ex3_composition.rds`: derived objects used by the past-semester DBA/PBA scripts.

The main article folder keeps the small subset of data needed to render `grouper.Rmd`; this supplementary folder contains the additional data needed to complete the combined `data/` layout and rerun the reproduction scripts.

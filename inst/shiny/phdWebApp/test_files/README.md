# Multi-role Workload App Test Files

This folder now contains one test input pair that is feasible under the app default settings:
- `C = 4`
- `e_max = 1`
- `ta_protected_max = 1`, `gr_protected_max = 1`
- `alpha_ta = 2`, `beta_ta = 1`, `phi = 1`, `rho_ta = 10`
- `alpha_gr`, `beta_gr`, and `rho_gr` disabled by default

## Default-Feasible Pair

- Current semester file: `current_semester_default.xlsx`
- Previous output file: `past_output_default.xlsx`

## Format Notes

- `current_semester_default.xlsx` has exactly two sheets: `students`, `demand`.
- `students` columns are exactly:
  `student_id, Name, year, first, second, third`
- `demand` columns are exactly:
  `course_code, TA, GR`
- `past_output_default.xlsx` includes `Name` and course-role columns ending with `-t` and `-g` (plus `-e` columns, optional for parsing).
- The `first`, `second`, and `third` columns are treated as general course preferences and are supplied to both TA and GR preference matrices.
- In single-semester mode, the previous output file is not required; extraction uses synthetic `past_ta = 0` and `past_gr = C`.

# PhD Model Data Format

Use one workbook per semester?

- `phd_model_input_AY2510.xlsx`

## Sheet 1: `students`

Keep one row per student. Include preferences in the same sheet.

Required columns:

- `student_id` (stable unique ID, never reused)
- `name`
- `email`
- `intake_date` (`YYYY-MM-DD`)
- `pref_1_course_code`
- `pref_2_course_code`
- `pref_3_course_code`

Notes:
- If a student has no preference, leave `pref_1_course_code` blank.
- Course codes in preference columns must match the exact codes used in `demand`.

## Sheet 2: `demand`

Keep one row per course.

Required columns:

- `course_code`
- `ta_units`
- `gr_units` in terms of unit instead of hours

## Sheet 3: `past_workload`

Current form is ok.

## Return data format

Running the `extract_phd` will return a list of results:

 
# Extract model inputs (wrapper)

Wrapper around
[`extract_student_info()`](https://Zimmy313.github.io/grouper/reference/extract_student_info.md),
[`extract_phd_info()`](https://Zimmy313.github.io/grouper/reference/extract_phd_info.md),
and
[`extract_multirole_info()`](https://Zimmy313.github.io/grouper/reference/extract_multirole_info.md).

## Usage

``` r
extract_info(
  assignment = c("diversity", "preference", "phd", "multirole"),
  ...
)
```

## Arguments

- assignment:

  Character string indicating model type. Must be one of `"diversity"`,
  `"preference"`, `"phd"`, or `"multirole"`.

- ...:

  Additional arguments for the underlying extraction functions. See
  Details.

## Value

A model input list from the corresponding extraction function.

## Details

Explicit argument guide by assignment:

- For `assignment = "diversity"`, `extract_info()` forwards `...` to
  [`extract_student_info()`](https://Zimmy313.github.io/grouper/reference/extract_student_info.md).

  Required arguments:

  - `dframe`

  - `self_formed_groups`

  - either:

    - `d_mat`, or

    - `demographic_cols`, so Gower dissimilarity is computed internally

  Optional arguments:

  - `skills`, which can be supplied or set to `NULL`

- For `assignment = "preference"`, `extract_info()` forwards `...` to
  [`extract_student_info()`](https://Zimmy313.github.io/grouper/reference/extract_student_info.md).

  Required arguments:

  - `dframe`

  - `self_formed_groups`

  - `pref_mat`

- For `assignment = "phd"`, `extract_info()` forwards `...` to
  [`extract_phd_info()`](https://Zimmy313.github.io/grouper/reference/extract_phd_info.md).

  Required arguments:

  - `student_df`

  - `p_mat`

  - `d_mat`

  Optional arguments:

  - `e_mode`, which uses the default from
    [`extract_phd_info()`](https://Zimmy313.github.io/grouper/reference/extract_phd_info.md)

  - `C`, which uses the default from
    [`extract_phd_info()`](https://Zimmy313.github.io/grouper/reference/extract_phd_info.md)

  - `s`, which uses the default from
    [`extract_phd_info()`](https://Zimmy313.github.io/grouper/reference/extract_phd_info.md)

- For `assignment = "multirole"`, `extract_info()` forwards `...` to
  [`extract_multirole_info()`](https://Zimmy313.github.io/grouper/reference/extract_multirole_info.md).

  Required arguments:

  - `student_df`

  - `d_mat`

  Optional arguments:

  - `p_ta_mat` and `p_gr_mat`

  - `e_mode`, `C`, `s`, and `single_semester`

This wrapper does not parse YAML files. YAML-based parameter extraction
remains available via
[`extract_params_yaml()`](https://Zimmy313.github.io/grouper/reference/extract_params_yaml.md).

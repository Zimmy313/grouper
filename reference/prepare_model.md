# Initialise optimisation model (wrapper)

Initialise optimisation model (wrapper)

## Usage

``` r
prepare_model(
  df_list,
  yaml_list = NULL,
  assignment = c("diversity", "preference", "phd"),
  w1 = 0.5,
  w2 = 0.5,
  ...
)
```

## Arguments

- df_list:

  Model input list.

- yaml_list:

  Parameter list from
  [`extract_params_yaml()`](https://Zimmy313.github.io/grouper/reference/extract_params_yaml.md).
  Required for `assignment = "diversity"` and
  `assignment = "preference"`. Ignored for `assignment = "phd"`.

- assignment:

  Character string indicating model type. Must be one of `"diversity"`,
  `"preference"`, or `"phd"`.

- w1, w2:

  Numeric values between 0 and 1. Should sum to 1. Used only for
  `assignment = "diversity"`.

- ...:

  Additional arguments passed to
  [`prepare_phd_model()`](https://Zimmy313.github.io/grouper/reference/prepare_phd_model.md)
  when `assignment = "phd"`.

## Value

An ompr model.

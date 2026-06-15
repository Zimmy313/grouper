# PhD Preference Matrix Example 001

An example preference matrix for the PhD and multi-role workload models.

## Usage

``` r
phd_prefmat_ex001
```

## Format

### `phd_prefmat_ex001`

A matrix with 4 rows and 4 columns.

Rows correspond to students in `phd_students_ex001`, and columns
correspond to rows of `phd_demand_ex001`.

Preference scores are encoded as 3 (first choice), 2 (second choice),
and 1 (third choice). Unranked courses are encoded as -99. These are
example scores only;
[`extract_phd_info()`](https://Zimmy313.github.io/grouper/reference/extract_phd_info.md)
and
[`extract_multirole_info()`](https://Zimmy313.github.io/grouper/reference/extract_multirole_info.md)
accept numeric preference scores supplied by the user.

## Source

This dataset was constructed by hand.

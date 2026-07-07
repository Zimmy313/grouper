# Compute total pairwise diversity for a set of students

Compute total pairwise diversity for a set of students

## Usage

``` r
compute_diversity(id, dmat)
```

## Arguments

- id:

  Integer vector of student indices into \`dmat\`.

- dmat:

  Numeric distance matrix (students × students).

## Value

Scalar: sum of upper-triangle distances among \`id\`.

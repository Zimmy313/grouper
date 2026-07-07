# Convert a preference matrix to rank-based scores

Transforms raw preference ranks so that higher values indicate stronger
preference. A rank of 1 maps to \`n_topics \* B\`, rank 2 to \`n_topics
\* B - 1\`, and so on.

## Usage

``` r
convert_pref_mat(pref_mat, n_topics, B)
```

## Arguments

- pref_mat:

  Numeric matrix of preference ranks (groups × columns).

- n_topics:

  Integer. Number of base topics.

- B:

  Integer. Number of subtopic subgroups per topic.

## Value

Numeric matrix of the same dimensions as \`pref_mat\`.

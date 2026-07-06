# Look up a group's preference score for a topic-subtopic combination

Look up a group's preference score for a topic-subtopic combination

## Usage

``` r
get_group_pref_score(group_num, topic, subtopic, pref_mat, n_topics)
```

## Arguments

- group_num:

  Integer. Group index (row of `pref_mat`).

- topic:

  Integer. Base topic index.

- subtopic:

  Integer. Subtopic (subgroup) index.

- pref_mat:

  Numeric preference matrix (groups × topic-subtopic columns).

- n_topics:

  Integer. Number of base topics.

## Value

Scalar preference score.

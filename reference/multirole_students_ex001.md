# Multi-role Individual Data Example 001

An example individual table for the multi-role workload allocation
model.

## Usage

``` r
multirole_students_ex001
```

## Format

### `multirole_students_ex001`

A data frame with 4 rows and 5 columns.

- student_id: unique individual id.

- year: cohort or year, encoded from 1 to 4.

- past_ta: previous-semester TA workload units.

- past_gr: previous-semester GR workload units.

- Name: individual name.

In this toy dataset, `past_ta + past_gr = 4` for every individual.

## Source

This dataset was constructed by hand.

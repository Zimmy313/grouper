#' DBA Group Composition Data Example 001
#'
#' An example dataset to use with the diversity-based assignment model.
#'
#' @format ## `dba_gc_ex001`
#' A data frame with 4 rows and 4 columns.
#'
#' * id: the student id of each students, simply the integers 1 to 4.
#' * major: the primary major of each student.
#' * skill: the skill level of each student.
#' * groups: the self-formed groups submitted by each student. In this case,
#'           student is in his/her own group.
#'
#' @source This dataset was constructed by hand.
"dba_gc_ex001"

#' PBA Group Composition Data Example 002
#'
#' An example dataset to use with the preference-based assignment model.
#'
#' @format ## `pba_gc_ex002`
#' A data frame with 8 rows and 2 columns.
#'
#' * id: the student id of each students, simply the integers 1 to 8.
#' * grouping: the self-formed groups submitted by each student. In this case,
#'             each self-formed group is of size 2.
#'
#' @source This dataset was constructed by hand.
"pba_gc_ex002"

#' PBA Group Preference Data Example 002
#'
#' An example dataset to use with the preference-based assignment model.
#'
#' @format ## `pba_prefmat_ex002`
#' A matrix with 4 rows and 4 columns
#'
#' Each row represents the preferences of each self-formed group in the
#' dataset `pba_gc_ex002`.
#'
#' @source This dataset was constructed by hand.
"pba_prefmat_ex002"

#' DBA Group Composition Data Example 003
#'
#' An example dataset to use with the diversity-based assignment model. It is
#' used to demonstrate the use of a custom dissimilarity matrix.
#'
#' @format ## `dba_gc_ex003`
#' A matrix with 4 rows and 4 columns
#'
#' * id: the student id of each students, simply the integers 1 to 4.
#' * self_groups: The self-formed groups
#' * year, major: demographics used in computing dissimilarities
#'
#' @source This dataset was constructed by hand.
"dba_gc_ex003"

#' DBA Group Composition Data Example 004
#'
#' An example dataset to use with the diversity-based assignment model. It is
#' used to demonstrate the use of a vectors to indicate individual group size
#' constraints for specific topics.
#'
#' @format ## `dba_gc_ex004`
#' A matrix with 5 rows and 4 columns
#'
#' * id: the student id of each students, simply the integers 1 to 4.
#' * self_groups: The self-formed groups
#' * python: Python skill level - 1 is lowest, 3 is highest.
#'
#' @source This dataset was constructed by hand.
"dba_gc_ex004"

#' Multi-role Individual Data Example 001
#'
#' An example individual table for the multi-role workload allocation model.
#'
#' @format ## `multirole_students_ex001`
#' A data frame with 4 rows and 5 columns.
#'
#' * student_id: unique individual id.
#' * year: cohort or year, encoded from 1 to 4.
#' * past_ta: previous-semester TA workload units.
#' * past_gr: previous-semester GR workload units.
#' * Name: individual name.
#'
#' In this toy dataset, `past_ta + past_gr = 4` for every individual.
#'
#' @source This dataset was constructed by hand.
"multirole_students_ex001"

#' Multi-role Preference Matrix Example 001
#'
#' An example preference matrix for the multi-role workload allocation model.
#' It can be used for either TA or GR preferences.
#'
#' @format ## `multirole_prefmat_ex001`
#' A matrix with 4 rows and 4 columns.
#'
#' Rows correspond to individuals in `multirole_students_ex001`, and columns
#' correspond to rows of `multirole_demand_ex001`.
#'
#' Preference scores are encoded as 3 (first choice), 2 (second choice), and 1
#' (third choice). Unranked courses are encoded as -99.
#'
#' @source This dataset was constructed by hand.
"multirole_prefmat_ex001"

#' Multi-role Demand Matrix Example 001
#'
#' An example demand matrix for the multi-role workload allocation model.
#'
#' @format ## `multirole_demand_ex001`
#' A matrix with 4 rows and 2 columns.
#'
#' Columns are in the order `TA`, `GR`. Row names store the course codes.
#'
#' @source This dataset was constructed by hand.
"multirole_demand_ex001"

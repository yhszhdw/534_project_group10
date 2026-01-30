#' @importFrom magrittr %>%
#' @importFrom rlang .data :=
#' @importFrom ggplot2 after_stat
#' @importFrom stats na.omit
NULL

# Register common dplyr/ggplot variables to silence R CMD check NOTES
utils::globalVariables(c(
  "series", "item_series", "target_currency", "base_currency",
  "rate_type", "country", "id", "label", "description", "value",
  "n", "n_missing", "ret", "count", "scaled"
))

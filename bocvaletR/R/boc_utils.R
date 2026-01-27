# First non-missing value (used for index normalization)
first_non_na <- function(x) {
  idx <- which(!is.na(x))
  if (length(idx) == 0) return(NA_real_)
  x[idx[1]]
}

# Simple “last observation carried forward”
fill_locf <- function(x) {
  if (!length(x)) return(x)
  for (i in seq_along(x)) if (is.na(x[i]) && i > 1) x[i] <- x[i - 1]
  x
}

# “next observation carried backward”
fill_nocb <- function(x) {
  if (!length(x)) return(x)
  for (i in rev(seq_along(x))) if (is.na(x[i]) && i < length(x)) x[i] <- x[i + 1]
  x
}

# Linear interpolation for gaps (needs at least two non-missing points)
fill_linear <- function(x) {
  if (sum(!is.na(x)) < 2) return(x)
  idx <- seq_along(x); ok <- !is.na(x)
  x[!ok] <- stats::approx(idx[ok], x[ok], xout = idx[!ok], rule = 2)$y
  x
}

# Rolling mean using a simple moving window (right-aligned)
roll_mean <- function(x, k) {
  if (k <= 1) return(x)
  as.numeric(stats::filter(x, rep(1 / k, k), sides = 1))
}

#' Time Series Utility Functions
#'
#' Normalize a numeric series (z-score, min-max, or index-to-base) within each
#' group (e.g., per series).
#'
#' @param data A data.frame/tibble containing the time series.
#' @param value_col Name of the numeric value column in `data` (string).
#' @param method Normalization method. One of `"zscore"`, `"minmax"`, or `"index"`.
#' @param index_base Base value used when `method = "index"` (default 100).
#' @param group_col Name of the grouping column (string). Default `"series"`.
#' @param new_col Name of the output column to create (string).
#'
#' @return A tibble/data.frame with a new column `new_col` containing normalized values.
#' @export
boc_normalize <- function(data,
                          value_col = "value",
                          method = c("zscore", "minmax", "index"),
                          index_base = 100,
                          group_col = "series",
                          new_col = "normalized") {

  method <- match.arg(method)

  data %>%
    dplyr::group_by(.data[[group_col]]) %>%
    dplyr::mutate(
      !!new_col := {
        v <- .data[[value_col]]
        if (method == "zscore") {
          (v - mean(v, na.rm = TRUE)) / stats::sd(v, na.rm = TRUE)
        } else if (method == "minmax") {
          rng <- range(v, na.rm = TRUE)
          if (diff(rng) == 0) NA_real_ else (v - rng[1]) / diff(rng)
        } else { # index
          base <- first_non_na(v)
          if (is.na(base) || base == 0) NA_real_ else (v / base) * index_base
        }
      }
    ) %>%
    dplyr::ungroup()
}

#' Fill missing values
#'
#' Fill missing values within each group using one of: LOCF (last observation
#' carried forward), NOCB (next observation carried backward), or linear
#' interpolation.
#'
#' @param data A data.frame/tibble containing the time series.
#' @param value_col Name of the numeric value column in `data` (string).
#' @param method Filling method. One of `"locf"`, `"nocb"`, or `"linear"`.
#' @param order_col Name of the ordering column (string), typically `"date"`.
#'   Data are arranged by this column before filling.
#' @param group_col Name of the grouping column (string). Default `"series"`.
#' @param new_col Name of the output column to create (string).
#'
#' @return A tibble/data.frame with a new column `new_col` containing filled values.
#' @export
boc_fill_missing <- function(data,
                             value_col = "value",
                             method = c("locf", "nocb", "linear"),
                             order_col = "date",
                             group_col = "series",
                             new_col = "filled") {

  method <- match.arg(method)
  fill_fun <- switch(method,
                     locf = fill_locf,
                     nocb = fill_nocb,
                     linear = fill_linear)

  data %>%
    dplyr::arrange(.data[[order_col]]) %>%
    dplyr::group_by(.data[[group_col]]) %>%
    dplyr::mutate(!!new_col := fill_fun(.data[[value_col]])) %>%
    dplyr::ungroup()
}

#' Summary statistics by series
#'
#' Compute common summary statistics for each group/series, including counts,
#' missingness, date range, and distributional statistics.
#'
#' @param data A data.frame/tibble containing the time series.
#' @param value_col Name of the numeric value column in `data` (string).
#' @param order_col Name of the ordering/date column in `data` (string), used to
#'   compute start/end range (default `"date"`).
#' @param group_col Name of the grouping column (string). Default `"series"`.
#'
#' @return A tibble with one row per group containing summary statistics.
#' @export
boc_summary <- function(data,
                        value_col = "value",
                        order_col = "date",
                        group_col = "series") {

  data %>%
    dplyr::group_by(.data[[group_col]]) %>%
    dplyr::summarise(
      n = dplyr::n(),
      n_missing = sum(is.na(.data[[value_col]])),
      n_non_missing = n - n_missing,
      start = suppressWarnings(min(.data[[order_col]], na.rm = TRUE)),
      end   = suppressWarnings(max(.data[[order_col]], na.rm = TRUE)),
      min = suppressWarnings(min(.data[[value_col]], na.rm = TRUE)),
      max = suppressWarnings(max(.data[[value_col]], na.rm = TRUE)),
      mean = mean(.data[[value_col]], na.rm = TRUE),
      median = stats::median(.data[[value_col]], na.rm = TRUE),
      sd = stats::sd(.data[[value_col]], na.rm = TRUE),
      .groups = "drop"
    )
}

#' Percent change over k periods
#'
#' Compute percent change over `periods` within each group, using either
#' arithmetic returns or log returns.
#'
#' @param data A data.frame/tibble containing the time series.
#' @param value_col Name of the numeric value column in `data` (string).
#' @param periods Integer number of periods to lag when computing change (default 1).
#' @param type Return type. One of `"arithmetic"` or `"log"`.
#' @param order_col Name of the ordering/date column (string). Data are arranged
#'   by this column before computing changes (default `"date"`).
#' @param group_col Name of the grouping column (string). Default `"series"`.
#' @param new_col Name of the output column to create (string).
#'
#' @return A tibble/data.frame with a new column `new_col` containing changes.
#' @export
boc_percent_change <- function(data,
                               value_col = "value",
                               periods = 1,
                               type = c("arithmetic", "log"),
                               order_col = "date",
                               group_col = "series",
                               new_col = "pct_change") {

  type <- match.arg(type)

  data %>%
    dplyr::arrange(.data[[order_col]]) %>%
    dplyr::group_by(.data[[group_col]]) %>%
    dplyr::mutate(
      !!new_col := if (type == "log") {
        log(.data[[value_col]]) - log(dplyr::lag(.data[[value_col]], periods))
      } else {
        (.data[[value_col]] - dplyr::lag(.data[[value_col]], periods)) /
          dplyr::lag(.data[[value_col]], periods)
      }
    ) %>%
    dplyr::ungroup()
}

#' Rolling mean (right-aligned)
#'
#' Compute a simple moving average (right-aligned) within each group using a
#' window of size `window`.
#'
#' @param data A data.frame/tibble containing the time series.
#' @param value_col Name of the numeric value column in `data` (string).
#' @param window Integer window size for the rolling mean (>= 1). Default 5.
#' @param order_col Name of the ordering/date column (string). Data are arranged
#'   by this column before computing the rolling mean (default `"date"`).
#' @param group_col Name of the grouping column (string). Default `"series"`.
#' @param new_col Name of the output column to create (string).
#'
#' @return A tibble/data.frame with a new column `new_col` containing rolling means.
#' @export
boc_rolling_mean <- function(data,
                             value_col = "value",
                             window = 5,
                             order_col = "date",
                             group_col = "series",
                             new_col = "roll_mean") {

  stopifnot(window >= 1)

  data %>%
    dplyr::arrange(.data[[order_col]]) %>%
    dplyr::group_by(.data[[group_col]]) %>%
    dplyr::mutate(!!new_col := roll_mean(.data[[value_col]], window)) %>%
    dplyr::ungroup()
}

#' Autocorrelation up to a chosen lag (per series)
#'
#' Compute autocorrelation values up to `lag_max` within each group/series.
#'
#' @param data A data.frame/tibble containing the time series.
#' @param value_col Name of the numeric value column to compute autocorrelation on (string).
#' @param lag_max Maximum lag to compute (integer).
#' @param group_col Name of the grouping column (string). Default `"series"`.
#'
#' @return A tibble with columns `lag` and `acf` for each group/series.
#' @export
boc_autocorr <- function(data,
                         value_col = "value",
                         lag_max = 10,
                         group_col = "series") {

  data %>%
    dplyr::group_by(.data[[group_col]]) %>%
    dplyr::summarise(
      tibble::tibble(
        lag = seq_len(lag_max),
        acf = stats::acf(.data[[value_col]],
                         lag.max = lag_max,
                         plot = FALSE,
                         na.action = na.omit)$acf[-1]
      ),
      .groups = "drop"
    )
}

#' Pairwise correlation matrix across series
#'
#' Compute a correlation matrix between multiple series after reshaping the data
#' wide by `date`.
#'
#' @param data A data frame containing at least `date`, `series`, and a numeric
#'   value column (default `"value"`).
#' @param value_col Name of the numeric value column in `data` to use for the
#'   correlation calculation (string).
#'
#' @return A numeric correlation matrix with one row/column per series.
#' @export
boc_correlation <- function(data, value_col = "value") {
  wide <- stats::reshape(
    data = dplyr::select(data, date, series, val = .data[[value_col]]),
    idvar = "date", timevar = "series", direction = "wide"
  )
  if (ncol(wide) < 3) {
    rlang::abort("Need at least two series to compute a correlation matrix.")
  }
  mat <- as.matrix(wide[, -1, drop = FALSE])
  colnames(mat) <- sub("^val\\.", "", colnames(mat))
  stats::cor(mat, use = "pairwise.complete.obs")
}

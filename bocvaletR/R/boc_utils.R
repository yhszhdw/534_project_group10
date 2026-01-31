# First non-missing value (used for index normalization)
first_non_na <- function(x) {
  idx <- which(!is.na(x))
  if (length(idx) == 0) return(NA_real_)
  x[idx[1]]
}

# Simple "last observation carried forward"
fill_locf <- function(x) {
  if (!length(x)) return(x)
  for (i in seq_along(x)) if (is.na(x[i]) && i > 1) x[i] <- x[i - 1]
  x
}

# "next observation carried backward"
fill_nocb <- function(x) {
  if (!length(x)) return(x)
  for (i in rev(seq_along(x))) if (is.na(x[i]) && i < length(x)) x[i] <- x[i + 1]
  x
}

# Basic validators used by exported helpers
validate_data <- function(data, required_cols = NULL) {
  if (!is.data.frame(data)) {
    rlang::abort("`data` must be a data.frame or tibble.")
  }
  if (!is.null(required_cols)) {
    missing <- setdiff(required_cols, names(data))
    if (length(missing)) {
      rlang::abort(paste0("Missing required column(s): ", paste(missing, collapse = ", ")))
    }
  }
}

validate_numeric_column <- function(data, col) {
  if (!is.numeric(data[[col]])) {
    rlang::abort(paste0("`", col, "` must be numeric."))
  }
}

validate_scalar_positive_integer <- function(x, name) {
  if (length(x) != 1 || is.na(x) || x < 1 || x != as.integer(x)) {
    rlang::abort(paste0("`", name, "` must be a single positive integer."))
  }
}

validate_scalar_numeric <- function(x, name) {
  if (length(x) != 1 || !is.numeric(x) || !is.finite(x)) {
    rlang::abort(paste0("`", name, "` must be a single finite numeric value."))
  }
}

# Wrapper to add consistent, informative error context around operations
safe_exec <- function(expr, context = "operation") {
  tryCatch(
    expr,
    error = function(e) {
      rlang::abort(paste0(context, ": ", conditionMessage(e)), parent = e)
    }
  )
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

#' Align FX/IR timestamps to a common "close" date
#'
#' Exchange rate and interest-rate markets trade across time zones. To avoid
#' misaligned daily changes (e.g., NY close vs. London close), align each
#' timestamp to a synthetic "close" date based on a cut-off time in a reference
#' time zone (default 17:00 America/New_York, the common FX convention).
#'
#' @param data A data.frame/tibble containing the time series.
#' @param datetime_col Name of the POSIXct timestamp column (string).
#' @param input_tz Time zone used to interpret `datetime_col` if it is stored as
#'   character (default "UTC").
#' @param cutoff_hour Integer hour (0-23) of the daily close in `cutoff_tz`.
#' @param cutoff_min Integer minute (0-59) of the daily close.
#' @param cutoff_tz Olson time zone string for the close (default "America/New_York").
#' @param new_col Name of the output date column to create (string). Default "fx_date".
#'
#' @return A tibble/data.frame with an added date column `new_col` that buckets
#'   each observation to the chosen close date.
#' @export
boc_align_fx_close <- function(data,
                               datetime_col = "timestamp",
                               input_tz = "UTC",
                               cutoff_hour = 17,
                               cutoff_min = 0,
                               cutoff_tz = "America/New_York",
                               new_col = "fx_date") {

  validate_data(data, datetime_col)

  if (length(cutoff_hour) != 1 || cutoff_hour < 0 || cutoff_hour > 23) {
    rlang::abort("`cutoff_hour` must be a single integer between 0 and 23.")
  }
  if (length(cutoff_min) != 1 || cutoff_min < 0 || cutoff_min > 59) {
    rlang::abort("`cutoff_min` must be a single integer between 0 and 59.")
  }

  dt_raw <- data[[datetime_col]]
  # Ensure POSIXct; if character, try to parse with input_tz
  if (!inherits(dt_raw, "POSIXct")) {
    dt_raw <- as.POSIXct(dt_raw, tz = input_tz)
  }
  if (!inherits(dt_raw, "POSIXct")) {
    rlang::abort(paste0("`", datetime_col, "` must be POSIXct or coercible to POSIXct."))
  }

  safe_exec({
    dt_local <- lubridate::with_tz(dt_raw, tzone = cutoff_tz)
    cutoff_base <- lubridate::floor_date(dt_local, unit = "day")
    cutoff_dt <- cutoff_base + lubridate::hours(cutoff_hour) + lubridate::minutes(cutoff_min)
    aligned_date <- dplyr::if_else(dt_local < cutoff_dt,
                                   as.Date(cutoff_dt - lubridate::days(1)),
                                   as.Date(cutoff_dt))
    data[[new_col]] <- aligned_date
    data
  }, "boc_align_fx_close failed")
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
  validate_data(data, c(value_col, group_col))
  validate_numeric_column(data, value_col)
  validate_scalar_numeric(index_base, "index_base")

  safe_exec({
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
  }, "boc_normalize failed")
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
  validate_data(data, c(value_col, order_col, group_col))
  validate_numeric_column(data, value_col)

  safe_exec({
    data %>%
      dplyr::arrange(.data[[order_col]]) %>%
      dplyr::group_by(.data[[group_col]]) %>%
      dplyr::mutate(!!new_col := fill_fun(.data[[value_col]])) %>%
      dplyr::ungroup()
  }, "boc_fill_missing failed")
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

  validate_data(data, c(value_col, order_col, group_col))
  validate_numeric_column(data, value_col)

  safe_exec({
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
  }, "boc_summary failed")
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
  validate_data(data, c(value_col, order_col, group_col))
  validate_numeric_column(data, value_col)
  validate_scalar_positive_integer(periods, "periods")

  safe_exec({
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
  }, "boc_percent_change failed")
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

  validate_data(data, c(value_col, order_col, group_col))
  validate_numeric_column(data, value_col)
  validate_scalar_positive_integer(window, "window")
  stopifnot(window >= 1)

  safe_exec({
    data %>%
      dplyr::arrange(.data[[order_col]]) %>%
      dplyr::group_by(.data[[group_col]]) %>%
      dplyr::mutate(!!new_col := roll_mean(.data[[value_col]], window)) %>%
      dplyr::ungroup()
  }, "boc_rolling_mean failed")
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

  validate_data(data, c(value_col, group_col))
  validate_numeric_column(data, value_col)
  validate_scalar_positive_integer(lag_max, "lag_max")

  safe_exec({
    data %>%
      dplyr::group_by(.data[[group_col]]) %>%
      dplyr::group_modify(~ {
        acf_vals <- stats::acf(.x[[value_col]],
                               lag.max = lag_max,
                               plot = FALSE,
                               na.action = stats::na.omit)$acf[-1]
        tibble::tibble(
          lag = seq_len(lag_max),
          acf = acf_vals
        )
      }) %>%
      dplyr::ungroup()
  }, "boc_autocorr failed")
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
#' @importFrom tidyr pivot_wider
#' @export
boc_correlation <- function(data, value_col = "value") {

  validate_data(data, c("date", "series", value_col))
  validate_numeric_column(data, value_col)

  # clean series labels to avoid invisible whitespace issues
  data <- data %>%
    dplyr::mutate(series = trimws(as.character(series)))

  if (dplyr::n_distinct(data$series) < 2) {
    rlang::abort("Need at least two distinct series to compute a correlation matrix.")
  }

  safe_exec({
    wide <- data %>%
      dplyr::select(date, series, value = dplyr::all_of(value_col)) %>%
      tidyr::pivot_wider(names_from = series, values_from = value)

    if (ncol(wide) < 3) {
      rlang::abort("Need at least two series to compute a correlation matrix.")
    }

    mat <- as.matrix(wide[, -1, drop = FALSE])
    stats::cor(mat, use = "pairwise.complete.obs")
  }, "boc_correlation failed")
}
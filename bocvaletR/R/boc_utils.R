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

#' @title Time Series Utility Functions
#' @description A collection of utility functions for time series data manipulation
#' Normalize a series (z-score, min-max, or index-to-base)
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

#' Fill missing values (LOCF, NOCB, or linear interpolation)
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

#' Summary stats by series
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

#' Percent change over k periods (arithmetic or log)
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
#' @export
boc_correlation <- function(data, value_col = "value") {
  # reshape wide without adding new dependencies
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

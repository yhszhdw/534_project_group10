# Internal helpers: NA handling + simple rolling mean
test_that("helpers handle missing values correctly", {

  expect_equal(bocvaletR:::first_non_na(c(NA, 2, 3)), 2)
  expect_true(is.na(bocvaletR:::first_non_na(c(NA_real_, NA_real_))))

  expect_equal(
    bocvaletR:::fill_locf(c(NA, 1, NA, 2)),
    c(NA, 1, 1, 2)
  )
  expect_equal(
    bocvaletR:::fill_nocb(c(1, NA, 2, NA)),
    c(1, 2, 2, NA)
  )

  expect_equal(
    bocvaletR:::fill_linear(c(1, NA, 3)),
    c(1, 2, 3)
  )
  expect_equal(
    bocvaletR:::fill_linear(c(1, NA)),
    c(1, NA)
  )

  expect_equal(
    bocvaletR:::roll_mean(1:5, 1),
    1:5
  )
  expect_equal(
    bocvaletR:::roll_mean(1:5, 3),
    c(NA, NA, 2, 3, 4)
  )
})

# Input validation helpers
test_that("validators guard against invalid inputs", {

  expect_error(
    bocvaletR:::validate_data(1),
    "data.frame"
  )

  expect_error(
    bocvaletR:::validate_data(data.frame(a = 1), required_cols = "b"),
    "Missing required column"
  )

  expect_error(
    bocvaletR:::validate_numeric_column(data.frame(a = "x"), "a"),
    "must be numeric"
  )

  expect_error(
    bocvaletR:::validate_scalar_positive_integer(c(1, 2), "periods"),
    "single positive integer"
  )
  expect_error(
    bocvaletR:::validate_scalar_positive_integer(0, "periods"),
    "single positive integer"
  )

  expect_error(
    bocvaletR:::validate_scalar_numeric("a", "threshold"),
    "single finite numeric"
  )
  expect_error(
    bocvaletR:::validate_scalar_numeric(NA_real_, "threshold"),
    "single finite numeric"
  )
})

# Error wrapper should pass values and prepend context
test_that("safe_exec returns result and wraps errors with context", {

  expect_equal(
    bocvaletR:::safe_exec({ 1 + 1 }),
    2
  )

  expect_error(
    bocvaletR:::safe_exec(stop("boom"), context = "calc"),
    "calc: boom"
  )
})

# FX close alignment across time zones and input formats
test_that("boc_align_fx_close aligns timestamps to close date", {

  ts <- as.POSIXct(c("2024-01-02 21:59:00", "2024-01-02 22:10:00"), tz = "UTC")
  df <- data.frame(timestamp = ts)

  aligned <- boc_align_fx_close(
    df,
    cutoff_hour = 17,
    cutoff_min = 0,
    cutoff_tz = "America/New_York",
    new_col = "close_date"
  )

  expect_equal(aligned$close_date, as.Date(c("2024-01-01", "2024-01-02")))

  df_char <- data.frame(timestamp = format(ts))
  aligned_char <- boc_align_fx_close(df_char, input_tz = "UTC")
  expect_equal(aligned_char$fx_date, as.Date(c("2024-01-01", "2024-01-02")))

  expect_error(
    boc_align_fx_close(data.frame(ts = ts), datetime_col = "missing_col"),
    "Missing required column"
  )
})

# Normalization modes (z-score, min-max, index) by series
test_that("boc_normalize supports zscore, minmax, and index methods", {

  df <- data.frame(
    series = rep(c("A", "B"), each = 3),
    value = c(1, 2, 3, 10, 20, 30)
  )

  z <- boc_normalize(df, method = "zscore", new_col = "z")
  expect_equal(z$z[z$series == "A"], c(-1, 0, 1))
  expect_equal(z$z[z$series == "B"], c(-1, 0, 1))

  mm <- boc_normalize(df, method = "minmax", new_col = "mm")
  expect_equal(mm$mm[mm$series == "A"], c(0, 0.5, 1))
  expect_equal(mm$mm[mm$series == "B"], c(0, 0.5, 1))

  idx <- boc_normalize(df, method = "index", index_base = 100, new_col = "idx")
  expect_equal(idx$idx[idx$series == "A"], c(100, 200, 300))
  expect_equal(idx$idx[idx$series == "B"], c(100, 200, 300))

  expect_error(
    boc_normalize(data.frame(series = "A", value = "x"), method = "zscore"),
    "must be numeric"
  )
})

# Missing-value filling strategies per series
test_that("boc_fill_missing fills values using the chosen method", {

  df <- data.frame(
    series = rep("A", 3),
    date = as.Date("2024-01-01") + 0:2,
    value = c(1, NA, 3)
  )

  locf <- boc_fill_missing(df, method = "locf", new_col = "filled")
  expect_equal(locf$filled, c(1, 1, 3))

  nocb <- boc_fill_missing(df, method = "nocb", new_col = "filled")
  expect_equal(nocb$filled, c(1, 3, 3))

  lin <- boc_fill_missing(df, method = "linear", new_col = "filled")
  expect_equal(lin$filled, c(1, 2, 3))

  df_bad <- data.frame(series = "A", date = as.Date("2024-01-01"), value = "x")
  expect_error(
    boc_fill_missing(df_bad),
    "must be numeric"
  )
})

# Grouped summary stats and missingness counts
test_that("boc_summary returns expected aggregates by series", {

  df <- data.frame(
    series = c("A", "A", "B", "B"),
    date = as.Date("2024-01-01") + c(0, 1, 0, 1),
    value = c(1, NA, 3, 5)
  )

  res <- boc_summary(df)

  a_row <- res[res$series == "A", ]
  expect_equal(a_row$n, 2)
  expect_equal(a_row$n_missing, 1)
  expect_equal(a_row$n_non_missing, 1)
  expect_equal(as.Date(a_row$start), as.Date("2024-01-01"))
  expect_equal(as.Date(a_row$end), as.Date("2024-01-02"))
  expect_equal(a_row$min, 1)
  expect_equal(a_row$max, 1)

  b_row <- res[res$series == "B", ]
  expect_equal(b_row$n, 2)
  expect_equal(b_row$n_missing, 0)
  expect_equal(b_row$mean, 4)
  expect_equal(b_row$median, 4)
  expect_equal(b_row$sd, sqrt(2))
})

# Percent change (arithmetic and log) with lag control
test_that("boc_percent_change computes arithmetic and log returns", {

  df <- data.frame(
    series = rep("A", 3),
    date = as.Date("2024-01-01") + 0:2,
    value = c(100, 110, 121)
  )

  arith <- boc_percent_change(df, type = "arithmetic", new_col = "ret")
  expect_equal(arith$ret, c(NA, 0.1, 0.1))

  log_ret <- boc_percent_change(df, type = "log", new_col = "ret")
  expect_equal(log_ret$ret, c(NA, log(1.1), log(1.1)))

  expect_error(
    boc_percent_change(df, periods = 0),
    "single positive integer"
  )
})

# Rolling averages with window validation
test_that("boc_rolling_mean adds moving averages", {

  df <- data.frame(
    series = rep("A", 3),
    date = as.Date("2024-01-01") + 0:2,
    value = c(100, 110, 121)
  )

  roll <- boc_rolling_mean(df, window = 2, new_col = "roll")
  expect_equal(roll$roll, c(NA, 105, 115.5))

  expect_error(
    boc_rolling_mean(df, window = 0),
    "single positive integer"
  )
})

# Autocorrelation table generation and type checking
test_that("boc_autocorr returns lagged autocorrelations", {

  df <- data.frame(
    series = rep(c("A", "B"), each = 6),
    value = c(1:6, 6:1)
  )

  res <- boc_autocorr(df, lag_max = 3)

  expect_true(all(c("series", "lag", "acf") %in% names(res)))
  expect_equal(nrow(res), 6)
  expect_equal(res$lag, c(1, 2, 3, 1, 2, 3))

  bad <- df
  bad$value <- as.character(bad$value)
  expect_error(
    boc_autocorr(bad),
    "must be numeric"
  )
})

# Pairwise correlation matrix and error cases
test_that("boc_correlation returns a matrix for multiple series and errors otherwise", {

  df <- data.frame(
    date = rep(as.Date("2024-01-01") + 0:2, times = 2),
    series = rep(c("s1", "s2"), each = 3),
    value = c(1, 2, 3, 2, 4, 6)
  )

  mat <- boc_correlation(df)

  expect_equal(dim(mat), c(2, 2))
  expect_equal(unname(diag(mat)), c(1, 1))
  expect_equal(unname(mat[1, 2]), 1)
  expect_equal(unname(mat[2, 1]), 1)

  single <- df[df$series == "s1", ]
  expect_error(
    boc_correlation(single),
    "at least two distinct series"
  )
})

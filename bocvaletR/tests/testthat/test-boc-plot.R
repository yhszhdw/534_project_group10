test_that("boc_plot: single-series tibble returns ggplot (backward compatible default)", {

  set.seed(1)
  df <- data.frame(
    date  = as.Date("2020-01-01") + 0:9,
    value = rnorm(10)
  )

  p <- boc_plot(df)  # mode = "auto" by default

  expect_s3_class(p, "ggplot")
})


test_that("boc_plot: default auto uses overlay for multi-series tibble", {

  set.seed(1)
  df_multi <- data.frame(
    date   = rep(as.Date("2020-01-01") + 0:9, times = 2),
    series = rep(c("FXUSDCAD", "FXEURCAD"), each = 10),
    value  = rnorm(20)
  )

  p <- boc_plot(df_multi)  # auto -> overlay for multi-series

  expect_s3_class(p, "ggplot")
})


test_that("boc_plot: overlay, facet and separate work for multi-series tibble", {

  set.seed(2)
  df_multi <- data.frame(
    date   = rep(as.Date("2020-01-01") + 0:9, times = 2),
    series = rep(c("A", "B"), each = 10),
    value  = rnorm(20)
  )

  p_overlay <- boc_plot(df_multi, mode = "overlay")
  p_facet   <- boc_plot(df_multi, mode = "facet")
  p_sep     <- boc_plot(df_multi, mode = "separate")

  expect_s3_class(p_overlay, "ggplot")
  expect_s3_class(p_facet, "ggplot")

  expect_type(p_sep, "list")
  expect_named(p_sep, c("A", "B"))
  expect_true(all(vapply(p_sep, inherits, logical(1), what = "ggplot")))
})


test_that("boc_plot: list input (concat=FALSE style) works for overlay/facet/separate", {

  set.seed(3)
  lst <- list(
    FXUSDCAD = data.frame(date = as.Date("2020-01-01") + 0:9, value = rnorm(10)),
    FXEURCAD = data.frame(date = as.Date("2020-01-01") + 0:9, value = rnorm(10))
  )

  p_overlay <- boc_plot(lst, mode = "overlay")
  p_facet   <- boc_plot(lst, mode = "facet")
  p_sep     <- boc_plot(lst, mode = "separate")

  expect_s3_class(p_overlay, "ggplot")
  expect_s3_class(p_facet, "ggplot")

  expect_type(p_sep, "list")
  expect_identical(sort(names(p_sep)), sort(c("FXUSDCAD", "FXEURCAD")))
  expect_true(all(vapply(p_sep, inherits, logical(1), what = "ggplot")))
})


test_that("boc_plot: list input without names gets auto series names in separate mode", {

  set.seed(4)
  lst_unnamed <- list(
    data.frame(date = as.Date("2020-01-01") + 0:9, value = rnorm(10)),
    data.frame(date = as.Date("2020-01-01") + 0:9, value = rnorm(10))
  )

  p_sep <- boc_plot(lst_unnamed, mode = "separate")

  expect_type(p_sep, "list")
  expect_named(p_sep, c("series_1", "series_2"))
  expect_true(all(vapply(p_sep, inherits, logical(1), what = "ggplot")))
})


test_that("boc_plot: legend=FALSE hides legend in overlay", {

  set.seed(5)
  df_multi <- data.frame(
    date   = rep(as.Date("2020-01-01") + 0:9, times = 2),
    series = rep(c("A", "B"), each = 10),
    value  = rnorm(20)
  )

  p <- boc_plot(df_multi, mode = "overlay", legend = FALSE)

  expect_s3_class(p, "ggplot")
  # ggplot2 stores legend position in theme; "none" should be set
  expect_identical(p$theme$legend.position, "none")
})


test_that("boc_plot: na_rm=TRUE drops NA rows and still plots if enough remain", {

  set.seed(6)
  df <- data.frame(
    date  = as.Date("2020-01-01") + 0:9,
    value = rnorm(10)
  )
  df$value[1] <- NA
  df$date[2]  <- NA

  p <- boc_plot(df, na_rm = TRUE)

  expect_s3_class(p, "ggplot")
})


test_that("boc_plot: na_rm=FALSE allows NA but may error if too few complete rows", {

  # Here we intentionally create NAs such that effectively no usable points remain.
  df <- data.frame(
    date  = as.Date("2020-01-01") + 0:1,
    value = c(NA_real_, NA_real_)
  )

  expect_error(
    boc_plot(df, na_rm = TRUE),
    "No sufficient non-missing observations",
    fixed = TRUE
  )
})


test_that("boc_plot: rejects non-data-frame input", {

  expect_error(
    boc_plot("not a data frame"),
    "data.frame|tibble|list",
    ignore.case = TRUE
  )
})


test_that("boc_plot: rejects empty list input", {

  expect_error(
    boc_plot(list()),
    "empty",
    ignore.case = TRUE
  )
})


test_that("boc_plot: rejects missing required columns", {

  df_missing <- data.frame(
    date = as.Date("2020-01-01") + 0:4
  )

  expect_error(
    boc_plot(df_missing),
    "date.*value",
    ignore.case = TRUE
  )
})


test_that("boc_plot: rejects non-date date column", {

  df_bad_date <- data.frame(
    date  = as.character(as.Date("2020-01-01") + 0:4),
    value = rnorm(5)
  )

  expect_error(
    boc_plot(df_bad_date),
    "Date|POSIX",
    ignore.case = TRUE
  )
})


test_that("boc_plot: rejects non-numeric value column", {

  df_bad_value <- data.frame(
    date  = as.Date("2020-01-01") + 0:4,
    value = as.character(rnorm(5))
  )

  expect_error(
    boc_plot(df_bad_value),
    "numeric",
    ignore.case = TRUE
  )
})


test_that("boc_plot: rejects insufficient observations", {

  df_short <- data.frame(
    date  = as.Date("2020-01-01"),
    value = 1.25
  )

  expect_error(
    boc_plot(df_short),
    "two|2|at least",
    ignore.case = TRUE
  )
})


test_that("boc_plot: rejects wrong mode value", {

  df <- data.frame(
    date  = as.Date("2020-01-01") + 0:9,
    value = rnorm(10)
  )

  expect_error(
    boc_plot(df, mode = "not-a-mode"),
    "should be one of",
    fixed = TRUE
  )
})

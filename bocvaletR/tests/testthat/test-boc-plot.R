test_that("boc_plot returns a ggplot object for valid input", {
  
  df <- data.frame(
    date  = as.Date("2020-01-01") + 0:9,
    value = rnorm(10)
  )
  
  p <- boc_plot(df)
  
  expect_s3_class(p, "ggplot")
})

test_that("boc_plot rejects non-data-frame input", {
  
  expect_error(
    boc_plot("not a data frame"),
    "data.frame"
  )
})

test_that("boc_plot rejects missing required columns", {
  
  df_missing <- data.frame(
    date = as.Date("2020-01-01") + 0:4
  )
  
  expect_error(
    boc_plot(df_missing),
    "date.*value"
  )
})

test_that("boc_plot rejects non-date date column", {
  
  df_bad_date <- data.frame(
    date  = as.character(as.Date("2020-01-01") + 0:4),
    value = rnorm(5)
  )
  
  expect_error(
    boc_plot(df_bad_date),
    "Date"
  )
})

test_that("boc_plot rejects non-numeric value column", {
  
  df_bad_value <- data.frame(
    date  = as.Date("2020-01-01") + 0:4,
    value = as.character(rnorm(5))
  )
  
  expect_error(
    boc_plot(df_bad_value),
    "numeric"
  )
})

test_that("boc_plot rejects insufficient observations", {
  
  df_short <- data.frame(
    date  = as.Date("2020-01-01"),
    value = 1.25
  )
  
  expect_error(
    boc_plot(df_short),
    "at least two"
  )
})

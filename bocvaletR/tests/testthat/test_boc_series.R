test_that("boc_series returns tibble for a single series (normal path)", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      expect_equal(path, "observations/FXUSDCAD/json")
      # query should include provided start/end if passed (we test separately below)
      list(
        observations = list(
          list(d = "2024-01-01", FXUSDCAD = list(v = "1.10")),
          list(d = "2024-01-02", FXUSDCAD = list(v = "1.20"))
        )
      )
    }
  )

  df <- boc_series("FXUSDCAD", concat = TRUE, progress = FALSE)

  expect_s3_class(df, "tbl_df")
  expect_equal(names(df), c("date", "series", "value"))
  expect_equal(nrow(df), 2)
  expect_equal(unique(df$series), "FXUSDCAD")
  expect_equal(df$value, c(1.10, 1.20))
})

test_that("boc_series passes start_date/end_date via query", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      expect_equal(path, "observations/FXUSDCAD/json")
      expect_equal(query$start_date, "2024-01-01")
      expect_equal(query$end_date, "2024-01-31")
      list(observations = list())
    }
  )

  # observations empty -> should still return empty tibble (no warning for empty list)
  df <- boc_series(
    "FXUSDCAD",
    start_date = "2024-01-01",
    end_date = "2024-01-31",
    concat = TRUE,
    progress = FALSE
  )
  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
  expect_equal(names(df), c("date", "series", "value"))
})

test_that("boc_series returns concatenated tibble for multiple series", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      if (path == "observations/A/json") {
        return(list(observations = list(
          list(d = "2024-01-01", A = list(v = "1")),
          list(d = "2024-01-02", A = list(v = "2"))
        )))
      }
      if (path == "observations/B/json") {
        return(list(observations = list(
          list(d = "2024-01-01", B = list(v = "10"))
        )))
      }
      stop("unexpected path")
    }
  )

  df <- boc_series(c("A", "B"), concat = TRUE, progress = FALSE)

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 3)
  expect_true(all(c("A", "B") %in% df$series))
  expect_equal(sum(df$series == "A"), 2)
  expect_equal(sum(df$series == "B"), 1)
})

test_that("boc_series returns named list when concat = FALSE", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      if (path == "observations/A/json") {
        return(list(observations = list(list(d = "2024-01-01", A = list(v = "1")))))
      }
      if (path == "observations/B/json") {
        return(list(observations = list(list(d = "2024-01-01", B = list(v = "2")))))
      }
      stop("unexpected path")
    }
  )

  out <- boc_series(c("A", "B"), concat = FALSE, progress = FALSE)

  expect_true(is.list(out))
  expect_equal(names(out), c("A", "B"))
  expect_s3_class(out$A, "tbl_df")
  expect_s3_class(out$B, "tbl_df")
  expect_equal(out$A$series[[1]], "A")
  expect_equal(out$B$series[[1]], "B")
})

test_that("boc_series trims and drops empty/NA series IDs", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      expect_equal(path, "observations/A/json")
      list(observations = list(list(d = "2024-01-01", A = list(v = "1"))))
    }
  )

  out <- boc_series(c("  A  ", "", NA_character_), concat = TRUE, progress = FALSE)

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1)
  expect_equal(out$series[[1]], "A")
})

test_that("boc_series handles request errors with warning and empty tibble", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      stop("boom")
    }
  )

  expect_warning(
    df <- boc_series("A", concat = TRUE, progress = FALSE),
    "request failed for series 'A'",
    fixed = FALSE
  )
  # After request fails, it will also warn about missing/invalid observations
  expect_warning(
    df <- boc_series("A", concat = TRUE, progress = FALSE),
    "missing or invalid `observations`",
    fixed = FALSE
  )

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
  expect_equal(names(df), c("date", "series", "value"))
})

test_that("boc_series handles invalid observations structure with warning and empty tibble", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      list(observations = "not a list")
    }
  )

  expect_warning(
    df <- boc_series("A", concat = TRUE, progress = FALSE),
    "missing or invalid `observations`",
    fixed = FALSE
  )

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

test_that("boc_series handles missing values inside observations (safe parsing)", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      list(
        observations = list(
          list(d = "2024-01-01", A = list(v = "1.5")),
          list(d = "2024-01-02"),                 # missing series field
          list(d = "2024-01-03", A = list(v = "")) # empty -> NA when numeric
        )
      )
    }
  )

  df <- boc_series("A", concat = TRUE, progress = FALSE)

  expect_equal(nrow(df), 3)
  expect_equal(df$series, rep("A", 3))
  expect_equal(df$date, as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")))
  expect_equal(df$value, c(1.5, NA_real_, NA_real_))
})

test_that("boc_series does not create progress bar when n = 1 (progress=TRUE)", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      list(observations = list())
    }
  )

  df <- boc_series("A", concat = TRUE, progress = TRUE)
  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

test_that("boc_series works with progress=FALSE for multiple series", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      list(observations = list())
    }
  )

  df <- boc_series(c("A", "B"), concat = TRUE, progress = FALSE)
  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

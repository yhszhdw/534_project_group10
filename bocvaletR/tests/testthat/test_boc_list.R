test_that("boc_list_series works in normal df/json modes", {
  local_mocked_bindings(
    boc_request = function(path) {
      expect_equal(path, "lists/series/json")
      list(
        series = list(
          FXAUDCAD = list(
            label = "AUD/CAD",
            description = "FX rate",
            link = "https://example.com/FXAUDCAD"
          ),
          V39079 = list(
            label = "CPI",
            description = "Consumer Price Index",
            link = "https://example.com/V39079"
          )
        )
      )
    }
  )

  df <- boc_list_series()
  expect_s3_class(df, "tbl_df")
  expect_true(all(c("id", "label", "description", "link") %in% names(df)))
  expect_equal(nrow(df), 2)

  df_fx <- boc_list_series(keyword = "fx")
  expect_equal(nrow(df_fx), 1)
  expect_equal(df_fx$id[[1]], "FXAUDCAD")

  df_1 <- boc_list_series(limit = 1)
  expect_equal(nrow(df_1), 1)

  j <- boc_list_series(as = "json")
  expect_true(is.list(j))
  expect_true("series" %in% names(j))
})

test_that("boc_list_series handles missing/empty response gracefully", {
  local_mocked_bindings(
    boc_request = function(path) {
      expect_equal(path, "lists/series/json")
      list(series = list())
    }
  )

  expect_warning(
    df <- boc_list_series(),
    "missing or empty `series`",
    fixed = FALSE
  )
  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

test_that("boc_list_series returns empty tibble when boc_request errors", {
  local_mocked_bindings(
    boc_request = function(path) stop("boom")
  )

  # Some implementations warn "request failed", some only warn "missing or empty `series`".
  # The contract we assert: it should return an empty tibble and warn about empty/missing series.
  expect_warning(
    df <- boc_list_series(),
    "missing or empty `series`",
    fixed = FALSE
  )

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

# ----------------------------------------------------------------------

test_that("boc_list_groups works in normal df/json modes", {
  local_mocked_bindings(
    boc_request = function(path) {
      expect_equal(path, "lists/groups/json")
      list(
        groups = list(
          FX = list(
            label = "Foreign Exchange",
            description = "Line1\nLine2\tMore",
            link = "https://example.com/FX"
          ),
          CPI = list(
            label = "Inflation",
            description = "Consumer   price   index",
            link = "https://example.com/CPI"
          )
        )
      )
    }
  )

  df <- boc_list_groups()
  expect_s3_class(df, "tbl_df")
  expect_true(all(c("id", "label", "description", "link") %in% names(df)))
  expect_equal(nrow(df), 2)

  fx_desc <- df$description[df$id == "FX"][[1]]
  expect_false(grepl("\n|\t", fx_desc))
  expect_false(grepl("\\s{2,}", fx_desc))

  df_fx <- boc_list_groups(keyword = "foreign")
  expect_equal(nrow(df_fx), 1)
  expect_equal(df_fx$id[[1]], "FX")

  df_1 <- boc_list_groups(limit = 1)
  expect_equal(nrow(df_1), 1)

  j <- boc_list_groups(as = "json")
  expect_true(is.list(j))
  expect_true("groups" %in% names(j))

  df_raw <- boc_list_groups(clean_description = FALSE)
  fx_desc_raw <- df_raw$description[df_raw$id == "FX"][[1]]
  expect_true(grepl("\n|\t", fx_desc_raw))
})

test_that("boc_list_groups handles missing/empty response gracefully", {
  local_mocked_bindings(
    boc_request = function(path) {
      expect_equal(path, "lists/groups/json")
      list(groups = list())
    }
  )

  expect_warning(
    df <- boc_list_groups(),
    "missing or empty `groups`",
    fixed = FALSE
  )

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

test_that("boc_list_groups returns empty tibble when boc_request errors", {
  local_mocked_bindings(
    boc_request = function(path) stop("boom")
  )

  expect_warning(
    df <- boc_list_groups(),
    "missing or empty `groups`",
    fixed = FALSE
  )

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

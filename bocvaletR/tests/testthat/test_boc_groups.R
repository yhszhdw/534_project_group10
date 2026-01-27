test_that("boc_groups returns list with group + series (normal path)", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      expect_equal(path, "groups/FX_RATES_DAILY/json")
      list(
        groupDetails = list(
          name = "FX_RATES_DAILY",
          label = "Daily FX Rates",
          description = "Foreign exchange rates (daily).",
          groupSeries = list(
            FXUSDCAD = list(label = "USD/CAD", link = "https://example.com/FXUSDCAD"),
            FXAUDCAD = list(label = "AUD/CAD", link = "https://example.com/FXAUDCAD")
          )
        )
      )
    }
  )

  out <- boc_groups("FX_RATES_DAILY", as = "list")

  expect_true(is.list(out))
  expect_true(all(c("group", "series") %in% names(out)))

  expect_s3_class(out$group, "tbl_df")
  expect_equal(names(out$group), c("group_id", "label", "description"))
  expect_equal(nrow(out$group), 1)
  expect_equal(out$group$group_id[[1]], "FX_RATES_DAILY")

  expect_s3_class(out$series, "tbl_df")
  expect_equal(names(out$series), c("id", "label", "link"))
  expect_equal(nrow(out$series), 2)
  expect_true(all(c("FXUSDCAD", "FXAUDCAD") %in% out$series$id))
})

test_that("boc_groups supports as = group_df and as = series_df", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      list(
        groupDetails = list(
          name = "G1",
          label = "Group One",
          description = "Desc",
          groupSeries = list(
            S1 = list(label = "Series 1", link = "https://example.com/S1")
          )
        )
      )
    }
  )

  gdf <- boc_groups("G1", as = "group_df")
  expect_s3_class(gdf, "tbl_df")
  expect_equal(names(gdf), c("group_id", "label", "description"))
  expect_equal(nrow(gdf), 1)
  expect_equal(gdf$group_id[[1]], "G1")

  sdf <- boc_groups("G1", as = "series_df")
  expect_s3_class(sdf, "tbl_df")
  expect_equal(names(sdf), c("id", "label", "link"))
  expect_equal(nrow(sdf), 1)
  expect_equal(sdf$id[[1]], "S1")
})

test_that("boc_groups returns empty series tibble when groupSeries is missing/empty", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      list(
        groupDetails = list(
          name = "GEMPTY",
          label = "Empty group",
          description = "No series here"
          # groupSeries missing on purpose
        )
      )
    }
  )

  out <- boc_groups("GEMPTY", as = "list")
  expect_s3_class(out$group, "tbl_df")
  expect_equal(out$group$group_id[[1]], "GEMPTY")

  expect_s3_class(out$series, "tbl_df")
  expect_equal(nrow(out$series), 0)
  expect_equal(names(out$series), c("id", "label", "link"))
})

test_that("boc_groups trims whitespace around group id", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      expect_equal(path, "groups/ABC/json")
      list(
        groupDetails = list(
          name = "ABC",
          label = "ABC label",
          description = "ABC desc",
          groupSeries = list()
        )
      )
    }
  )

  gdf <- boc_groups("  ABC  ", as = "group_df")
  expect_equal(gdf$group_id[[1]], "ABC")
})

test_that("boc_groups handles request errors and returns empty outputs", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) stop("boom")
  )

  expect_warning(
    out <- boc_groups("FX_RATES_DAILY", as = "list"),
    "request failed",
    fixed = FALSE
  )
  # After request failure, it also warns missing groupDetails
  expect_warning(
    out <- boc_groups("FX_RATES_DAILY", as = "list"),
    "missing groupDetails",
    fixed = FALSE
  )

  expect_s3_class(out$group, "tbl_df")
  expect_s3_class(out$series, "tbl_df")
  expect_equal(nrow(out$group), 1)   # empty_group_df has 1 row (group_id filled)
  expect_equal(nrow(out$series), 0)  # empty_series_df has 0 rows
})

test_that("boc_groups handles missing groupDetails and returns empty outputs", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) list(not_groupDetails = TRUE)
  )

  expect_warning(
    out <- boc_groups("FX_RATES_DAILY", as = "list"),
    "missing groupDetails",
    fixed = FALSE
  )

  expect_s3_class(out$group, "tbl_df")
  expect_s3_class(out$series, "tbl_df")
  expect_equal(nrow(out$group), 1)
  expect_equal(nrow(out$series), 0)
})

test_that("boc_groups tolerates a malformed groupSeries element (does not error)", {
  local_mocked_bindings(
    boc_request = function(path, query = list()) {
      list(
        groupDetails = list(
          name = "G2",
          label = "Group 2",
          description = "Desc",
          groupSeries = list(
            S1 = list(label = "ok", link = "https://example.com/S1"),
            S2 = NULL  # malformed element; should still produce a row
          )
        )
      )
    }
  )

  out <- boc_groups("G2", as = "series_df")
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2)
  expect_true(all(c("S1", "S2") %in% out$id))
})

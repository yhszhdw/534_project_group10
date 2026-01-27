testthat::test_that("boc_request returns parsed list on success (mocked)", {
  httr2::with_mocked_responses(
    mock = list(
      httr2::response(
        url = "https://www.bankofcanada.ca/valet/lists/series/json",
        status_code = 200,
        headers = c("content-type" = "application/json; charset=utf-8"),
        body = charToRaw('{"series":{"FXUSDCAD":{"label":"USD/CAD"}}}')
      )
    ),
    code = {
      res <- bocvaletR:::boc_request("lists/series/json")
      testthat::expect_type(res, "list")
      testthat::expect_true("series" %in% names(res))
      testthat::expect_true("FXUSDCAD" %in% names(res$series))
      testthat::expect_equal(res$series$FXUSDCAD$label, "USD/CAD")
    }
  )
})


testthat::test_that("boc_request accepts query params without error (mocked)", {
  httr2::with_mocked_responses(
    mock = list(
      httr2::response(
        url = "https://www.bankofcanada.ca/valet/observations/FXUSDCAD/json",
        status_code = 200,
        headers = c("content-type" = "application/json; charset=utf-8"),
        body = charToRaw('{"observations":[]}')
      )
    ),
    code = {
      res <- bocvaletR:::boc_request(
        "observations/FXUSDCAD/json",
        query = list(start_date = "2020-01-01", end_date = "2020-01-31")
      )
      testthat::expect_type(res, "list")
      testthat::expect_true("observations" %in% names(res))
    }
  )
})

testthat::test_that("boc_request aborts with friendly message when JSON parsing fails", {
  httr2::with_mocked_responses(
    mock = list(
      httr2::response(
        url = "https://www.bankofcanada.ca/valet/lists/series/json",
        status_code = 200,
        headers = c("content-type" = "text/html; charset=utf-8"),
        body = charToRaw("<html>not json</html>")
      )
    ),
    code = {
      testthat::expect_error(
        bocvaletR:::boc_request("lists/series/json"),
        "Failed to parse JSON with simplifyVector=FALSE",
        fixed = TRUE
      )
    }
  )
})

test_that("CI is really running tests", {
  expect_equal(1, 2)
})
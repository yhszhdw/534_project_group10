test_that("boc_request returns parsed JSON list (normal path)", {
  # 1) mock httr2 pipeline entry/exit
  testthat::local_mocked_bindings(
    request = function(url) {
      # return a "request" object; can just be a list
      list(url = url, headers = list(), query = list())
    },
    req_user_agent = function(req, ua) req,
    req_headers = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_url_query = function(req, ...) req,

    # final perform returns a "response"
    req_perform = function(req, ...) {
      structure(
        list(status = 200L),
        class = "mock_resp"
      )
    },

    # 2) mock status check + json parsing
    resp_check_status = function(resp, ...) invisible(resp),
    resp_body_json = function(resp, simplifyVector = FALSE, check_type = TRUE, ...) {
      list(ok = TRUE, value = 123)
    },

    .package = "httr2"
  )

  out <- bocvaletR:::boc_request("lists/series/json", query = list(a = 1))

  testthat::expect_type(out, "list")
  testthat::expect_true(isTRUE(out$ok))
  testthat::expect_equal(out$value, 123)
})

test_that("boc_request throws readable error on non-2xx (resp_check_status error path)", {
  testthat::local_mocked_bindings(
    request = function(url) list(url = url),
    req_user_agent = function(req, ua) req,
    req_headers = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_url_query = function(req, ...) req,
    req_perform = function(req, ...) structure(list(status = 500L), class = "mock_resp"),

    resp_check_status = function(resp, ...) stop("status not ok"),
    resp_status = function(resp, ...) 500L,
    resp_body_string = function(resp, ...) "server error",

    .package = "httr2"
  )

  testthat::expect_error(
    bocvaletR:::boc_request("lists/series/json"),
    regexp = "Bank of Canada API request failed \\(HTTP 500\\).*Path: lists/series/json",
    fixed = FALSE
  )
})

test_that("boc_request falls back to check_type = FALSE when content-type missing", {
  called <- new.env(parent = emptyenv())
  called$n <- 0L

  testthat::local_mocked_bindings(
    request = function(url) list(url = url),
    req_user_agent = function(req, ua) req,
    req_headers = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_url_query = function(req, ...) req,
    req_perform = function(req, ...) structure(list(status = 200L), class = "mock_resp"),
    resp_check_status = function(resp, ...) invisible(resp),

    resp_body_json = function(resp, simplifyVector = FALSE, check_type = TRUE, ...) {
      called$n <- called$n + 1L
      if (check_type) stop("missing content-type")
      list(ok = TRUE)
    },

    .package = "httr2"
  )

  out <- bocvaletR:::boc_request("lists/series/json")
  testthat::expect_true(isTRUE(out$ok))
  testthat::expect_equal(called$n, 2L)  # first fails, second succeeds
})

test_that("boc_request throws readable error when JSON cannot be parsed", {
  testthat::local_mocked_bindings(
    request = function(url) list(url = url),
    req_user_agent = function(req, ua) req,
    req_headers = function(req, ...) req,
    req_timeout = function(req, ...) req,
    req_retry = function(req, ...) req,
    req_url_query = function(req, ...) req,
    req_perform = function(req, ...) structure(list(status = 200L), class = "mock_resp"),
    resp_check_status = function(resp, ...) invisible(resp),

    resp_body_json = function(resp, simplifyVector = FALSE, check_type = TRUE, ...) {
      stop("json parse error")
    },
    resp_content_type = function(resp, ...) "application/json",

    .package = "httr2"
  )

  testthat::expect_error(
    bocvaletR:::boc_request("lists/series/json"),
    regexp = "Failed to parse JSON response\\..*Path: lists/series/json",
    fixed = FALSE
  )
})

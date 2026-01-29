#' Internal helper to call Bank of Canada Valet API
#'
#' @param path API path after /valet/ (e.g. "lists/series/json")
#' @param query Named list of query parameters (e.g. list(start_date="2020-01-01"))
#'
#' @return Parsed JSON response (list)
#' @keywords internal
boc_request <- function(path, query = list()) {
  stopifnot(is.character(path), length(path) == 1, nzchar(path))
  stopifnot(is.list(query))

  base_url <- "https://www.bankofcanada.ca/valet/"
  url <- paste0(base_url, path)

  # Best-effort user agent (doesn't fail if DESCRIPTION isn't available)
  ua <- "bocvaletR (valet API)"
  pkg_ver <- tryCatch(utils::packageVersion("bocvaletR"), error = function(e) NULL)
  if (!is.null(pkg_ver)) ua <- paste0("bocvaletR/", pkg_ver, " (valet API)")

  resp <- httr2::request(url) |>
    httr2::req_user_agent(ua) |>
    httr2::req_headers("Accept" = "application/json") |>
    httr2::req_timeout(30) |>
    httr2::req_retry(
      max_tries = 3,
      backoff = ~ 0.5 * (2 ^ (.x - 1)),
      is_transient = function(resp) {
        # retry on network errors or transient server codes
        is.null(resp) || httr2::resp_status(resp) %in% c(408, 429, 500, 502, 503, 504)
      }
    ) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_perform()

  # Fail early on non-2xx with readable message
  tryCatch(
    httr2::resp_check_status(resp),
    error = function(e) {
      status <- tryCatch(httr2::resp_status(resp), error = function(e2) NA_integer_)
      body_txt <- tryCatch(httr2::resp_body_string(resp), error = function(e2) "")
      body_txt <- substr(body_txt, 1, 500)
      rlang::abort(paste0(
        "Bank of Canada API request failed (HTTP ", status, "). ",
        "Path: ", path, ". ",
        if (nzchar(body_txt)) paste0("Response (first 500 chars): ", body_txt) else ""
      ))
    }
  )

  # Parse JSON robustly:
  # 1) Try strict parsing (checks content-type)
  # 2) If API/mocks omit content-type, fall back to check_type = FALSE
  tryCatch(
    httr2::resp_body_json(resp, simplifyVector = FALSE),
    error = function(e1) {
      tryCatch(
        httr2::resp_body_json(resp, simplifyVector = FALSE, check_type = FALSE),
        error = function(e2) {
          ct <- tryCatch(httr2::resp_content_type(resp), error = function(e3) NA_character_)
          rlang::abort(paste0(
            "Failed to parse JSON response. ",
            "Path: ", path, ". ",
            "Content-Type: ", ct, ". ",
            "Error: ", conditionMessage(e2)
          ))
        }
      )
    }
  )
}

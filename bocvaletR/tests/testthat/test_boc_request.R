#' Internal helper to call Bank of Canada Valet API
#'
#' @param path API path after /valet/
#' @param query Named list of query parameters
#' @return Parsed JSON response
#' @keywords internal
boc_request <- function(path, query = list()) {
  
  base_url <- "https://www.bankofcanada.ca/valet/"
  url <- paste0(base_url, path)
  
  resp <- httr2::request(url) |>
    httr2::req_timeout(30) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_url_query(!!!query) |>
    httr2::req_perform() #|>
    # httr2::resp_check_status()
  
  tryCatch(
    {
      httr2::resp_body_json(resp, simplifyVector = FALSE, check_type = FALSE)
    },
    error = function(e) {
      rlang::abort(paste0(
        "Failed to parse JSON with simplifyVector=FALSE: ",
        conditionMessage(e)
      ))
    }
  )
}

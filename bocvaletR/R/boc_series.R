#' Get Bank of Canada time series data
#'
#' @param series Character vector of series IDs (e.g. "FXUSDCAD")
#' @param start_date Start date (YYYY-MM-DD)
#' @param end_date End date (YYYY-MM-DD)
#'
#' @return A tibble with date, series, and value
#' @export
boc_series <- function(series,
                       start_date = NULL,
                       end_date = NULL) {
  
  stopifnot(is.character(series))
  
  query <- list()
  if (!is.null(start_date)) query$start_date <- start_date
  if (!is.null(end_date))   query$end_date   <- end_date
  
  out <- lapply(series, function(s) {
    
    json <- boc_request(
      path  = paste0("observations/", s, "/json"),
      query = query
    )
    
    obs <- json$observations
    if (length(obs) == 0) return(NULL)
    
    tibble::tibble(
      date   = as.Date(vapply(obs, `[[`, "", "d")),
      series = s,
      value  = as.numeric(
        vapply(obs, function(x) x[[s]]$v, "", USE.NAMES = FALSE)
      )
    )
  })
  
  dplyr::bind_rows(out)
}

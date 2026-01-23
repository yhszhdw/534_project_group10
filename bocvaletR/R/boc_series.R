#' Get Bank of Canada time series data
#'
#' @param series Character vector of series IDs (e.g. "FXUSDCAD")
#' @param start_date Start date (YYYY-MM-DD)
#' @param end_date End date (YYYY-MM-DD)
#' @param concat Logical. If TRUE (default), return a single concatenated tibble.
#'   If FALSE, return a named list of tibbles, one per series.
#' @param progress Logical. If TRUE (default), show a progress bar.
#'
#' @return A tibble or a named list of tibbles depending on `concat`
#' @export
boc_series <- function(series,
                       start_date = NULL,
                       end_date = NULL,
                       concat = TRUE,
                       progress = TRUE) {

  stopifnot(is.character(series))
  stopifnot(is.logical(concat), length(concat) == 1)
  stopifnot(is.logical(progress), length(progress) == 1)

  query <- list()
  if (!is.null(start_date)) query$start_date <- start_date
  if (!is.null(end_date))   query$end_date   <- end_date

  n <- length(series)

  pb <- NULL
  if (isTRUE(progress) && n > 1) {
    pb <- utils::txtProgressBar(min = 0, max = n, style = 3)
    on.exit({
      try(utils::close(pb), silent = TRUE)
      cat("\n")
    }, add = TRUE)
  }

  out <- vector("list", n)

  for (i in seq_along(series)) {
    s <- series[[i]]

    json <- boc_request(
      path  = paste0("observations/", s, "/json"),
      query = query
    )

    obs <- json$observations

    out[[i]] <- if (length(obs) == 0) {
      tibble::tibble(
        date = as.Date(character()),
        series = s,
        value = numeric()
      )
    } else {
      tibble::tibble(
        date   = as.Date(vapply(obs, `[[`, "", "d")),
        series = s,
        value  = as.numeric(
          vapply(obs, function(x) x[[s]]$v, "", USE.NAMES = FALSE)
        )
      )
    }

    if (!is.null(pb)) utils::setTxtProgressBar(pb, i)
  }

  names(out) <- series

  if (isTRUE(concat)) {
    return(dplyr::bind_rows(out))
  }

  out
}

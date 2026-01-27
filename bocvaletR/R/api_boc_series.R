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

  # light input cleanup (not a big structural change)
  series <- trimws(series)
  series <- series[!is.na(series) & nzchar(series)]

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

  empty_series_tbl <- function(s) {
    tibble::tibble(
      date = as.Date(character()),
      series = s,
      value = numeric()
    )
  }

  out <- vector("list", n)

  for (i in seq_along(series)) {
    s <- series[[i]]

    # Graceful: request failure / HTTP errors / bad JSON
    json <- tryCatch(
      boc_request(
        path  = paste0("observations/", s, "/json"),
        query = query
      ),
      error = function(e) {
        warning(sprintf("boc_series: request failed for series '%s': %s", s, conditionMessage(e)))
        return(NULL)
      }
    )

    if (is.null(json) || is.null(json$observations) || !is.list(json$observations)) {
      warning(sprintf("boc_series: missing or invalid `observations` for series '%s' (series may not exist or response format changed)", s))
      out[[i]] <- empty_series_tbl(s)
      if (!is.null(pb)) utils::setTxtProgressBar(pb, i)
      next
    }

    obs <- json$observations

    # Parse observations safely
    if (length(obs) == 0) {
      out[[i]] <- empty_series_tbl(s)
    } else {
      dates_chr <- tryCatch(
        vapply(obs, `[[`, "", "d"),
        error = function(e) {
          warning(sprintf("boc_series: failed extracting dates for series '%s': %s", s, conditionMessage(e)))
          rep(NA_character_, length(obs))
        }
      )

      values_chr <- tryCatch(
        vapply(obs, function(x) {
          # x[[s]] might be NULL if response structure differs; return NA in that case
          if (is.null(x[[s]]) || is.null(x[[s]]$v)) return(NA_character_)
          x[[s]]$v
        }, "", USE.NAMES = FALSE),
        error = function(e) {
          warning(sprintf("boc_series: failed extracting values for series '%s': %s", s, conditionMessage(e)))
          rep(NA_character_, length(obs))
        }
      )

      out[[i]] <- tibble::tibble(
        date   = as.Date(dates_chr),
        series = s,
        value  = suppressWarnings(as.numeric(values_chr))
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

#' Get Bank of Canada FX RSS exchange rates (RDF/XML)
#'
#' @param series Character vector of FX series IDs (e.g. "FXAUDCAD").
#'   If NULL or length 0, fetches ALL available FX rates from /valet/fx_rss.
#' @param concat Logical. If TRUE (default), bind all into one tibble.
#'   If FALSE, return a named list of tibbles.
#' @param progress Logical. Show progress bar when multiple series are requested.
#'
#' @return A tibble (or named list) of the latest FX observations from RSS.
#' @export
boc_fx_rss <- function(series = NULL, concat = TRUE, progress = TRUE) {
  stopifnot(is.logical(concat), length(concat) == 1)
  stopifnot(is.logical(progress), length(progress) == 1)

  # namespaces
  ns <- c(
    rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    rss = "http://purl.org/rss/1.0/",
    dc  = "http://purl.org/dc/elements/1.1/",
    cb  = "http://www.cbwiki.net/wiki/index.php/Specification_1.1"
  )

  xtext1 <- function(node, path) {
    x <- xml2::xml_find_first(node, path, ns = ns)
    if (inherits(x, "xml_missing") || length(x) == 0) return(NA_character_)
    txt <- xml2::xml_text(x)
    if (!nzchar(txt)) NA_character_ else txt
  }

  parse_item_series <- function(item_about) {
    # https://www.bankofcanada.ca/valet/fx_rss/FXAUDCAD -> FXAUDCAD
    if (is.na(item_about) || !nzchar(item_about)) return(NA_character_)
    sub(".*/", "", item_about)
  }

  # helper to return a correctly-shaped empty tibble
  empty_fx_tbl <- function(feed_series = NULL) {
    tibble::tibble(
      feed_series = if (is.null(feed_series) || !nzchar(feed_series)) NA_character_ else feed_series,
      item_series = character(),
      title = character(),
      link = character(),
      description = character(),
      dc_date_utc = as.POSIXct(character(), tz = "UTC"),
      value = numeric(),
      base_currency = character(),
      target_currency = character(),
      rate_type = character(),
      observation_period_utc = as.POSIXct(character(), tz = "UTC"),
      country = character()
    )
  }

  # robust datetime parsing (proposal #4)
  parse_boc_datetime_utc <- function(x) {
    if (is.na(x) || !nzchar(x)) return(as.POSIXct(NA_character_, tz = "UTC"))
    # try a few common ISO-8601 variants, including fractional seconds and offsets
    as.POSIXct(
      x,
      tz = "UTC",
      tryFormats = c(
        "%Y-%m-%dT%H:%M:%SZ",
        "%Y-%m-%dT%H:%M:%OSZ",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%OS%z",
        "%Y-%m-%dT%H:%M:%S%:z",
        "%Y-%m-%dT%H:%M:%OS%:z"
      )
    )
  }

  fetch_one_feed <- function(feed_series = NULL) {
    url <- if (is.null(feed_series) || length(feed_series) == 0 || !nzchar(feed_series)) {
      "https://www.bankofcanada.ca/valet/fx_rss"
    } else {
      paste0("https://www.bankofcanada.ca/valet/fx_rss/", feed_series)
    }

    # graceful network / HTTP errors (proposal #1)
    resp <- tryCatch(
      httr::GET(url, httr::user_agent("bocvaletR (fx_rss)")),
      error = function(e) {
        warning(sprintf("boc_fx_rss: request failed for '%s': %s", url, conditionMessage(e)))
        return(NULL)
      }
    )
    if (is.null(resp)) return(empty_fx_tbl(feed_series))

    # stop_for_status but graceful (proposal #1)
    ok <- tryCatch(
      {
        httr::stop_for_status(resp)
        TRUE
      },
      error = function(e) {
        warning(sprintf("boc_fx_rss: HTTP error for '%s': %s", url, conditionMessage(e)))
        FALSE
      }
    )
    if (!ok) return(empty_fx_tbl(feed_series))

    xml_txt <- tryCatch(
      httr::content(resp, as = "text", encoding = "UTF-8"),
      error = function(e) {
        warning(sprintf("boc_fx_rss: failed reading response body for '%s': %s", url, conditionMessage(e)))
        return(NA_character_)
      }
    )
    if (is.na(xml_txt) || !nzchar(xml_txt)) return(empty_fx_tbl(feed_series))

    # graceful XML parsing errors (proposal #2)
    doc <- tryCatch(
      xml2::read_xml(xml_txt),
      error = function(e) {
        warning(sprintf("boc_fx_rss: XML parse failed for '%s': %s", url, conditionMessage(e)))
        return(NULL)
      }
    )
    if (is.null(doc)) return(empty_fx_tbl(feed_series))

    items <- xml2::xml_find_all(doc, ".//rss:item", ns = ns)

    if (length(items) == 0) {
      return(empty_fx_tbl(feed_series))
    }

    rows <- lapply(items, function(node) {
      item_about <- xml2::xml_attr(node, "rdf:about", ns = ns)
      if (is.na(item_about) || !nzchar(item_about)) {
        item_about <- xml2::xml_attr(node, "{http://www.w3.org/1999/02/22-rdf-syntax-ns#}about")
      }
      if (is.na(item_about) || !nzchar(item_about)) {
        item_about <- xml2::xml_attr(node, "about")
      }
      item_series <- parse_item_series(item_about)

      title <- xtext1(node, "./rss:title")
      link  <- xtext1(node, "./rss:link")
      desc  <- xtext1(node, "./rss:description")

      dc_date <- xtext1(node, "./dc:date")
      dc_date_utc <- parse_boc_datetime_utc(dc_date)

      country <- xtext1(node, ".//cb:country")

      value_txt <- xtext1(node, ".//cb:exchangeRate/cb:value")
      value <- suppressWarnings(as.numeric(value_txt))

      base_currency   <- xtext1(node, ".//cb:exchangeRate/cb:baseCurrency")
      target_currency <- xtext1(node, ".//cb:exchangeRate/cb:targetCurrency")
      rate_type       <- xtext1(node, ".//cb:exchangeRate/cb:rateType")

      obs_period <- xtext1(node, ".//cb:exchangeRate/cb:observationPeriod")
      observation_period_utc <- parse_boc_datetime_utc(obs_period)

      tibble::tibble(
        feed_series = if (is.null(feed_series) || !nzchar(feed_series)) NA_character_ else feed_series,
        item_series = item_series,
        title = title,
        link = link,
        description = desc,
        dc_date_utc = dc_date_utc,
        value = value,
        base_currency = base_currency,
        target_currency = target_currency,
        rate_type = rate_type,
        observation_period_utc = observation_period_utc,
        country = country
      )
    })

    dplyr::bind_rows(rows)
  }

  # Case A: series is empty -> fetch all in one request
  if (is.null(series) || length(series) == 0) {
    return(fetch_one_feed(NULL))
  }

  # Case B: multiple feeds
  stopifnot(is.character(series))

  n <- length(series)
  pb <- NULL
  if (isTRUE(progress) && n > 1) {
    pb <- utils::txtProgressBar(min = 0, max = n, style = 3)
    on.exit({
      try(base::close(pb), silent = TRUE)
      cat("\n")
    }, add = TRUE)
  }

  out <- vector("list", n)
  for (i in seq_along(series)) {
    out[[i]] <- fetch_one_feed(series[[i]])
    if (!is.null(pb)) {
      utils::setTxtProgressBar(pb, i)
      utils::flush.console()
    }
  }

  names(out) <- series

  if (isTRUE(concat)) return(dplyr::bind_rows(out))
  out
}

#' List available FX RSS series codes (from /valet/fx_rss)
#'
#' @return A tibble with available FX series IDs and basic metadata.
#' @export
boc_fx_rss_available <- function() {
  df <- boc_fx_rss(series = NULL, concat = TRUE, progress = FALSE)

  dplyr::filter(df, !is.na(item_series) & nzchar(item_series)) |>
    dplyr::distinct(
      item_series, target_currency, base_currency, rate_type, country,
      .keep_all = FALSE
    ) |>
    dplyr::mutate(
      pair = dplyr::if_else(
        !is.na(target_currency) & !is.na(base_currency),
        paste0(target_currency, "/", base_currency),
        NA_character_
      )
    ) |>
    dplyr::arrange(item_series)
}

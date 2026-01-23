library(purrr)
library(tibble)
library(dplyr)
#' List Bank of Canada Valet series
#'
#' @param as Return format. Either "json" or "df".
#' @param keyword Optional keyword to filter by id/label/description (case-insensitive).
#' @param limit Optional maximum number of rows to return (only applies when as = "df").
#'
#' @return If as = "json", the raw parsed JSON (list). If as = "df", a tibble with
#'   columns id, label, description, link.
#' @export
boc_list_series <- function(as = c("df", "json"), keyword = NULL, limit = NULL) {
  as <- match.arg(as)

  json <- boc_request("lists/series/json")
  if (as == "json") return(json)

  # Convert to tibble
  df <- purrr::imap_dfr(json$series, function(x, id) {
    tibble::tibble(
      id = id,
      label = if (!is.null(x$label)) x$label else NA_character_,
      description = if (!is.null(x$description)) x$description else NA_character_,
      link = if (!is.null(x$link)) x$link else NA_character_
    )
  })

  # Optional filter
  if (!is.null(keyword) && nzchar(keyword)) {
    kw <- keyword
    df <- dplyr::filter(
      df,
      grepl(kw, id, ignore.case = TRUE) |
      grepl(kw, label, ignore.case = TRUE) |
      grepl(kw, description, ignore.case = TRUE)
    )
  }

  # Optional limit
  if (!is.null(limit)) {
    limit <- as.integer(limit)
    if (!is.na(limit) && limit > 0) df <- utils::head(df, limit)
  }

  df
}

#' List Bank of Canada Valet groups
#'
#' @param as Return format. Either "json" or "df".
#' @param keyword Optional keyword to filter by id/label/description (case-insensitive).
#' @param limit Optional maximum number of rows to return (only applies when as = "df").
#' @param clean_description If TRUE, compress whitespace/newlines in description for nicer printing.
#'
#' @return If as = "json", the raw parsed JSON (list). If as = "df", a tibble with
#'   columns id, label, description, link.
#' @export
boc_list_groups <- function(as = c("df", "json"),
                            keyword = NULL,
                            limit = NULL,
                            clean_description = TRUE) {
  as <- match.arg(as)

  json <- boc_request("lists/groups/json")
  if (as == "json") return(json)

  df <- purrr::imap_dfr(json$groups, function(x, id) {
    desc <- if (!is.null(x$description)) x$description else NA_character_

    if (isTRUE(clean_description) && !is.na(desc)) {
      desc <- gsub("[\r\n\t]+", " ", desc)
      desc <- gsub("\\s{2,}", " ", desc)
      desc <- trimws(desc)
    }

    tibble::tibble(
      id = id,
      label = if (!is.null(x$label)) x$label else NA_character_,
      description = desc,
      link = if (!is.null(x$link)) x$link else NA_character_
    )
  })

  if (!is.null(keyword) && nzchar(keyword)) {
    kw <- keyword
    df <- dplyr::filter(
      df,
      grepl(kw, id, ignore.case = TRUE) |
      grepl(kw, label, ignore.case = TRUE) |
      grepl(kw, description, ignore.case = TRUE)
    )
  }

  if (!is.null(limit)) {
    limit <- as.integer(limit)
    if (!is.na(limit) && limit > 0) df <- utils::head(df, limit)
  }

  df
}

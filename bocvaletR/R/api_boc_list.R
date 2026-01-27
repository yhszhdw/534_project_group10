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

  # Graceful: request failure / non-JSON / HTTP errors, etc.
  json <- tryCatch(
    boc_request("lists/series/json"),
    error = function(e) {
      warning(sprintf("boc_list_series: request failed: %s", conditionMessage(e)))
      return(NULL)
    }
  )

  if (as == "json") return(json)

  empty_df <- tibble::tibble(
    id = character(),
    label = character(),
    description = character(),
    link = character()
  )

  if (is.null(json) || is.null(json$series) || !is.list(json$series) || length(json$series) == 0) {
    warning("boc_list_series: missing or empty `series` in response (service may be down or format changed).")
    df <- empty_df
  } else {
    # Convert to tibble (graceful per-element)
    one_row_safe <- function(x, id) {
      tryCatch(
        {
          if (is.null(x) || !is.list(x)) x <- list()
          tibble::tibble(
            id = id,
            label = if (!is.null(x$label) && nzchar(x$label)) x$label else NA_character_,
            description = if (!is.null(x$description) && nzchar(x$description)) x$description else NA_character_,
            link = if (!is.null(x$link) && nzchar(x$link)) x$link else NA_character_
          )
        },
        error = function(e) {
          warning(sprintf("boc_list_series: failed parsing series '%s': %s", id, conditionMessage(e)))
          tibble::tibble(id = id, label = NA_character_, description = NA_character_, link = NA_character_)
        }
      )
    }

    df <- purrr::imap_dfr(json$series, one_row_safe)
  }

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

  # Graceful: request failure / non-JSON / HTTP errors, etc.
  json <- tryCatch(
    boc_request("lists/groups/json"),
    error = function(e) {
      warning(sprintf("boc_list_groups: request failed: %s", conditionMessage(e)))
      return(NULL)
    }
  )

  if (as == "json") return(json)

  empty_df <- tibble::tibble(
    id = character(),
    label = character(),
    description = character(),
    link = character()
  )

  if (is.null(json) || is.null(json$groups) || !is.list(json$groups) || length(json$groups) == 0) {
    warning("boc_list_groups: missing or empty `groups` in response (service may be down or format changed).")
    df <- empty_df
  } else {
    one_row_safe <- function(x, id) {
      tryCatch(
        {
          if (is.null(x) || !is.list(x)) x <- list()

          desc <- if (!is.null(x$description) && nzchar(x$description)) x$description else NA_character_
          if (isTRUE(clean_description) && !is.na(desc)) {
            desc <- gsub("[\r\n\t]+", " ", desc)
            desc <- gsub("\\s{2,}", " ", desc)
            desc <- trimws(desc)
          }

          tibble::tibble(
            id = id,
            label = if (!is.null(x$label) && nzchar(x$label)) x$label else NA_character_,
            description = desc,
            link = if (!is.null(x$link) && nzchar(x$link)) x$link else NA_character_
          )
        },
        error = function(e) {
          warning(sprintf("boc_list_groups: failed parsing group '%s': %s", id, conditionMessage(e)))
          tibble::tibble(id = id, label = NA_character_, description = NA_character_, link = NA_character_)
        }
      )
    }

    df <- purrr::imap_dfr(json$groups, one_row_safe)
  }

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

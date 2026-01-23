#' Get Bank of Canada group details (metadata + series list)
#'
#' @param group Group ID (e.g. "FX_RATES_DAILY")
#' @param as Return format:
#'   - "list": list(group = <tibble>, series = <tibble>)
#'   - "series_df": only the series tibble (convenient for piping into boc_series)
#'   - "group_df": only the group metadata tibble
#'
#' @return A list or tibble(s) depending on `as`.
#' @export
boc_groups <- function(group, as = c("list", "series_df", "group_df")) {
  as <- match.arg(as)
  stopifnot(is.character(group), length(group) == 1)

  json <- boc_request(path = paste0("groups/", group, "/json"))
  gd <- json$groupDetails

  group_df <- tibble::tibble(
    group_id = if (!is.null(gd$name)) gd$name else group,
    label = if (!is.null(gd$label)) gd$label else NA_character_,
    description = if (!is.null(gd$description)) gd$description else NA_character_
  )

  gs <- gd$groupSeries
  series_df <- if (!is.null(gs) && length(gs) > 0) {
    purrr::imap_dfr(gs, function(x, sid) {
      tibble::tibble(
        id = sid,
        label = if (!is.null(x$label)) x$label else NA_character_,
        link  = if (!is.null(x$link))  x$link  else NA_character_
      )
    })
  } else {
    tibble::tibble(id = character(), label = character(), link = character())
  }

  if (as == "group_df") return(group_df)
  if (as == "series_df") return(series_df)

  list(group = group_df, series = series_df)
}

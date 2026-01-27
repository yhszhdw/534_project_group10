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

  group <- trimws(group)
  stopifnot(nzchar(group))

  empty_group_df <- function(gid) {
    tibble::tibble(
      group_id = gid,
      label = NA_character_,
      description = NA_character_
    )
  }

  empty_series_df <- function() {
    tibble::tibble(
      id = character(),
      label = character(),
      link = character()
    )
  }

  finish <- function(group_df, series_df) {
    if (as == "group_df") return(group_df)
    if (as == "series_df") return(series_df)
    list(group = group_df, series = series_df)
  }

  # Graceful: request failure / non-JSON / HTTP errors, etc.
  json <- tryCatch(
    boc_request(path = paste0("groups/", group, "/json")),
    error = function(e) {
      warning(sprintf("boc_groups: request failed for group '%s': %s", group, conditionMessage(e)))
      return(NULL)
    }
  )

  if (is.null(json) || is.null(json$groupDetails)) {
    warning(sprintf("boc_groups: missing groupDetails for group '%s' (group may not exist or response format changed)", group))
    return(finish(empty_group_df(group), empty_series_df()))
  }

  gd <- json$groupDetails

  group_df <- tibble::tibble(
    group_id = if (!is.null(gd$name) && nzchar(gd$name)) gd$name else group,
    label = if (!is.null(gd$label) && nzchar(gd$label)) gd$label else NA_character_,
    description = if (!is.null(gd$description) && nzchar(gd$description)) gd$description else NA_character_
  )

  gs <- gd$groupSeries
  if (is.null(gs) || length(gs) == 0 || !is.list(gs)) {
    series_df <- empty_series_df()
    return(finish(group_df, series_df))
  }

  # Graceful: per-series parsing; a single bad element won't crash everything
  one_row_safe <- function(x, sid) {
    tryCatch(
      {
        if (is.null(x) || !is.list(x)) x <- list()
        tibble::tibble(
          id = sid,
          label = if (!is.null(x$label) && nzchar(x$label)) x$label else NA_character_,
          link  = if (!is.null(x$link)  && nzchar(x$link))  x$link  else NA_character_
        )
      },
      error = function(e) {
        warning(sprintf("boc_groups: failed parsing series '%s' in group '%s': %s", sid, group, conditionMessage(e)))
        tibble::tibble(id = sid, label = NA_character_, link = NA_character_)
      }
    )
  }

  series_df <- purrr::imap_dfr(gs, one_row_safe)

  finish(group_df, series_df)
}

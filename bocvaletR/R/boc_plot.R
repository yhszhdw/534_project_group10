#' Plot Bank of Canada time series
#'
#' @param df A tibble returned by boc_series(concat = TRUE) OR
#'   a named list of tibbles returned by boc_series(concat = FALSE).
#' @param mode How to plot multiple series:
#'   - "auto" (default): single-series behaves like old boc_plot(); multi-series uses "overlay"
#'   - "overlay": all series on one axes (colored by series)
#'   - "facet": facet by series (one figure, many panels)
#'   - "separate": return a named list of ggplots (one per series)
#' @param na_rm Logical; if TRUE, drop rows with NA in date/value (default TRUE).
#' @param title Plot title. If NULL, use a sensible default.
#' @param xlab,ylab Axis labels.
#' @param legend Logical; show legend for overlay plots (default TRUE).
#' @return A ggplot object (mode = "auto"/"overlay"/"facet"),
#'   or a named list of ggplot objects (mode = "separate").
#' @export
boc_plot <- function(df,
                     mode = c("auto", "overlay", "facet", "separate"),
                     na_rm = TRUE,
                     title = NULL,
                     xlab = "Date",
                     ylab = "Value",
                     legend = TRUE) {

  mode <- match.arg(mode)

  is_df <- function(x) inherits(x, "data.frame")

  validate_one_tbl <- function(d, nm = NULL) {
    if (!is_df(d)) {
      stop("Input must be a data.frame/tibble, or a named list of them.", call. = FALSE)
    }

    required_cols <- c("date", "value")
    if (!all(required_cols %in% names(d))) {
      msg <- "Input data must contain columns: 'date' and 'value'."
      if (!is.null(nm)) msg <- paste0(msg, " Problem in series: ", nm)
      stop(msg, call. = FALSE)
    }

    if (!inherits(d$date, c("Date", "POSIXct", "POSIXt"))) {
      msg <- "date must be of class Date or POSIXct/POSIXt."
      if (!is.null(nm)) msg <- paste0(msg, " Problem in series: ", nm)
      stop(msg, call. = FALSE)
    }

    if (!is.numeric(d$value)) {
      msg <- "value must be numeric."
      if (!is.null(nm)) msg <- paste0(msg, " Problem in series: ", nm)
      stop(msg, call. = FALSE)
    }

    if (nrow(d) < 2) {
      msg <- "Need at least two observations to plot a time series."
      if (!is.null(nm)) msg <- paste0(msg, " Problem in series: ", nm)
      stop(msg, call. = FALSE)
    }

    d
  }

  normalize_to_long <- function(x) {
    # list input (concat = FALSE)
    if (is.list(x) && !is_df(x)) {
      if (length(x) == 0) stop("Input list is empty.", call. = FALSE)

      nms <- names(x)
      if (is.null(nms) || any(!nzchar(nms))) {
        nms <- paste0("series_", seq_along(x))
        names(x) <- nms
      }

      lst <- Map(function(d, nm) {
        d <- validate_one_tbl(d, nm)
        if (!("series" %in% names(d))) d$series <- nm
        d
      }, x, names(x))

      return(dplyr::bind_rows(lst))
    }

    # single tibble input (concat = TRUE)
    if (is_df(x)) {
      d <- validate_one_tbl(x)
      if (!("series" %in% names(d))) d$series <- "series_1"
      return(d)
    }

    stop("Input must be a tibble/data.frame or a named list of tibbles.", call. = FALSE)
  }

  df_long <- normalize_to_long(df)

  if (isTRUE(na_rm)) {
    df_long <- df_long[!is.na(df_long$date) & !is.na(df_long$value), , drop = FALSE]
  }
  if (nrow(df_long) < 2) stop("No sufficient non-missing observations to plot.", call. = FALSE)

  df_long$series <- as.character(df_long$series)
  n_series <- length(unique(df_long$series))

  # Backward-compatible default
  if (mode == "auto") {
    mode <- if (n_series <= 1) "single" else "overlay"
  }

  if (is.null(title)) {
    title <- if (n_series <= 1) "Bank of Canada Time Series" else "Bank of Canada Time Series (Multiple Series)"
  }

  make_old_single_plot <- function(d) {
    ggplot2::ggplot(d, ggplot2::aes(x = date, y = value)) +
      ggplot2::geom_line(color = "steelblue") +
      ggplot2::labs(title = title, x = xlab, y = ylab) +
      ggplot2::theme_minimal()
  }

  if (identical(mode, "single")) {
    d1 <- df_long[df_long$series == unique(df_long$series)[1], , drop = FALSE]
    validate_one_tbl(d1)
    return(make_old_single_plot(d1))
  }

  if (mode == "overlay") {
    if (n_series <= 1) return(make_old_single_plot(df_long))

    p <- ggplot2::ggplot(df_long, ggplot2::aes(x = date, y = value, color = series)) +
      ggplot2::geom_line() +
      ggplot2::labs(title = title, x = xlab, y = ylab, color = "Series") +
      ggplot2::theme_minimal()

    if (!isTRUE(legend)) p <- p + ggplot2::theme(legend.position = "none")
    return(p)
  }

  if (mode == "facet") {
    if (n_series <= 1) return(make_old_single_plot(df_long))

    return(
      ggplot2::ggplot(df_long, ggplot2::aes(x = date, y = value)) +
        ggplot2::geom_line(color = "steelblue") +
        ggplot2::facet_wrap(~ series, scales = "free_y") +
        ggplot2::labs(title = title, x = xlab, y = ylab) +
        ggplot2::theme_minimal() +
        ggplot2::theme(legend.position = "none")
    )
  }

  # mode == "separate"
  split_df <- split(df_long, df_long$series)
  plots <- lapply(names(split_df), function(nm) {
    d <- split_df[[nm]]
    validate_one_tbl(d, nm)
    ggplot2::ggplot(d, ggplot2::aes(x = date, y = value)) +
      ggplot2::geom_line(color = "steelblue") +
      ggplot2::labs(title = paste0(title, " - ", nm), x = xlab, y = ylab) +  # ASCII only
      ggplot2::theme_minimal()
  })
  names(plots) <- names(split_df)
  plots
}

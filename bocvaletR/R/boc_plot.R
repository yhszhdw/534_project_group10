#' Plot Bank of Canada time series
#'
#' @param df A tibble returned by boc_series()
#' @return A ggplot object
#' @export
boc_plot <- function(df) {

  # ---- Input validation ----
  if (!inherits(df, "data.frame")) {
    stop("df must be a data.frame or tibble.", call. = FALSE)
  }

  required_cols <- c("date", "value")
  if (!all(required_cols %in% names(df))) {
    stop(
      "df must contain columns: 'date' and 'value'.",
      call. = FALSE
    )
  }

  if (!inherits(df$date, c("Date", "POSIXct", "POSIXt"))) {
    stop(
      "df$date must be of class Date or POSIXct.",
      call. = FALSE
    )
  }

  if (!is.numeric(df$value)) {
    stop(
      "df$value must be numeric.",
      call. = FALSE
    )
  }

  if (nrow(df) < 2) {
    stop(
      "df must contain at least two observations to plot a time series.",
      call. = FALSE
    )
  }

  # ---- Plot ----
  ggplot2::ggplot(df, ggplot2::aes(x = date, y = value)) +
    ggplot2::geom_line(color = "steelblue") +
    ggplot2::labs(
      title = "Bank of Canada Time Series",
      x = "Date",
      y = "Value"
    ) +
    ggplot2::theme_minimal()
}

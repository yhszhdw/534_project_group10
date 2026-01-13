#' Plot Bank of Canada time series
#'
#' @param df A tibble returned by boc_series()
#' @return A ggplot object
#' @export
boc_plot <- function(df) {
  
  stopifnot(all(c("date", "value") %in% names(df)))
  
  ggplot2::ggplot(df, ggplot2::aes(x = date, y = value)) +
    ggplot2::geom_line(color = "steelblue") +
    ggplot2::labs(
      title = "Bank of Canada Time Series",
      x = "Date",
      y = "Value"
    ) +
    ggplot2::theme_minimal()
}

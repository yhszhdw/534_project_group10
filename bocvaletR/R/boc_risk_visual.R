# boc_risk_visual.R
# FX Risk Metrics and Visualization
# DATA 550 – Financial Visualization Standard

# ------------------------------------------------
# 1. Core risk metrics: Historical VaR & CVaR
# ------------------------------------------------

risk_var_cvar <- function(x, alpha = 0.05) {

  # ---- Input validation (explicit & early) ----
  if (!is.numeric(x)) {
    if (is.logical(x)) {
      x <- as.numeric(x)
    } else {
      stop("Input x must be a numeric vector.", call. = FALSE)
    }
  }

  if (length(x) < 2) {
    stop("Input x must contain at least two observations.", call. = FALSE)
  }

  if (all(is.na(x))) {
    stop("no valid observations", call. = FALSE)
  }

  if (!is.numeric(alpha) || length(alpha) != 1 || alpha <= 0 || alpha >= 1) {
    stop("alpha must be a single numeric value in (0, 1).", call. = FALSE)
  }

  # ---- Clean data ----
  x <- x[is.finite(x)]

  if (length(x) == 0) {
    stop("no valid observations", call. = FALSE)
  }

  # ---- Risk measures ----
  var  <- as.numeric(stats::quantile(x, probs = alpha, na.rm = TRUE))
  cvar <- mean(x[x <= var], na.rm = TRUE)

  list(
    var  = var,
    cvar = cvar
  )
}

# ------------------------------------------------
# 2. Visualization: VaR / CVaR (DATA 550 style)
# ------------------------------------------------

risk_plot_var_cvar <- function(x, alpha = 0.05, title = NULL) {

  stats <- risk_var_cvar(x, alpha)

  df <- data.frame(ret = x)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = ret)) +

    # Histogram: relative frequency
    ggplot2::geom_histogram(
      ggplot2::aes(y = after_stat(count / sum(count))),
      bins = 60,
      fill = "grey85",
      color = "white"
    ) +

    # Density curve (shape reference only)
    ggplot2::geom_density(
      ggplot2::aes(y = after_stat(scaled * 0.06)),
      color = "steelblue",
      linewidth = 1.2
    ) +

    # VaR line
    ggplot2::geom_vline(
      xintercept = stats$var,
      linetype = "dashed",
      linewidth = 1.2,
      color = "firebrick"
    ) +

    # CVaR line
    ggplot2::geom_vline(
      xintercept = stats$cvar,
      linewidth = 1.2,
      color = "darkred"
    ) +

    # Tail rug
    ggplot2::geom_rug(
      data = subset(df, ret <= stats$var),
      ggplot2::aes(x = ret),
      sides = "b",
      alpha = 0.35,
      color = "firebrick"
    ) +

    ggplot2::labs(
      title    = title %||% "Historical VaR / CVaR (FX Returns)",
      subtitle = paste0("Confidence level = ", 1 - alpha),
      x        = "Daily log return",
      y        = "Relative frequency"
    ) +

    ggplot2::theme_minimal(base_size = 14)

  list(
    plot = p,
    var  = stats$var,
    cvar = stats$cvar
  )
}

# ------------------------------------------------
# 3. Text summary
# ------------------------------------------------

risk_text_summary <- function(n, alpha, var, cvar) {

  if (!is.numeric(n) || n <= 0) {
    stop("n must be a positive integer.", call. = FALSE)
  }

  if (!is.numeric(alpha) || alpha <= 0 || alpha >= 1) {
    stop("alpha must be in (0, 1).", call. = FALSE)
  }

  if (!is.numeric(var) || !is.numeric(cvar)) {
    stop("var and cvar must be numeric.", call. = FALSE)
  }

  paste0(
    "Historical risk summary:\n",
    "- Sample size: ", n, "\n",
    "- VaR (", alpha * 100, "%): ", round(var, 6), "\n",
    "- CVaR (", alpha * 100, "%): ", round(cvar, 6), "\n\n",
    "Interpretation: VaR represents the return threshold that is exceeded ",
    "with probability ", alpha, ", while CVaR measures the average loss ",
    "conditional on returns falling below the VaR level."
  )
}



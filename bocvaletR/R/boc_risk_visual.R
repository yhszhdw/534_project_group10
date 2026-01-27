# boc_risk_visual.R
# FX Risk Metrics and Visualization
# DATA 550 – Financial Visualization Standard

# ------------------------------------------------
# 1. Core risk metrics: Historical VaR & CVaR
# ------------------------------------------------

risk_var_cvar <- function(x, alpha = 0.05) {
  stopifnot(is.numeric(x), length(alpha) == 1, alpha > 0, alpha < 1)
  
  x <- x[is.finite(x)]
  
  var  <- as.numeric(quantile(x, probs = alpha, na.rm = TRUE))
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
  
  p <- ggplot(df, aes(x = ret)) +
    
    # Histogram: relative frequency (NOT density)
    geom_histogram(
      aes(y = after_stat(count / sum(count))),
      bins = 60,
      fill = "grey85",
      color = "white"
    ) +
    
    # Density curve: shape reference only (scaled down)
    geom_density(
      aes(y = after_stat(scaled * 0.06)),
      color = "steelblue",
      linewidth = 1.2
    ) +
    
    # VaR line
    geom_vline(
      xintercept = stats$var,
      linetype = "dashed",
      linewidth = 1.2,
      color = "firebrick"
    ) +
    
    # CVaR line
    geom_vline(
      xintercept = stats$cvar,
      linewidth = 1.2,
      color = "darkred"
    ) +
    
    # Tail observations (rug, unambiguous)
    geom_rug(
      data = subset(df, ret <= stats$var),
      aes(x = ret),
      sides = "b",
      alpha = 0.35,
      color = "firebrick"
    ) +
    
    labs(
      title    = title %||% "Historical VaR / CVaR (FX Returns)",
      subtitle = paste0("Confidence level = ", 1 - alpha),
      x        = "Daily log return",
      y        = "Relative frequency"
    ) +
    
    theme_minimal(base_size = 14)
  
  list(
    plot = p,
    var  = stats$var,
    cvar = stats$cvar
  )
}

# ------------------------------------------------
# 3. Text summary (used in run_risk_analysis.R)
# ------------------------------------------------

risk_text_summary <- function(n, alpha, var, cvar) {
  
  stopifnot(
    is.numeric(alpha),
    is.numeric(var),
    is.numeric(cvar)
  )
  
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



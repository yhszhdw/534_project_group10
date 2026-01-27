# run_risk_analysis.R
# End-to-end FX VaR / CVaR analysis
# DATA 550 – final execution script

# --------------------------------------------------
# 0. Clean environment and load dependencies
# --------------------------------------------------


source("boc_request.R")
source("boc_series.R")
source("boc_risk_visual.R")

# --------------------------------------------------
# 1. Fetch FX data from Bank of Canada
# --------------------------------------------------

df <- boc_series("FXUSDCAD")

# Construct daily log returns
x <- na.omit(diff(log(df$value)))

# --------------------------------------------------
# 2. Risk parameters
# --------------------------------------------------

p <- 0.05   # 5% tail risk level

# --------------------------------------------------
# 3. Risk analysis + visualization
# --------------------------------------------------

res <- risk_plot_var_cvar(
  x,
  alpha = p,
  title = "FXUSDCAD Historical VaR / CVaR"
)

# Display plot
print(res$plot)

# --------------------------------------------------
# 4. Textual risk summary
# --------------------------------------------------

cat(
  "\n",
  risk_text_summary(
    n     = length(x),
    alpha = p,
    var   = res$var,
    cvar  = res$cvar
  ),
  "\n"
)



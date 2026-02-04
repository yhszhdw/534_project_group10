# Please see the PROOF_OF_GRADING_SCHEME.md for meeting all the scoring factors. Please see the PROOF_OF_CRAN_SUBMISSION.png for CRAN pulishment. The process requires manual review and may take up to 10 days. However, the package has already passed all the CRAN code check.

# bocvaletR

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold these standards.
See [CODE_OF_CONDUCT.md](/bocvaletR/inst/CODE_OF_CONDUCT.md) for details.

---

## An R Wrapper for the Bank of Canada Valet API

**bocvaletR** is a modern, tidyverse-oriented R package that provides
reliable, analysis-ready access to the
[Bank of Canada Valet API](https://www.bankofcanada.ca/valet/docs).

The package goes beyond basic API access by supporting **robust data
retrieval**, **time-series preprocessing**, and **publication-ready
visualization**, making it suitable for economists, data scientists, and
finance students working in reproducible R workflows.

---

## 1. Overview

The Bank of Canada Valet API offers programmatic access to hundreds of
official Canadian financial and economic time series, including exchange
rates, interest rates, and macroeconomic indicators.

While existing R clients for the Valet API focus primarily on raw data
retrieval, **bocvaletR** emphasizes:

- Reliability and consistent handling of API edge cases
- Tidy, analysis-ready outputs by default
- Seamless integration with tidyverse workflows
- Lightweight but practical tools for time-series analysis and visualization

The package is designed to support complete workflows from data discovery
to analysis and visualization.

---

## 2. Installation

### Development version

```r
install.packages(
  "https://github.com/yhszhdw/534_project_group10/releases/download/v1.0.0/bocvaletR_1.0.0.tar.gz",
  repos = NULL,
  type = "source"
)
```
## 3. Quick Start

### 3.1 Retrieve a single time series

```r
library(bocvaletR)

fx_usd <- boc_series("FXUSDCAD", start_date = "2023-01-01")
head(fx_usd)
```

### 3.2 Retrieve multiple series

```r
fx_multi <- boc_series(c("FXUSDCAD", "FXEURCAD"))
head(fx_multi)
```

### 3.3 Plot time series

```r
boc_plot(fx_usd)
boc_plot(fx_multi)                 # overlay
boc_plot(fx_multi, mode = "facet") # faceted comparison
```

## 4. Core Functionality

### 4.1 Data Retrieval

High-level functions wrap the core Valet API endpoints:

```r
boc_series()        # Retrieve one or more time series
boc_groups()        # Retrieve all series within a group
boc_list_series()   # List available series metadata
boc_list_groups()   # List available groups
```

These functions provide:

- Support for multiple series in a single call  
- Consistent date filtering  
- Tidy tibble outputs with stable column names  
- Informative error messages for invalid requests  

---

### 4.2 Time-Series Utilities

To support downstream analysis, bocvaletR includes helper functions for
common time-series operations:

```r
boc_fill_missing()     # Missing value handling (LOCF, interpolation)
boc_normalize()        # Normalization (z-score, min-max, index)
boc_percent_change()   # Arithmetic and log returns
boc_rolling_mean()     # Rolling averages
boc_summary()          # Summary statistics
boc_autocorr()         # Autocorrelation by series
boc_correlation()      # Cross-series correlation matrices
boc_align_fx_close()   # Time-zone aware FX close alignment
```
These helpers are designed to complement tidyverse tools rather than
replace them, enabling clear, readable, and reproducible analysis
pipelines.

### 4.3 Visualization

The package provides built-in visualization helpers for exploratory and
applied analysis:

```r
boc_plot()                # Time series visualization
risk_var_cvar()           # Historical VaR / CVaR computation
risk_plot_var_cvar()      # VaR / CVaR visualization
risk_text_summary()       # Textual interpretation of risk metrics
```

All plotting functions return ggplot2 objects and can be further
customized using standard ggplot2 layers.

## 5. Example: FX Risk Visualization

This example demonstrates a simple end-to-end risk analysis workflow
using daily foreign exchange data retrieved from the Bank of Canada
Valet API. The workflow follows the same design philosophy used
throughout bocvaletR: retrieve data, apply lightweight transformations,
and visualize results.

### 5.1 Retrieve FX data

We begin by retrieving a daily USD/CAD exchange rate series.

```r
fx <- boc_series("FXUSDCAD", start_date = "2023-01-01")
head(fx)
```

### 5.2 Compute daily log returns

Risk metrics are typically computed on returns rather than price levels.
Here we compute daily log returns using the built-in helper.

```r
fx_ret <- boc_percent_change(
  data      = fx,
  value_col = "value",
  type      = "log",
  order_col = "date",
  group_col = "series",
  new_col   = "log_ret"
)

ret <- fx_ret$log_ret
ret <- ret[is.finite(ret)]
length(ret)
```

### 5.3 Visualize VaR and CVaR

The historical Value-at-Risk (VaR) and Conditional VaR (CVaR) can be
computed and visualized directly from the return vector.

```r
vis <- risk_plot_var_cvar(ret, alpha = 0.05)
vis$plot
```

This plot shows the empirical return distribution with VaR and CVaR
overlaid as reference lines, highlighting downside tail risk.

## 6. Documentation

The package includes comprehensive documentation to support reproducible
and applied workflows.

Documentation resources include:

- **Function reference** generated via *roxygen2*, providing detailed
  descriptions of arguments, return values, and examples for all exported
  functions.
- **Vignettes** demonstrating complete workflows, including:
  - Data retrieval from the Bank of Canada Valet API
  - Data preprocessing and summarization
  - Time-series visualization and risk analysis

To explore the available vignettes, run:

```r
browseVignettes("bocvaletR")
```

## 7. Testing and Reliability

bocvaletR includes a comprehensive automated test suite to ensure
correctness, robustness, and long-term maintainability.

The testing strategy is built around **testthat** and **httptest2** and
includes:

- Mocked API responses to ensure tests are fast, reproducible, and
  independent of external network conditions
- Unit tests covering data retrieval, input validation, and error
  handling
- Explicit tests for known edge cases in Valet API behavior
- Continuous integration checks to prevent regressions as the codebase
  evolves

---

## 8. Project Status

This package was developed as part of an academic software engineering
and financial visualization project and is actively maintained.

Bug reports, feature requests, and contributions are welcome through the
project repository.

---

## 9. License

This project is licensed under the **MIT License**.

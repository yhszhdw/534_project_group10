# bocvaletR
## An R Wrapper for the Bank of Canada Valet API

---

## 1. Project Overview

This project proposes the development of **bocvaletR**, an R package that provides a modern, tidyverse-oriented wrapper for the Bank of Canada Valet API. The package is designed to allow R users to access official Canadian financial and economic time-series data through concise, well-documented functions, without manually constructing HTTP requests or parsing raw JSON responses.

While R packages that interface with the Valet API already exist, **bocvaletR** aims to go beyond basic data retrieval by focusing on **reliability, workflow integration, and analysis-ready outputs**. The target users include economists, data scientists, and finance students who rely on reproducible and efficient workflows in R for analysis and visualization.

---

## 2. Motivation and Background

The Bank of Canada Valet API provides authoritative, well-maintained financial and economic datasets such as exchange rates, interest rates, and macroeconomic indicators. These data are widely used in academic research, policy analysis, and applied data science.

Although existing R packages (e.g., community-developed Valet API clients) already provide access to this API, they have several limitations:

- They primarily focus on **basic data retrieval**, with limited support for downstream analysis workflows
- Some API behaviors (such as date filtering for grouped series) are **inconsistent or unreliable**, requiring users to manually clean results
- Limited tooling exists for **metadata exploration**, **series alignment**, and **workflow-level utilities**
- Visualization, caching, and reproducibility features are minimal or absent
- Documentation and examples tend to focus on API usage rather than applied analysis

As a result, users often need to write substantial additional code for validation, transformation, plotting, and repeated API calls.

**bocvaletR** is motivated by the goal of addressing these gaps. Rather than duplicating existing functionality, the package is designed to **extend and improve upon existing Valet API wrappers** by offering:

- More reliable and consistent handling of API edge cases
- Analysis-ready outputs that integrate naturally with tidyverse workflows
- Lightweight but high-impact utilities for common time-series tasks
- Clear documentation and vignettes that emphasize reproducible economic analysis

This approach makes the project both practically useful and well-suited as a course project demonstrating applied software engineering, API design, and data analysis principles.

---

## 3. Project Objectives

The primary goal is to design and implement a fully functional R package that improves upon existing Valet API wrappers by:

- Wrapping the core endpoints of the Bank of Canada Valet API
- Providing consistent and reliable data retrieval, including client-side fixes for known API limitations
- Returning data in tidy, analysis-ready formats by default
- Supporting common analytical workflows through helper utilities and visualization tools
- Following best practices for R package development, testing, and documentation

---

## 4. Package Design and Core Functionality

### 4.1 Data Retrieval Functions

The package will expose a small set of high-level functions for data access:

```r
boc_series()        # Retrieve one or more time series
boc_group()         # Retrieve all series within a group
boc_list()          # List available series or groups
boc_series_info()   # Retrieve metadata for a series
```

These functions will:

- Support date range filtering, including consistent client-side filtering when API behavior is unreliable
- Allow multiple series to be queried in a single call
- Return results as tidy tibbles with stable column names and types
- Validate inputs and handle API errors with clear, informative messages

A low-level internal function (`boc_request()`) will manage HTTP requests, retries, and response parsing.

### 4.2 Visualization Support

To support exploratory and applied analysis, the package will include lightweight plotting helpers:

```r
boc_plot()          # Single or multi-series time series plots
boc_plot_group()    # Grouped or faceted comparisons
```

These functions will return ggplot2 objects that are publication-ready by default but fully customizable by the user.

### 4.3 Basic Data Utilities

To move beyond simple data access, bocvaletR will include helper functions that support common time-series workflows:

```r
boc_normalize()        # Scaling and normalization (Z-score, percentage change)
boc_fill_missing()     # Missing value handling (LOCF, interpolation)
boc_summary()          # Descriptive statistics
boc_percent_change()   # Period-over-period percentage change
boc_rolling_mean()     # Rolling averages
boc_autocorr()         # Autocorrelation analysis
boc_correlation()      # Multi-series correlation matrices
```

These utilities are intentionally lightweight and designed to complement, not replace, existing tidyverse tools. Together, they distinguish bocvaletR from existing Valet API wrappers by supporting complete analysis workflows.

---

## 5. Technology Stack

The package will be implemented using modern R tooling:

| Component | Purpose |
|-----------|---------|
| **httr2** | HTTP requests and API handling |
| **dplyr, tibble** | Data manipulation |
| **ggplot2** | Visualization |
| **rlang** | Structured error handling |
| **roxygen2** | Documentation generation |
| **testthat** | Unit testing |
| **httptest2** | Mocking HTTP responses |

---

## 6. Documentation Plan

Documentation is a core component of the project and will include:

### 6.1 README
- Installation instructions
- Quick-start examples
- Overview of key differences from existing Valet API packages

### 6.2 Function Documentation
- Full roxygen2 documentation for all exported functions
- Executable examples demonstrating typical workflows

### 6.3 Vignettes
- **Basic Usage** – Accessing series and groups with tidy outputs
- **Advanced Workflows** – Reliable filtering, batch queries, and caching
- **Applied Example** – A reproducible economic analysis using real data

---

## 7. Testing Strategy

The package will include a comprehensive test suite:

- Unit tests for data retrieval, parsing, and validation
- Mocked API responses to ensure tests are fast and reproducible
- Explicit tests for known API edge cases (e.g., group date filtering)
- Target coverage of at least 80%

This strategy ensures correctness, robustness, and maintainability.

---

## 8. Expected Outcomes

By the end of the project, the team will deliver:

- A working R package that improves upon existing Bank of Canada Valet API wrappers
- Reliable, tidy, and analysis-ready data access tools
- Clear documentation and applied examples demonstrating real-world usage

The project will demonstrate strong software engineering practices while addressing a real need in the R ecosystem.

---

## 9. Conclusion

Although R packages for accessing the Bank of Canada Valet API already exist, they focus primarily on basic data retrieval. bocvaletR addresses this gap by emphasizing reliability, workflow integration, and analysis-ready tooling. By extending existing approaches rather than duplicating them, the project delivers practical value while remaining well-scoped for a course-based software development project.
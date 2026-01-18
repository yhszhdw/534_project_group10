# bocvaletR
## An R Wrapper for the Bank of Canada Valet API

---

## 1. Project Overview

This project proposes the development of **bocvaletR**, an R package that provides a clean and user-friendly wrapper for the Bank of Canada Valet API. The package aims to allow R users to access official Canadian financial and economic time-series data using concise, well-documented R functions, without manually constructing HTTP requests or parsing raw JSON responses.

The target users include economists, data scientists, and finance students who rely on reproducible workflows in R for data analysis and visualization.

---

## 2. Motivation and Background

The Bank of Canada Valet API offers authoritative and well-maintained financial datasets, including exchange rates and economic indicators. These data are widely used in academic research and policy analysis. However:

- The API is primarily designed for direct HTTP access
- There is no official R wrapper that integrates naturally with tidyverse workflows
- Users must repeatedly implement request handling, parsing, and validation logic

Developing an R wrapper addresses these issues by:

- **Reducing technical overhead** for users
- **Promoting reproducible** financial analysis in R
- **Providing a reusable**, extensible package aligned with modern R package standards

The API is also well suited for a course project: it is sufficiently complex to demonstrate software engineering skills while remaining feasible within a semester.

---

## 3. Project Objectives

The primary goal is to design and implement a fully functional R package that:

- Wraps the core endpoints of the Bank of Canada Valet API
- Returns data in tidy, analysis-ready formats
- Provides basic visualization and data processing helpers
- Includes documentation and tests following best practices for R packages

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

- Support date range filtering
- Allow multiple series to be queried at once
- Return results as tibbles
- Handle invalid inputs and API errors gracefully

A low-level internal function (`boc_request()`) will manage HTTP requests and response parsing.

### 4.2 Visualization Support

To support exploratory analysis, the package will include lightweight plotting helpers:

```r
boc_plot()          # Single or multi-series time series plots
boc_plot_group()    # Grouped or faceted comparisons
```

These functions will produce publication-ready ggplot2 objects while remaining fully customizable by the user.

### 4.3 Basic Data Utilities

Common time-series preparation tasks will be simplified through helper functions:

```r
boc_normalize()        # Scaling and normalization (Z-score, percentage change)
boc_fill_missing()     # Missing value handling (LOCF, interpolation)
boc_summary()          # Descriptive statistics
boc_percent_change()   # Period-over-period percentage change
boc_rolling_mean()     # Rolling average
boc_autocorr()         # Autocorrelation structure
boc_correlation()      # Multi-series correlation matrix
```

These utilities are intentionally lightweight and designed to complement existing tidyverse tools rather than replace them.

---

## 5. Technology Stack

The package will be implemented using modern R tooling:

| Component | Purpose |
|-----------|---------|
| **httr2** | HTTP requests |
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
- Overview of available functions

### 6.2 Function Documentation
- Full roxygen2 documentation for all exported functions
- Executable examples for each function

### 6.3 Vignettes (3)
1. **Basic Usage**: Introduction to the API wrapper with simple examples
2. **Advanced Querying**: Batch requests, caching, and best practices
3. **Applied Example**: A realistic economic analysis using real data

---

## 7. Testing Strategy

The package will include a comprehensive test suite:

- **Unit tests** for data retrieval, parsing, and validation
- **Mocked API responses** to ensure tests are fast and stable
- **Target coverage**: at least 80% code coverage

This ensures correctness, robustness, and maintainability.

---

## 8. Expected Outcomes

By the end of the project, the team will deliver:

- A working R package that wraps the Bank of Canada Valet API
- Clean, documented, and tested code following R package standards
- Example analyses demonstrating real-world usage

The project will demonstrate both software engineering practices and practical data analysis skills, aligning well with course learning objectives.

---

## 9. Conclusion

The proposed bocvaletR package addresses a real gap in the R ecosystem by providing convenient access to authoritative Canadian financial data. The project balances practical relevance with technical depth and offers a clear opportunity to apply API design, testing, and documentation principles in a realistic setting.
# bocvaletR - R Wrapper for Bank of Canada API | Project Proposal

---

## I. Project Overview

**Project Name**: bocvaletR - Bank of Canada Valet API R Language Wrapper  
**Selected API**: [Bank of Canada Valet API v1.0.1](https://www.bankofcanada.ca/valet/)  
**Team Size**: 3 members  
**Expected Duration**: 8 weeks  
**Target Audience**: Economists, Financial Analysts, Data Scientists, Policy Makers

---

## II. Project Background & Motivation

### 2.1 Why Choose This API?

1. **High Practical Value**
   - Bank of Canada Valet API provides official financial data (exchange rates, economic indicators, etc.)
   - Strong data credibility and trusted source
   - Widely used in academic research and financial analysis

2. **Excellent API Design**
   - Supports multiple endpoints: single series queries, group queries, list browsing, RSS feeds
   - Provides flexible date range filtering
   - Standard response format (JSON)

3. **Appropriate Development Complexity**
   - Not overly simple (avoiding meaningless exercises)
   - Not overly complex (achievable within the semester)
   - Covers typical API wrapping challenges: request building, response parsing, error handling, data wrangling

4. **Community Demand Exists**
   - Currently no official R language wrapper
   - Contributes to expanding R data science ecosystem
   - Can be contributed to ROpenSci community after completion

---

## III. Project Scope & Objectives

### 3.1 Core Goals

Completely wrap the Bank of Canada Valet API into a user-friendly R package, enabling users to fetch, organize, and visualize financial time series data through concise R functions without directly calling the API.

### 3.2 Expected Deliverables

| Category | Expected Outcomes |
|----------|------------------|
| **Code** | 7 R functions + complete test suite (>80% coverage)|
| **Documentation** | Complete README + function docs + 3 in-depth vignettes |
| **Testing** | Unit tests + integration tests + Mock tests |
| **Engineering** | GitHub workflow + CI/CD + community docs |
| **Optional** | CRAN/ROpenSci submission + pkgdown website |

---

## IV. Package Design & Architecture

### 4.1 Core API Functions (Data Fetching)

**Primary Functions for Data Acquisition**:
```r
boc_request()        # Internal: Low-level HTTP API call wrapper
boc_series()         # Fetch single/multiple time series data
boc_list()           # List all available series/groups
boc_series_info()    # Fetch series metadata information
boc_group()          # Batch fetch data by group (efficient for multi-series)
```

**Features**:
- Support for querying multiple series simultaneously
- Flexible date range filtering (start_date, end_date)
- Returns clean tibble format data
- Error handling and retry logic

### 4.2 Visualization Functions

**Plotting Tools**:
```r
boc_plot()           # Basic time series line plot
boc_plot_group()     # Multi-series comparison plots (faceting, custom themes)
```

**Features**:
- Clean, publication-ready default themes
- Customizable colors, labels, and styling
- Support for multiple series visualization

### 4.3 Data Processing & Utilities (Lightweight Analysis)

**Data Wrangling Functions** - Simplify common tasks without deep domain analysis:

#### 4.3.1 Normalization & Scaling
```r
boc_normalize()      # Standardize values (Z-score, min-max scaling, percentage change)
                     # Use case: Compare multiple series on same scale
```

#### 4.3.2 Missing Data Handling
```r
boc_fill_missing()   # Handle gaps in time series
                     # Methods: last observation carried forward (locf), 
                     #         linear interpolation, forward fill
                     # Use case: Prepare data for time series analysis
```

#### 4.3.3 Basic Summary & Exploration
```r
boc_summary()        # Quick statistical summary (mean, sd, min, max, etc.)
boc_percent_change() # Calculate period-over-period percentage change
boc_rolling_mean()   # Compute rolling average
boc_autocorr()       # Check autocorrelation structure
boc_correlation()    # Multi-series correlation matrix
```

**Design Philosophy**: These functions handle **generic data processing** tasks that 80% of users need. They integrate seamlessly with `dplyr`, `ggplot2`, and other tidyverse tools.

### 4.4 Internal Utilities

**Helper Functions**:
```r
boc_validate_date()     # Date format validation
boc_validate_series()   # Series ID verification
boc_cache_clear()       # Cache management
```

**Features**:
- Caching mechanism to avoid redundant API calls
- Friendly error messages and input validation
- Cross-platform support

---

## V. Technology Stack & Dependencies

### 5.1 Core Dependencies
- **httr2** - Modern HTTP request library (cleaner than httr)
- **dplyr** - Data manipulation and wrangling
- **ggplot2** - Plotting and visualization
- **tibble** - Modern data frame representation
- **rlang** - Elegant error handling

### 5.2 Development Tool Dependencies
- **roxygen2** - Automatic documentation generation
- **testthat** - Unit testing framework
- **httptest2/webmockr** - Mock HTTP requests (avoid frequent API calls)
- **covr** - Test coverage statistics
- **lintr + styler** - Code style checking and formatting

### 5.3 CI/CD Tools
- **GitHub Actions** - Automated testing and checks
- **pkgdown** - Auto-generate documentation website (optional)

---

## VI. Documentation Planning

### 6.1 README.md
- Package functionality overview
- Installation instructions (GitHub, CRAN)
- 5-minute quick start example
- API function reference table
- FAQ section
- Build status badges

### 6.2 Roxygen2 Function Documentation
- Complete `@param`, `@return`, `@examples` for each exported function
- Mark internal functions with `@keywords internal`
- Use `@seealso` to link related functions
- All example code must be executable

### 6.3 Vignettes (3 in-depth tutorials)

#### 6.3.1 bank-of-canada-api.Rmd (Basic Tutorial - existing draft)
**Theme**: From Zero to Graph - Complete Workflow  
**Content**:
- Bank of Canada Valet API introduction
- `boc_series()` basic usage
- `boc_plot()` plotting time series
- USD/CAD exchange rate example
- Complete flow from raw data to visualization

#### 6.3.2 advanced-queries.Rmd (Advanced Usage)
**Theme**: Efficient Data Queries & Batch Analysis  
**Content**:
- `boc_list()` data discovery
- `boc_group()` group batch query advantages
- Multi-series comparison analysis
- Caching mechanisms and performance optimization
- Handling API limits and best practices
- Error handling examples

#### 6.3.3 economic-analysis-example.Rmd (Application Case Study)
**Theme**: Real-World Financial Data Analysis  
**Content**:
- Canadian dollar depreciation trend analysis (multi-year historical data)
- Multi-currency exchange rate comparison (USD, EUR, GBP vs CAD)
- Economic indicator correlation analysis
- Result export and visualization
- Extension examples integrating other data sources

### 6.4 Inline Code Documentation
- Clear function descriptions at function head
- Step-by-step comments for complex logic
- Traceable API request URL building process
- Data transformation pipeline explanation

---

## VII. Testing Strategy

### 7.1 Unit Tests (tests/testthat/)

```r
test-boc_request.R
  ✓ API request URL construction
  ✓ Query parameter passing
  ✓ JSON response parsing
  ✓ Exception response handling

test-boc_series.R
  ✓ Single series data fetching
  ✓ Multi-series batch fetching
  ✓ Date range filtering
  ✓ Correct data structure return (tibble)
  ✓ Missing data handling

test-boc_list.R
  ✓ Series list querying
  ✓ Group list querying
  ✓ List format return

test-boc_group.R
  ✓ Group data fetching
  ✓ Multi-series handling within groups

test-boc_plot.R
  ✓ Plot object type
  ✓ Plot elements (title, axes)
  ✓ Multi-series plotting

test-utils.R
  ✓ Date format validation
  ✓ Series ID checking
  ✓ Error message format
```

### 7.2 Integration Tests

```r
test-error-handling.R
  ✓ Invalid series ID handling
  ✓ Network error handling and retry
  ✓ Unreasonable date range handling
  ✓ API rate limiting handling

test-cache.R
  ✓ Cache hit correctness
  ✓ Cache clearing functionality
```

### 7.3 Mocking & Fixtures
- Use `httptest2` or `webmockr` to mock API responses
- Store test data in `tests/fixtures/` directory
- Avoid frequent real API calls in unit tests (fast & stable)

### 7.4 Coverage Goals
- **Minimum Standard**: >80% code line coverage
- **Tool**: Measure with `covr` package
- **Report**: GitHub Actions auto-generates coverage report

---

## VIII. Package Maintainability & Best Practices

### 8.1 Error Handling Design

```r
# Input validation
if (!is.character(series)) {
  rlang::abort("series must be a character vector",
               class = "invalid_series_type")
}

# API error capture and retry
tryCatch(
  { resp <- httr2::req_perform(req) },
  error = function(e) {
    # Retry logic or graceful degradation
    rlang::abort(
      paste("API request failed:", e$message),
      class = "api_error"
    )
  }
)
```

### 8.2 Code Style
- Follow [tidyverse coding style guide](https://style.tidyverse.org/)
- Variable naming: `snake_case`
- Function naming: `snake_case` (verb + noun: `boc_request`, `boc_series`)
- Use `lintr` for checking + `styler` for auto-formatting

### 8.3 Dependency Management
- Specify dependency version ranges explicitly (DESCRIPTION)
- Minimize external dependencies (keep only essential ones)
- Regularly update and check compatibility

### 8.4 License Choice
- **Selected**: MIT License
- **Rationale**: Friendly, no license propagation requirement, allows commercial use

---

## IX. Community & Engineering Documentation

### 9.1 LICENSE (MIT License)
- Clearly state users can freely use, modify, and distribute
- Maintain copyright attribution

### 9.2 CODE_OF_CONDUCT.md
- Define expected team behavior standards
- Anti-harassment and inclusivity policy
- Violation reporting and handling process

### 9.3 CONTRIBUTING.md
**Workflow Definition**:
```
1. Fork project or create branch (naming: feature/xxx or fix/xxx)
2. Develop features on separate branches
3. Write unit tests (must pass)
4. Update relevant documentation
5. Submit Pull Request (with clear description)
6. Pass CI/CD checks and code review
7. Merge to develop branch
8. Periodic releases from develop to main
```

**Branching Strategy**:
```
main          ← Stable release version (with version tags)
  ↑
release-v0.x.x ← Release preparation
  ↑
develop       ← Integration branch (daily development)
  ↑
feature/*     ← Feature branches (per developer)
fix/*         ← Fix branches
docs/*        ← Documentation branches
```

### 9.4 .github/workflows/R-CMD-check.yml
**Automated Checks**:
- Run on every push and PR
- Execute `R CMD check` (standard R package check)
- Run all unit tests
- Generate code coverage report
- Support Windows/Mac/Linux matrix testing
- Auto-comment on PR failures

---

## X. Version Control & Release Strategy

### 10.1 Version Numbering (Semantic Versioning)
- **v0.1.0** - Basic functionality version (2 functions + tests + docs)
- **v0.2.0** - Enhanced version (add groups, lists, etc.)
- **v0.3.0** - Production stable version (complete docs + caching + error handling)
- **v1.0.0** - CRAN release version (all checks passing)

### 10.2 DESCRIPTION Update
```
Package: bocvaletR
Title: Bank of Canada Valet API R Wrapper
Version: 0.1.0
Authors@R: c(
  person("Member1", "Name1", role = c("aut", "cre"), email = "..."),
  person("Member2", "Name2", role = "aut"),
  person("Member3", "Name3", role = "aut")
)
Description: Wraps Bank of Canada Valet API as R package...
License: MIT + file LICENSE
Depends: R (>= 4.1.0)
Imports: httr2, dplyr, ggplot2, tibble, rlang
Suggests: testthat (>= 3.0.0), httptest2, knitr, rmarkdown
```

---

## XI. Daily Project Notebook (Individual Notebook)

**Requirement**: Each team member maintains a log in personal GitHub repo

**Log Format Example**:
```
【Date】2026-01-20

【Completed Tasks】
- Implemented boc_list() core logic
- Wrote test-boc_list.R unit tests (12 test cases)
- Updated NAMESPACE exports

【Issues Found】
- API returns duplicate series IDs, need handling
- Some series missing metadata, need defaults

【Technical Decisions】
Decision: Use file system caching instead of in-memory caching
Rationale: 
  - Support cross-session persistence
  - Users can clear cache
  - Avoid memory overflow (large datasets)

【Related Commits】
- bocvaletR@abc1234: feat: implement boc_list()
- bocvaletR@def5678: test: add test-boc_list.R
- Group10-nb@xyz9999: Update daily progress

【Next Steps】
- Write boc_list() integration tests
- Start boc_group() development
```

---

## XII. Expected Outcomes & Grading Alignment

### 12.1 Code Quality (25 points)
- ✅ 7 complete R functions with comprehensive API endpoint coverage
- ✅ Robust error handling (input validation, API exceptions, network failures)
- ✅ >80% test coverage with unit + integration tests
- ✅ Clear code comments for developer maintainability
- ✅ Cross-platform support (Windows/Mac/Linux)

### 12.2 Documentation & Writing (30+15 points)
- ✅ Complete README (installation, quick start, function table, FAQ)
- ✅ 3 in-depth Vignettes (basic, advanced, application case)
- ✅ Complete roxygen2 docs for all exported functions
- ✅ Detailed daily project notes with decision records and commit links
- ✅ Standard, readable code comments

### 12.3 Visualization (10 points)
- ✅ `boc_plot()` basic time series line plots
- ✅ `boc_plot_group()` multi-series comparison and faceted plots
- ✅ Vignettes include complete data-to-graph workflow
- ✅ Support customizable colors, themes, labels

### 12.4 Engineering & Collaboration (5+10+5 points)
- ✅ Standard GitHub workflow (branching, PRs, code review)
- ✅ CI/CD automation (GitHub Actions)
- ✅ All members show equal contribution through commit records
- ✅ CONTRIBUTING.md clearly defines workflow

### 12.5 Bonus Points (10 points optional)
- 🎯 **CRAN Submission**: Fully CRAN-compatible with passing checks
- 🎯 **ROpenSci Review**: Pass community peer review, enhance credibility
- 🎯 **pkgdown Website**: Auto-generated API documentation website
- 🎯 **Example Datasets**: Built-in common financial indicators

---

## XIII. Development Timeline

| Phase | Task | Weeks | Deliverables |
|-------|------|-------|-------------|
| 1 | Environment setup + Phase 2 function implementation | 1.5 | boc_list, boc_group, boc_series_info |
| 2 | Unit test writing | 1.5 | 8 test files, >80% coverage |
| 3 | Documentation & Vignettes | 1.5 | README + 3 Vignettes + roxygen2 docs |
| 4 | Integration tests + error handling enhancement | 1 | Integration tests, caching, retry logic |
| 5 | Code review + optimization | 1 | Code review, performance optimization, bug fixes |
| 6 | CRAN/ROpenSci submission (optional) | 1 | Submission + review feedback fixes |
| **Total** | | **~8 weeks** | |

---

## XIV. Risk & Mitigation Strategies

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| API changes/discontinuation | Low | Medium | Use mock tests, regularly check API docs |
| Team member time conflicts | Medium | Medium | Clear early task allocation, async collaboration |
| Requirement changes | Medium | Medium | Keep simple, prioritize core features |
| Testing difficulty | Low | Low | Use httptest2 mock, prepare fixtures beforehand |

---

## XV. Success Criteria

Project success is defined as:

1. **Complete Functionality** ✅
   - All planned functions implemented
   - All API endpoints covered
   - Robust error handling

2. **Quality Standards Met** ✅
   - R CMD check with no errors/warnings
   - Test coverage >80%
   - Cross-platform tests passing

3. **Sufficient Documentation** ✅
   - Clear, understandable README
   - Rich content in 3 Vignettes
   - Complete docs for all functions

4. **Standards-Compliant Collaboration** ✅
   - Standard git workflow
   - Equal member contributions
   - Detailed daily notebooks

5. **Community Ready** ✅ (optional)
   - Pass CRAN/ROpenSci review
   - pkgdown website published
   - Clear open-source license

---

## XVI. Reference Resources

- **R Packages**: https://r-pkgs.hadley.nz/
- **Tidyverse Style Guide**: https://style.tidyverse.org/
- **ROpenSci Best Practices**: https://devguides.ropensci.org/
- **httptest2**: Mock HTTP requests
- **Bank of Canada API Docs**: https://www.bankofcanada.ca/valet/docs

---

**Proposal Date**: January 17, 2026  
**Proposing Team**: Group 10  
**Project Status**: 🟢 Pending Approval, Ready to Start Development
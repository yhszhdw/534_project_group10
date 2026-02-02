# Development Log — bocvaletR

## Project Overview
**Project:** bocvaletR — R wrapper for the Bank of Canada Valet API  
**Start Date:** January 20  
**Focus:** JSON + FX RSS data access, robustness, testing, and CI

---

## January 20 — Project planning and API design framing

### Commits
- `9d419d9` — update the README
- `af97db4` — adding more for api
- `c8852f2` — Update README.md

### Work completed
- Established the initial project vision for **bocvaletR** as an R wrapper around the Bank of Canada Valet API
- Used the README as a planning and design document rather than purely user-facing documentation
- Defined the intended API surface, including:
  - Core data retrieval functions (series, groups, lists)
  - Separation between metadata endpoints and observation endpoints
  - Early consideration of extensibility (multiple series, filtering, future visualization)
- Clarified project scope and development direction before writing production code:
  - Focus on structured JSON access
  - Emphasis on clean, user-oriented function interfaces
  - Avoidance of premature optimization or over-engineering

### Notes
- No functional R code was added on this day
- README iterations reflect iterative design and API planning rather than implementation churn
- This day effectively served as a project kickoff and API contract draft

### Classification
- **Type:** Planning / Design / Documentation
- **Stage:** Project initialization
- **Design impact:** High

## January 22 — Core API implementation and data retrieval functions

### Commits
- `4229c6a` — data retrival functions

### Work completed
- Implemented the first complete set of **core API-facing functions** for bocvaletR
- Added foundational data retrieval capabilities covering both metadata and time-series observations
- Created and populated the following API modules:
  - `R/api_boc_fx_rss.R`
  - `R/api_boc_groups.R`
  - `R/api_boc_list.R`
  - `R/api_boc_series.R`
- Implemented main user-facing functions:
  - `boc_fx_rss()` — fetch latest FX rates from the Bank of Canada FX RSS feed
    - Examples: `boc_fx_rss()`, `boc_fx_rss("FXUSDCAD")`, `boc_fx_rss(c("FXUSDCAD", "FXAUDCAD"))`
  - `boc_fx_rss_available()` — list available FX RSS series IDs
  - `boc_groups()` — retrieve group metadata and associated series
  - `boc_list_series()` — list all available series metadata with optional keyword filtering
  - `boc_list_groups()` — list all available group metadata
  - `boc_series()` — retrieve time-series observations for one or multiple series
- Established consistent function structure and return formats across endpoints
- Aligned implementations with the API design planned earlier in the README

### Notes
- Primary focus was functional completeness rather than documentation or testing
- Error handling and robustness were minimal at this stage and planned for later iterations

### Classification
- **Type:** Feature development
- **Stage:** Core API implementation
- **Design impact:** High

---

## January 23 — Tutorial authoring and developer onboarding support

### Commits
- `d3ec151` — Create TUTORIAL.md
- `87d62c7` — Update TUTORIAL.md

### Work completed
- Created an initial **TUTORIAL.md** to document core bocvaletR workflows
- Added concise usage examples covering newly implemented API functions
- Documented expected input patterns and typical usage sequences to support:
  - Internal team understanding
  - Easier onboarding for other group members
  - Faster parallel development without repeatedly consulting source code
- Iteratively refined the tutorial to improve clarity and ordering of examples

### Notes
- Tutorial content prioritized developer usability over polished end-user prose
- This documentation served as a lightweight contract between implementation and future extensions

### Classification
- **Type:** Documentation / Developer support
- **Stage:** Early usability and collaboration
- **Design impact:** Medium

---

## January 25 — Error handling and robustness improvements

### Commits
- `c170d77` — Adding exception handlers

### Work completed
- Added structured **exception and error handling** across all API-facing functions
- Introduced `tryCatch`-based guards for:
  - Network request failures
  - JSON / XML parsing errors
  - Unexpected or malformed API responses
- Standardized failure behavior to ensure **consistent return types**:
  - Empty tibbles with predefined column structures
  - Predictable outputs even under error conditions
- Improved handling of edge cases involving:
  - Missing or incomplete fields
  - Empty API responses
  - Partial data availability
- Reduced noisy warnings caused by numeric coercion and incomplete records

### Outcome
- Core API functions became more resilient to unstable endpoints
- User-facing behavior remained predictable under failure scenarios
- Established a robustness baseline for later testing and CI integration

### Classification
- **Type:** Robustness / Error handling
- **Stage:** API hardening
- **Design impact:** Medium–High

---

## January 26 — Initial testing and CI setup (in progress)

### Commits
- `3bf91d6` — adding CI

### Work completed
- Implemented the first **unit test suite** targeting core internal functionality
- Added `testthat` tests for `boc_request()` covering:
  - Successful request paths
  - Expected failure and error scenarios
- Used **mocked HTTP responses** to isolate tests from external API availability
- Verified **local test coverage** for `boc_request()` met the ≥ 80% requirement
- Began configuring **GitHub Actions** for automated `R CMD check`

### Current status
- `boc_request()` tests pass locally
- Coverage confirmed in the local development environment
- CI workflow configuration present but **not yet passing** in GitHub Actions

### Notes
- CI failures at this stage were expected due to incomplete environment setup
- Test coverage was intentionally limited to `boc_request()` as a foundation for later expansion

### Classification
- **Type:** Testing / CI infrastructure
- **Stage:** CI bootstrap
- **Design impact:** Medium

---

## January 27 — CI debugging, test expansion, and stabilization

### Commits
- `251b6a8`, `7cf485e` — debugging
- `183ffec` — changing license
- `3519c86` — Update boc_risk_visual.R
- `34f8e4f`, `2cc29d3` — Update DESCRIPTION
- `69f2773`, `f702c16` — Update R-CMD-check.yaml
- `af0fab5` — debug
- `1671354` — Merge branch 'main'
- `5a70145` — testing test
- `f750e86` — new test file
- `eeea3a8` — confirming test run
- `49b4c0b` — documentation
- `7107bfa` — adding all api tests

### Work completed
- Focused on **making the CI pipeline pass reliably** and aligning it with local development
- Iteratively debugged failing GitHub Actions runs by:
  - Fixing test execution issues and skipped tests
  - Resolving environment and dependency mismatches
  - Updating `R-CMD-check.yaml` to ensure consistent CI behavior
- Expanded the test suite to cover **all API-facing functions**, including:
  - Metadata endpoints
  - Time-series retrieval functions
  - FX RSS-related functionality
- Added and validated new test files, confirming that:
  - Tests execute correctly in CI
  - Mocked HTTP requests behave consistently across environments
- Updated package metadata and configuration:
  - Adjusted `DESCRIPTION` to satisfy R CMD check requirements
  - Updated license information to ensure compliance
- Performed targeted documentation updates to reflect the stabilized API and test coverage

### Outcome
- All API-related tests now pass both locally and in CI
- GitHub Actions workflow runs successfully on push and pull requests
- CI environment is fully aligned with the local setup
- Established a stable foundation for final checks and package release preparation

### Classification
- **Type:** Debugging / Testing / CI stabilization
- **Stage:** Pre-release hardening
- **Design impact:** High

---

## January 29 — CI debugging and test execution fixes

### Commits
- `6056a0a`, `03e7ccd`, `067efbc` — debugging
- `9931652` — updating api request
- `d9447f8` — Add end-to-end vignette, risk visualization, and tests  
*(Commits related purely to devlog location or devlog content updates are intentionally excluded.)*

### Work completed
- Focused on **diagnosing false-positive CI passes** caused by improperly executed tests
- Identified and fixed an issue in `test_boc_request.R` where:
  - Tests were being silently skipped
  - CI appeared to pass despite tests not actually running
- Corrected test configuration to ensure:
  - All tests execute as intended under `testthat`
  - CI results accurately reflect test outcomes
- Performed additional debugging and minor API request adjustments to align behavior between:
  - Local test runs
  - GitHub Actions CI environment
- Validated fixes by re-running tests locally and confirming correct execution in CI

### Outcome
- Eliminated misleading CI success states caused by skipped tests
- Restored trust in CI feedback and test coverage signals
- Improved overall reliability of the testing and validation workflow

### Classification
- **Type:** Debugging / Testing
- **Stage:** CI correctness and validation
- **Design impact:** Medium

---

## January 30 — CRAN readiness, R CMD check, and release preparation

### Commits
- `5c2471b` — checking and passing CRAN check
- `300633b` — init package repo for rhub
- `a68550d` — debugging
- `b6aa5d1` — adding data retrieval vignettes
- `37029ab` — change summary: add risk_var_cvar function and related documentation
- `64e09f9` — added exception for bocvaletR directory for boc_utils

### Work completed
- Focused on **making the package CRAN-ready** and ensuring clean `R CMD check` results
- Ran and passed `devtools::check()` locally with:
  - No errors
  - No warnings
  - No notes
- Initialized **r-hub configuration** to validate package behavior across multiple platforms
- Performed final rounds of debugging to resolve remaining check issues
- Added and refined **vignettes** documenting data retrieval workflows to meet CRAN documentation expectations
- Integrated **risk analysis functionality**:
  - Implemented `risk_var_cvar()` for historical VaR and CVaR computation
  - Added accompanying documentation and examples
- Addressed remaining edge cases and exceptions in internal utilities to satisfy CRAN robustness requirements

### Outcome
- Package successfully passes local and CI-based `R CMD check`
- Documentation and vignettes meet CRAN submission standards
- Codebase stabilized and feature-complete for initial release submission

### Classification
- **Type:** Debugging / Documentation / Release preparation
- **Stage:** CRAN readiness
- **Design impact:** High

---

## January 31 — Documentation finalization and CRAN submission

### Commits
- `6029df0` — cran submission
- `e345d91` — debugging and building package
- `78d6d95` — building package
- `ebc50d5` — adding author
- `1bddfa2` — publish
- `27406ba` — preparing for publish
- `695602c` — removing unnecessary document
- `98da18e` — changing log name
- `64fe5a1` — Delete TUTORIAL.md
- `5d2c0f1` — adding data process vignettes
- `69cb55b` — Adding code of conduct
- `eb5f76b` — Merge branch 'main'
- `b8e8811` — debugging

### Work completed
- Finalized **user-facing documentation** through new and revised vignettes:
  - Added end-to-end data retrieval, preprocessing, and summary workflows
  - Consolidated earlier tutorial content into CRAN-compliant vignettes
- Cleaned and reorganized repository documentation:
  - Removed redundant or non-CRAN-compliant documents
  - Renamed and standardized development log files
  - Added a Code of Conduct for community and CRAN requirements
- Performed final **build and debugging cycles** to ensure:
  - Package builds cleanly from source
  - All checks pass prior to submission
- Finalized package metadata:
  - Added author information
  - Prepared release versioning (`v0.9.0`)
- Submitted **bocvaletR v0.9.0** to CRAN after completing all required checks

### Outcome
- Package successfully built and submitted to CRAN
- Documentation and vignettes aligned with CRAN standards
- bocvaletR entered CRAN review process pending feedback

### Classification
- **Type:** Documentation / Release
- **Stage:** CRAN submission
- **Design impact:** High

---

## February 1 — Visualization expansion and documentation finalization

### Commits
- `753ca99` — upgrading boc_plot, adding vignettes
- `bff519d` — debugging
- `cd9f721` — Delete risk_plot.png

### Work completed
- Expanded the **visualization layer** of bocvaletR with a major upgrade to plotting functionality
- Enhanced `boc_plot()` to support flexible multi-series visualization:
  - Added support for both concatenated and non-concatenated (`concat = FALSE`) outputs from `boc_series()`
  - Implemented multiple display modes: `auto`, `overlay`, `facet`, and `separate`
  - Preserved backward compatibility with earlier single-series usage
  - Improved input validation and handling of missing values in plotting workflows
- Implemented **risk visualization utilities** for applied financial analysis:
  - Added historical VaR and CVaR computation via `risk_var_cvar()`
  - Implemented visual summaries using `risk_plot_var_cvar()`
  - Added text-based interpretation via `risk_text_summary()`
  - Demonstrated end-to-end FX risk analysis workflows using Bank of Canada data
- Added and refined **vignettes** documenting:
  - Time-series visualization with `boc_plot()`
  - Integrated data preprocessing, transformation, and plotting pipelines
  - Applied FX risk visualization using VaR and CVaR
- Removed generated image artifacts from the repository to keep the package clean and CRAN-friendly

### Outcome
- Visualization and risk analysis features fully implemented
- Documentation (README, vignettes, and function references) aligned with the finalized API
- Package feature set completed for the initial public release

### Classification
- **Type:** Feature development / Documentation
- **Stage:** Feature completion
- **Design impact:** High

  higher-frequency data support)

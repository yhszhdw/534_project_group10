# Proof of Grading Scheme — bocvaletR

This document maps each grading criterion to concrete evidence in the
repository to facilitate transparent and efficient grading.

## 1. Core Goal: R Package Wrapping a RESTful API (Software requirements — code)

**Requirement (from grading scheme):**  
The goal of the package is to wrap a web RESTful API into a set of R functions and
offer a package for others to use those functions. Functions should perform the
minimum necessary data wrangling to return viable data formats.

---

### API Selection

- **API name:** Bank of Canada Valet API  
- **Official documentation:**  
  https://www.bankofcanada.ca/valet/docs  
- **Description:**  
  A public RESTful API provided by the Bank of Canada for accessing economic and
  financial time-series data, metadata, and foreign exchange rates.

The API is publicly accessible, well-documented, and does not require user
authentication, making it suitable for a reusable R wrapper.

---

### API Wrapping Functions

The package wraps the Valet API into a coherent set of user-facing R functions,
including (non-exhaustive list):

- `boc_request()` — internal request handler for REST endpoints
- `boc_series()` — retrieve time-series observations
- `boc_list_series()` — retrieve series metadata
- `boc_groups()` — retrieve group metadata and associated series
- `boc_list_groups()` — list available data groups
- `boc_fx_rss()` — retrieve foreign exchange rates from the Bank of Canada FX RSS feed
- `boc_fx_rss_available()` — list available FX RSS series

These functions abstract away URL construction, request handling, and response
parsing, allowing users to interact with the API using idiomatic R interfaces.

---

### Data Wrangling and Output Format

- All user-facing API functions return **structured tabular outputs**
  (`data.frame` / `tibble`)
- Raw JSON or XML responses from the API are parsed and minimally transformed to:
  - Normalize field names
  - Convert values to appropriate R types
  - Ensure consistent column structure across related functions

This ensures outputs are immediately usable for downstream analysis and
visualization.

---

### Separation of Package Logic vs. Vignette Examples

- **General-purpose wrangling** (API requests, parsing, normalization) is
  implemented directly in the package code (`R/` directory)
- **Workflow-specific transformations and examples** are demonstrated in
  vignettes rather than embedded in the core API

Detailed examples of data retrieval and usage can be accessed after installation
via:

- `vignette("bocvaletR-data-retrieval", package = "bocvaletR")`

This separation follows best practices for reusable API packages.

---

### Verification Steps for Grader

1. Install the package from source
2. Load the package: `library(bocvaletR)`
3. Run a representative API call, e.g.:
   - `boc_series("FXUSDCAD")`
   - `boc_list_groups(limit = 5)`
4. Confirm returned objects are data frames / tibbles
5. Open the data retrieval vignette to inspect documented workflows

## 2. Error Handling, Testing, and Continuous Integration (Software requirements — code)

**Requirement (from grading scheme):**  
- functions should handle errors gracefully  
- have unit and integration tests  
- use GitHub Actions for continuous integration (with a passing build stamp in the README)

---

### Error Handling (Graceful Failures)

- All user-facing functions include structured error handling using `error` / `warning`
  patterns to prevent hard crashes under common failure scenarios (e.g., network issues,
  malformed API responses, missing fields).
- Error paths are covered by automated tests to ensure predictable behavior.

---

### Unit / Integration Testing

- Comprehensive test suite implemented using **testthat**
- Test coverage exceeds **80%** overall (many components are **90%+**)
- Tests cover:
  - successful API responses
  - edge cases and malformed/empty responses
  - expected failure conditions and error messaging
  - core utilities and user-facing workflows where applicable

---

### Test Coverage Evidence

- Test coverage was measured using the **covr** package.
- Overall package coverage: **92.63%**, exceeding the required 80% threshold.

**Per-file coverage highlights:**
- `R/api_boc_series.R`: 84.51%
- `R/api_boc_fx_rss.R`: 88.02%
- `R/api_boc_list.R`: 94.12%
- `R/api_boc_groups.R`: 96.72%
- `R/api_boc_request.R`: 98.00%
- `R/boc_plot.R`: 93.00%
- `R/boc_risk_visual.R`: 92.31%
- `R/boc_utils.R`: 96.51%

Coverage results confirm that core API functions, internal utilities, and
user-facing workflows are extensively tested.

**Verification steps for grader:**
- Run `covr::package_coverage()` from the package directory
- Confirm reported coverage exceeds 80%


### Mocked HTTP (No External Dependency)

- API-related tests use **mocked HTTP responses** to avoid reliance on external
  services and ensure deterministic test outcomes in CI.

---

### Continuous Integration (GitHub Actions)

- Automated checks are executed via **GitHub Actions** (R CMD check workflow)
- CI runs on pushes / pull requests and confirms tests pass consistently
- Evidence: see repository GitHub Actions workflow runs and status records

## 3. Documentation & Vignettes (Docs and vignettes — writing:30, mechanics:10, viz:10)

**Requirement (from grading scheme):**  
- Documentation must be complete and readable  
- At least one vignette should illustrate most (if not all) package functionality  
- A hard requirement is a workflow that goes from data retrieval to visualization  
- Vignettes must include plotting (“zero → graph”)

---

### Function-Level Documentation (roxygen2)

- All exported user-facing functions are documented using **roxygen2**
- Corresponding `.Rd` files are generated and stored under `man/`
- Documented functions include API access, data processing, visualization, and risk analysis utilities, for example:
  - API & retrieval: `boc_series()`, `boc_groups()`, `boc_list_series()`, `boc_fx_rss()`
  - Processing & summaries: `boc_fill_missing()`, `boc_percent_change()`, `boc_summary()`
  - Visualization & risk analysis: `boc_plot()`, `risk_var_cvar()`, `risk_plot_var_cvar()`

This ensures users can access help pages via `?function_name` for all major functionality.

---

### README Documentation

- A project-level `README.md` provides:
  - An overview of the package purpose
  - Installation instructions
  - Basic usage examples demonstrating core API functionality
- The README serves as a quick entry point for new users prior to consulting vignettes.

---

### Vignettes Overview

The package includes multiple vignettes, each targeting a distinct aspect of the workflow:

- **`bocvaletR-data-retrieval.Rmd`**  
  Documents all data retrieval functionality, including interaction with the Bank of Canada Valet API and FX RSS endpoints.

- **`bocvaletR-data-visualization.Rmd`**  
  Focuses on visualization and risk analysis, covering plotting utilities and VaR/CVaR-based risk visualization.

- **`bocvaletR-data-process-and-summary.Rmd`**  
  Demonstrates data preprocessing, transformation, and summary statistics functions.

- **`full_bocvaletR_demo_WEILI.Rmd`**  
  Provides a complete end-to-end workflow, integrating data retrieval, processing, visualization, and risk analysis.

---

### Zero-to-Graph Requirement (Hard Requirement)

- The **visualization and demo vignettes** explicitly demonstrate a full workflow:
  1. Retrieve data from the Bank of Canada API
  2. Perform preprocessing and transformations
  3. Generate plots using package visualization functions
  4. Apply and visualize risk metrics (VaR / CVaR)

This satisfies the requirement to show a reproducible workflow from raw data to graphical output.

---

### Verification Steps for Grader

1. Install the package from source
2. Run `vignette(package = "bocvaletR")`
3. Open any vignette, for example:
   - `vignette("bocvaletR-data-visualization", package = "bocvaletR")`
4. Confirm presence of narrative text, code examples, and generated plots

## 4. Individual Notebook / Daily Project Log (Notebook — writing:15, mechanics:5)

**Requirement (from grading scheme):**  
Each group member must maintain an individual daily project notebook documenting
their contributions, development decisions, and evidence of work (e.g., commit links).

---

### Individual Development Logs

Each group member created and maintained an individual development log documenting
daily work and contributions:

- `DEVLOG_Zihao_Sheng.md`
- `DEVLOG_Wei_Li.Rmd`
- `DEVLOG_Inara.Rmd`

These logs are maintained in each contributor’s GitHub repository and updated
throughout the project timeline.

---

### Content of the Development Logs

Each development log includes:

- **Daily entries** summarizing work completed
- Clear description of each task’s role within the overall group project
- **Links to GitHub commits** as evidence of contribution
- Documentation of **development decisions**, including rationale for design
  choices (e.g., API design, testing strategies, CI configuration)

This structure aligns with the requirement for a computational/dry lab notebook
and supports transparency and reproducibility of individual contributions.

---

### Verification Steps for Grader

1. Navigate to each contributor’s repository
2. Open the corresponding `DEVLOG_*.md` / `DEVLOG_*.Rmd` file
3. Confirm daily entries, commit references, and documented decisions

## 5. Collaboration Mechanics and Workflow Proof

**Requirement (from grading scheme):**  
- Include a contributions document outlining team workflow  
- Demonstrate via Git history that the proposed workflow was followed  
- Show evidence that all group members contributed meaningfully and comparably

---

### Contribution and Governance Documents

The repository includes all required collaboration and governance documents at
the project root:

- `CONTRIBUTING.md` — outlines expected workflow practices and contribution process
- `CODE_OF_CONDUCT.md` — defines behavioral expectations for contributors
- `LICENSE` — specifies usage and redistribution terms
- `README.md` — provides project overview and usage instructions

These documents establish clear expectations for collaboration, conduct, and reuse.

---

### Team Workflow and Responsibilities

The project was developed collaboratively by three contributors, each of whom
maintained responsibility for specific components of the package. Responsibilities
were distributed across core functional areas, including:

- **Data retrieval and API interaction**
- **Data preprocessing and summary utilities**
- **Visualization and risk analysis components**
- **Testing and maintenance of assigned modules**

Each contributor was responsible not only for implementation, but also for
documentation updates and test coverage related to their assigned components.

---

### Evidence of Balanced Contributions

- Git commit history shows consistent contributions from all three team members:
  - Zihao Sheng
  - Wei Li
  - Inara
- Contributions span the full project lifecycle, including feature development,
  testing, debugging, documentation, and refinement.
- Each contributor maintained an individual development log documenting daily work:
  - `DEVLOG_Zihao_Sheng.md`
  - `DEVLOG_Wei_Li.Rmd`
  - `DEVLOG_Inara.Rmd`

These logs include summaries of work performed, links to relevant commits, and
documentation of development decisions, providing transparent evidence of
individual effort and contribution balance.

---

### Workflow Compliance

- Development followed the collaboration practices described in `CONTRIBUTING.md`
- Changes were introduced incrementally and integrated through Git-based workflows
- Commit history reflects frequent, meaningful commits rather than monolithic updates

Overall, the Git history and accompanying documentation demonstrate that the
proposed workflow was followed and that contributions were distributed equitably
among team members.

---

### Verification Steps for Grader

1. Review `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` in the repository root
2. Inspect the GitHub commit history and contributor list
3. Cross-reference commits with individual development logs

## Bonus — Go Public and Open Source (spark:10)

**Requirement (from grading scheme):**  
Go public and let other people use and contribute to your package (e.g., public
GitHub repository, CRAN / ROpenSci submission).

---

### Public Repository and Open-Source Setup

- The project is hosted in a **public GitHub repository**, allowing external users
  to view, install, and contribute to the package.
- The repository includes standard open-source governance files:
  - `LICENSE`
  - `CODE_OF_CONDUCT.md`
  - `CONTRIBUTING.md`
- GitHub Releases are used to distribute installable source tarballs.

This setup enables transparent collaboration and reuse beyond the course context.

---

### CRAN Submission Status

- The package **bocvaletR** has been formally submitted to CRAN.
- The submission has successfully passed **CRAN automated checks** and is currently
  **pending manual review** by the CRAN team.

CRAN auto-check confirmation (excerpt):

- Package: `bocvaletR_0.9.2.tar.gz`
- Status: Auto-processed, pending manual inspection
- Platforms checked:
  - Windows (r-devel): NOTE
  - Debian Linux (r-devel): NOTE
- No errors or warnings reported
- No strong reverse dependencies detected

This demonstrates that the package meets CRAN’s technical and structural
requirements and is suitable for public distribution.

---

### Significance for the Project

By making the repository public and submitting the package to CRAN, the project
goes beyond the minimum requirements of the assignment and demonstrates:

- Real-world package engineering practices
- Compliance with community standards
- Readiness for external users and contributors

This fulfills the optional “Go public” component of the project.

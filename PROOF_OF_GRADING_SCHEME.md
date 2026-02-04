# Proof of Grading Scheme — bocvaletR (Condensed)

This document maps each grading criterion to concrete evidence in the repository for fast and transparent grading.

---

## 1. Core Goal: R Package Wrapping a RESTful API (Code)

**Requirement:** Wrap a RESTful API into reusable R functions; return minimally-wrangled, usable outputs.

- **API:** Bank of Canada Valet API  
  Docs: https://www.bankofcanada.ca/valet/docs
- **Key wrapper functions (user-facing):**
  - `boc_series()` — time-series observations
  - `boc_list_series()` — series metadata
  - `boc_groups()` — group metadata + series in group
  - `boc_list_groups()` — list groups
  - `boc_fx_rss()` — FX RSS rates (RDF/XML)
  - `boc_fx_rss_available()` — available FX RSS series
- **Internal request handler:** `boc_request()` (URL construction, request, parse)
- **Outputs:** All user-facing retrieval functions return `data.frame` / `tibble`
- **Separation of concerns:** API logic in `R/`; extended workflows in vignettes

**Verify (example calls):**
- library(bocvaletR)
- boc_series("FXUSDCAD")
- boc_list_groups(limit = 5)

---

## 2. Error Handling, Testing, Continuous Integration (Code)

**Requirement:** Graceful errors, tests, CI (GitHub Actions) with passing status.

- **Error handling:** Consistent `error` / `warning` behavior for common failures (network, empty/malformed responses)
- **Tests:** `testthat` suite covering success + edge/failure paths
- **Mocked HTTP:** API tests rely on mocked responses (deterministic CI; no external dependency)
- **Coverage:** Overall **92.63%** via `covr` (≥ 80% requirement met)

**Coverage highlights (examples):**
- `R/api_boc_series.R`: 84.51%
- `R/api_boc_fx_rss.R`: 88.02%
- `R/api_boc_list.R`: 94.12%
- `R/api_boc_groups.R`: 96.72%
- `R/api_boc_request.R`: 98.00%
- `R/boc_plot.R`: 93.00%
- `R/boc_risk_visual.R`: 92.31%
- `R/boc_utils.R`: 96.51%

- **CI:** GitHub Actions runs R CMD check on push/PR; README shows build status badge

**Verify:**
- covr::package_coverage()

---

## 3. Documentation & Vignettes (Zero → Graph)

**Requirement:** Complete documentation; at least one vignette demonstrating data retrieval → visualization (hard requirement).

- **Function docs:** roxygen2 docs for exported functions; generated `.Rd` under `man/`
- **README:** overview + install + quick usage
- **Vignettes included:**
  - `bocvaletR-data-retrieval.Rmd` — retrieval functions (Valet API + FX RSS)
  - `bocvaletR-data-visualization.Rmd` — plotting + VaR/CVaR visualization
  - `bocvaletR-data-process-and-summary.Rmd` — preprocessing + summaries
  - `full_bocvaletR_demo_WEILI.Rmd` — end-to-end workflow

- **Zero → graph evidence:** Visualization + demo vignettes show:
  1) retrieve data from API  
  2) process/transform  
  3) generate plots with package functions  
  4) compute + visualize VaR/CVaR (where applicable)

**Verify:**
- vignette(package = "bocvaletR")
- vignette("bocvaletR-data-visualization", package = "bocvaletR")

---

## 4. Individual Notebook / Daily Project Logs (Writing + Mechanics)

**Requirement:** Each member maintains an individual daily notebook with evidence (e.g., commit links).

- **Logs:**
  - `DEVLOG_Zihao_Sheng.md`
  - `DEVLOG_Wei_Li.Rmd`
  - `DEVLOG_Inara.Rmd`
- **Each log contains:** daily entries, task summaries, commit links, and design/decision notes

**Verify:** Open each `DEVLOG_*` file in the contributors’ repositories.

---

## 5. Collaboration Mechanics / Workflow Proof

**Requirement:** Contribution/workflow document + evidence in Git history that workflow was followed and contributions are balanced.

- **Governance/workflow docs (repo root):**
  - `CONTRIBUTING.md`
  - `CODE_OF_CONDUCT.md`
  - `LICENSE`
  - `README.md`
- **Evidence of collaboration:**
  - Git history shows frequent, incremental commits (not monolithic)
  - Multiple contributors with comparable activity across features, tests, docs
  - Individual devlogs cross-reference commit evidence

**Verify:**
- Review `CONTRIBUTING.md` + `CODE_OF_CONDUCT.md`
- Check GitHub “Commits” and “Contributors”
- Cross-check devlog commit links

---

## Bonus — Public / Open Source (Spark)

**Requirement:** Make public and usable by others (e.g., public repo; CRAN submission).

- **Public GitHub repo:** open access for install + contribution
- **Open-source readiness:** LICENSE + CODE_OF_CONDUCT + CONTRIBUTING present
- **Distribution:** GitHub Releases provide installable source tarballs
- **CRAN:** Submitted; passed automated checks; pending manual review (new submission)

**Verify:**
- Confirm repo visibility is public
- Check Releases page
- (If included) see CRAN submission email excerpt / win-builder logs in repo artifacts

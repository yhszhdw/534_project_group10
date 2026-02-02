# Contributing to bocvaletR

Thank you for your interest in contributing to **bocvaletR**!  
Contributions of all kinds are welcome, including bug reports, feature
requests, documentation improvements, and code contributions.

---

## Ways to Contribute

You can contribute to this project by:

- Reporting bugs or unexpected behavior
- Suggesting new features or enhancements
- Improving documentation or vignettes
- Submitting pull requests with code changes

Before contributing, please take a moment to review the guidelines below.

---

## Reporting Issues

If you encounter a bug or have a feature request, please open a GitHub issue
and include:

- A clear and descriptive title
- A minimal reproducible example (if applicable)
- Your R version and operating system
- Relevant error messages or warnings

Well-documented issues help speed up fixes and discussion.

---

## Development Setup

To set up a local development environment:

1. Clone the repository:
   - `git clone https://github.com/your-username/bocvaletR.git`
2. Install development dependencies:
   - `devtools::install_dev_deps()`
3. Load the package:
   - `devtools::load_all()`

All development and checks should be run from a clean R session.

---

## Coding Style

- Follow standard R package development conventions
- Use clear, descriptive function and variable names
- Keep functions focused and modular
- Avoid introducing unnecessary dependencies
- Ensure all exported functions are documented using **roxygen2**

---

## Testing

This package uses **testthat** for unit testing.

- New features and bug fixes should include corresponding tests
- All tests must pass locally before submitting a pull request:
  - `devtools::test()`
- API-related tests should use mocked HTTP responses where possible to avoid
  reliance on external services
- Pull requests must pass the GitHub Actions CI checks

---

## Documentation

Documentation is a first-class component of bocvaletR.

- Update function documentation when modifying behavior
- Add or update vignettes for user-facing workflows
- Ensure examples run without errors and complete in a reasonable time

---

## Pull Request Process

Before submitting a pull request:

- Ensure `devtools::check()` runs without errors, warnings, or notes
- Confirm all tests pass locally and in CI
- Keep pull requests focused on a single feature or fix
- Clearly describe the motivation and scope of your changes

Pull requests will be reviewed for correctness, clarity, and consistency with
the existing design.

---

## Code of Conduct

This project follows the Contributor Covenant Code of Conduct.  
By participating, you agree to uphold a respectful and inclusive environment
for all contributors.

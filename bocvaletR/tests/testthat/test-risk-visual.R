test_that("risk_var_cvar returns correct structure", {
  
  set.seed(123)
  x <- rnorm(1000)
  
  res <- risk_var_cvar(x, alpha = 0.05)
  
  expect_type(res, "list")
  expect_named(res, c("var", "cvar"))
  expect_true(res$cvar <= res$var)
})

test_that("risk_var_cvar rejects invalid inputs", {
  
  expect_error(
    risk_var_cvar("not numeric"),
    "numeric vector"
  )
  
  expect_error(
    risk_var_cvar(c(NA_real_, NA_real_)),
    "no valid observations"
  )
  
  expect_error(
    risk_var_cvar(rnorm(10), alpha = 1.2),
    "alpha must be"
  )
})

test_that("risk_plot_var_cvar returns plot and statistics", {
  
  set.seed(1)
  x <- rnorm(500)
  
  res <- risk_plot_var_cvar(x)
  
  expect_true("plot" %in% names(res))
  expect_s3_class(res$plot, "ggplot")
  expect_true(res$cvar <= res$var)
})

test_that("risk_text_summary returns character output", {
  
  txt <- risk_text_summary(
    n = 1000,
    alpha = 0.05,
    var = -0.02,
    cvar = -0.04
  )
  
  expect_type(txt, "character")
  expect_match(txt, "Historical risk summary")
})

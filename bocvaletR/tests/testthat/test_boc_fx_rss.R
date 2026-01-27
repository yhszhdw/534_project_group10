test_that("boc_fx_rss parses RSS XML into a tibble (series = NULL)", {
  xml_txt <- paste0(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rdf:RDF ',
    ' xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"',
    ' xmlns:rss="http://purl.org/rss/1.0/"',
    ' xmlns:dc="http://purl.org/dc/elements/1.1/"',
    ' xmlns:cb="http://www.cbwiki.net/wiki/index.php/Specification_1.1"',
    '>',
    ' <rss:channel rdf:about="https://www.bankofcanada.ca/valet/fx_rss"/>',
    ' <rss:item rdf:about="https://www.bankofcanada.ca/valet/fx_rss/FXAUDCAD">',
    '   <rss:title>AUD/CAD</rss:title>',
    '   <rss:link>https://example.com/FXAUDCAD</rss:link>',
    '   <rss:description>desc</rss:description>',
    '   <dc:date>2024-01-02T12:00:00Z</dc:date>',
    '   <cb:country>Canada</cb:country>',
    '   <cb:exchangeRate>',
    '     <cb:value>1.2345</cb:value>',
    '     <cb:baseCurrency>CAD</cb:baseCurrency>',
    '     <cb:targetCurrency>AUD</cb:targetCurrency>',
    '     <cb:rateType>NOON</cb:rateType>',
    '     <cb:observationPeriod>2024-01-02T00:00:00Z</cb:observationPeriod>',
    '   </cb:exchangeRate>',
    ' </rss:item>',
    ' <rss:item rdf:about="https://www.bankofcanada.ca/valet/fx_rss/FXUSDCAD">',
    '   <rss:title>USD/CAD</rss:title>',
    '   <rss:link>https://example.com/FXUSDCAD</rss:link>',
    '   <rss:description>desc2</rss:description>',
    '   <dc:date>2024-01-03T12:00:00Z</dc:date>',
    '   <cb:country>Canada</cb:country>',
    '   <cb:exchangeRate>',
    '     <cb:value>1.1111</cb:value>',
    '     <cb:baseCurrency>CAD</cb:baseCurrency>',
    '     <cb:targetCurrency>USD</cb:targetCurrency>',
    '     <cb:rateType>NOON</cb:rateType>',
    '     <cb:observationPeriod>2024-01-03T00:00:00Z</cb:observationPeriod>',
    '   </cb:exchangeRate>',
    ' </rss:item>',
    '</rdf:RDF>'
  )

  mock_resp <- structure(list(url = "https://www.bankofcanada.ca/valet/fx_rss"), class = "mock_resp")

  # Stub httr calls inside boc_fx_rss
  mockery::stub(boc_fx_rss, "httr::GET", function(url, ...) mock_resp)
  mockery::stub(boc_fx_rss, "httr::stop_for_status", function(resp, ...) invisible(resp))
  mockery::stub(boc_fx_rss, "httr::content", function(resp, as = "text", encoding = "UTF-8", ...) xml_txt)

  df <- boc_fx_rss(series = NULL, concat = TRUE, progress = FALSE)

  expect_s3_class(df, "tbl_df")
  expect_true(all(c(
    "feed_series", "item_series", "title", "link", "description", "dc_date_utc",
    "value", "base_currency", "target_currency", "rate_type", "observation_period_utc", "country"
  ) %in% names(df)))

  expect_equal(nrow(df), 2)
  expect_true(all(df$item_series %in% c("FXAUDCAD", "FXUSDCAD")))
  expect_equal(df$value[match("FXAUDCAD", df$item_series)], 1.2345)
  expect_equal(df$value[match("FXUSDCAD", df$item_series)], 1.1111)
})

test_that("boc_fx_rss handles multiple series and concat = FALSE", {
  xml_for <- function(code) paste0(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rdf:RDF ',
    ' xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"',
    ' xmlns:rss="http://purl.org/rss/1.0/"',
    ' xmlns:dc="http://purl.org/dc/elements/1.1/"',
    ' xmlns:cb="http://www.cbwiki.net/wiki/index.php/Specification_1.1"',
    '>',
    ' <rss:item rdf:about="https://www.bankofcanada.ca/valet/fx_rss/', code, '">',
    '   <rss:title>', code, '</rss:title>',
    '   <rss:link>https://example.com/', code, '</rss:link>',
    '   <rss:description>desc</rss:description>',
    '   <dc:date>2024-01-02T12:00:00Z</dc:date>',
    '   <cb:country>Canada</cb:country>',
    '   <cb:exchangeRate>',
    '     <cb:value>1</cb:value>',
    '     <cb:baseCurrency>CAD</cb:baseCurrency>',
    '     <cb:targetCurrency>XXX</cb:targetCurrency>',
    '     <cb:rateType>NOON</cb:rateType>',
    '     <cb:observationPeriod>2024-01-02T00:00:00Z</cb:observationPeriod>',
    '   </cb:exchangeRate>',
    ' </rss:item>',
    '</rdf:RDF>'
  )

  # GET returns the url so content() can decide which XML to return
  mockery::stub(boc_fx_rss, "httr::GET", function(url, ...) structure(list(url = url), class = "mock_resp"))
  mockery::stub(boc_fx_rss, "httr::stop_for_status", function(resp, ...) invisible(resp))
  mockery::stub(boc_fx_rss, "httr::content", function(resp, as = "text", encoding = "UTF-8", ...) {
    code <- sub(".*/fx_rss/", "", resp$url)
    xml_for(code)
  })

  out <- boc_fx_rss(series = c("FXAAA", "FXBBB"), concat = FALSE, progress = FALSE)

  expect_true(is.list(out))
  expect_equal(names(out), c("FXAAA", "FXBBB"))
  expect_s3_class(out$FXAAA, "tbl_df")
  expect_s3_class(out$FXBBB, "tbl_df")
  expect_equal(out$FXAAA$item_series[[1]], "FXAAA")
  expect_equal(out$FXBBB$item_series[[1]], "FXBBB")
})

test_that("boc_fx_rss warns and returns empty tibble on request error", {
  mockery::stub(boc_fx_rss, "httr::GET", function(url, ...) stop("boom"))

  expect_warning(
    df <- boc_fx_rss(series = NULL, concat = TRUE, progress = FALSE),
    "request failed",
    fixed = FALSE
  )

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

test_that("boc_fx_rss warns and returns empty tibble on HTTP error", {
  mockery::stub(boc_fx_rss, "httr::GET", function(url, ...) structure(list(url = url), class = "mock_resp"))
  mockery::stub(boc_fx_rss, "httr::stop_for_status", function(resp, ...) stop("http 500"))
  mockery::stub(boc_fx_rss, "httr::content", function(resp, as = "text", encoding = "UTF-8", ...) "ignored")

  expect_warning(
    df <- boc_fx_rss(series = NULL, concat = TRUE, progress = FALSE),
    "HTTP error",
    fixed = FALSE
  )

  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

# ----------------------------------------------------------------------

test_that("boc_fx_rss_available returns distinct series with pair column", {
  local_mocked_bindings(
    boc_fx_rss = function(series = NULL, concat = TRUE, progress = FALSE) {
      tibble::tibble(
        feed_series = NA_character_,
        item_series = c("FXAUDCAD", "FXAUDCAD", "FXUSDCAD"),
        title = c("t1", "t1dup", "t2"),
        link = c("l1", "l1dup", "l2"),
        description = c("d1", "d1dup", "d2"),
        dc_date_utc = as.POSIXct(c("2024-01-01","2024-01-02","2024-01-03"), tz = "UTC"),
        value = c(1.1, 1.2, 1.3),
        base_currency = c("CAD","CAD","CAD"),
        target_currency = c("AUD","AUD","USD"),
        rate_type = c("NOON","NOON","NOON"),
        observation_period_utc = as.POSIXct(c("2024-01-01","2024-01-02","2024-01-03"), tz = "UTC"),
        country = c("Canada","Canada","Canada")
      )
    }
  )

  df <- boc_fx_rss_available()

  expect_s3_class(df, "tbl_df")
  expect_true(all(c("item_series", "target_currency", "base_currency", "rate_type", "country", "pair") %in% names(df)))
  expect_equal(sum(df$item_series == "FXAUDCAD"), 1)

  aud_pair <- df$pair[df$item_series == "FXAUDCAD"][[1]]
  expect_equal(aud_pair, "AUD/CAD")
})

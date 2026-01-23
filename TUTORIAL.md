## 1.`boc_list_series(as = c("df", "json"), keyword = NULL, limit = NULL)`

List all available Bank of Canada **series IDs and metadata**  
(**does NOT return actual data**; use `boc_series()` with the returned `id`).

**Arguments**
- `keyword`: search series by keyword (id / label / description)
- `limit`: maximum number of series returned
- `as`: `"df"` (default) or `"json"`

**Example**
```r
boc_list_series(keyword = "exchange", limit = 10)
```

## 2.`boc_list_groups(as = c("df", "json"), keyword = NULL, limit = NULL, clean_description = TRUE)`

List all available Bank of Canada **groups** (each group contains multiple related series).

**Arguments**
- `keyword`: search groups by keyword (id / label / description)
- `limit`: maximum number of groups returned
- `as`: `"df"` (default) or `"json"`

**Example**
```r
boc_list_groups(keyword = "exchange")
```

## 3.`boc_groups(group, as = c("list", "series_df", "group_df"))`

Get details of **one Bank of Canada group** and the series it contains.

**Arguments**
- `group`: group ID (e.g. `"FX_RATES_DAILY"`)
- `as`:  
  - `"list"` (default): group info + series list  
  - `"series_df"`: only series table (use `df$id` with `boc_series()`)  
  - `"group_df"`: only group metadata

**Example**
```r
g <- boc_groups("FX_RATES_DAILY")
g$series$id            # series IDs inside the group

# directly fetch data
boc_series(g$series$id)
```

## 4.`boc_series(series, start_date = NULL, end_date = NULL, concat = TRUE, progress = TRUE)`

Fetch **time series observations** for one or more Bank of Canada series IDs.

**Arguments**
- `series`: character vector of series IDs  
  (can be provided manually, from `group$series$id`, or from `boc_list_series()`)
- `start_date`, `end_date`: date range (`YYYY-MM-DD`)
- `concat`: `TRUE` (default) returns one combined tibble;  
  `FALSE` returns a list of tibbles (one per series)
- `progress`: show progress bar when fetching many series

**Common ways to provide `series`**
```r
# 1) manually specify series IDs
boc_series(c("FXUSDCAD", "FXEURCAD"))

# 2) from a group
g <- boc_groups("FX_RATES_DAILY")
boc_series(g$series$id)

# 3) from list search
ids <- boc_list_series(keyword = "USDCAD", limit = 1)$id
boc_series(ids)
```

## 5.`boc_fx_rss_available()`

List all **available FX exchange rate codes** supported by the Bank of Canada FX RSS feed.

This function is useful when you **do not know FX series IDs in advance**.

**Return**
- `item_series`: FX series code (e.g. `"FXUSDCAD"`)
- `pair`: currency pair (e.g. `"USD/CAD"`)
- `base_currency`, `target_currency`
- `rate_type`, `country`

**Example**
```r
# see all available FX codes
boc_fx_rss_available()

# pick some FX codes and fetch latest values
codes <- boc_fx_rss_available()$item_series
boc_fx_rss(codes)
```

## 6.`boc_fx_rss(series = NULL, concat = TRUE, progress = TRUE)`

Fetch **latest FX exchange rates** from the Bank of Canada RSS feed.

If `series` is `NULL`, all available FX rates are returned.

**Arguments**
- `series`: FX series IDs (e.g. `"FXUSDCAD"`);  
  if `NULL`, fetch all available FX rates
- `concat`: `TRUE` (default) returns one tibble;  
  `FALSE` returns a list (one tibble per series)
- `progress`: show progress bar when fetching multiple series

**Notes**
- `item_series` is the actual FX code of each rate  
- `feed_series` indicates the requested RSS feed (may be `NA` when fetching all)

**Example**
```r
# fetch all latest FX rates
boc_fx_rss()

# fetch specific FX rates
boc_fx_rss(c("FXUSDCAD", "FXEURCAD"))

# fetch using available codes
codes <- boc_fx_rss_available()$item_series
boc_fx_rss(codes)
```

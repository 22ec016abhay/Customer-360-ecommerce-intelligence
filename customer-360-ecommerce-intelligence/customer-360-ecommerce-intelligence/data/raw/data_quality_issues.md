# Data Quality Issues — Answer Key

This file documents every intentional data-quality issue injected into the raw dataset.
Do NOT look at this until after you've done your own inspection in Excel/Python — 
use it only to check whether you found everything.

Reference/analysis date for the whole project (fixed, not dynamic 'today'): **2026-08-31**
Order period: 2025-01-01 to 2026-08-31

| Table | Issue | Description | Row Count |
|---|---|---|---|
| products.csv | products_category_inconsistency | Category values written inconsistently (wrong capitalization or 'and' instead of '&') for a handful of products, e.g. 'electronics' instead of 'Electronics'. | 6 |
| products.csv | products_cost_greater_than_price | cost_price is higher than unit_price for a few products, implying a negative margin. Likely a data-entry mistake in the source system. | 3 |
| customers.csv | customers_missing_age | Age is missing (null) for a subset of customers — optional field not always collected at signup. | 175 |
| customers.csv | customers_missing_gender | Gender is missing (null) for a subset of customers. | 150 |
| customers.csv | customers_missing_state | State is missing (null) for a subset of customers. | 100 |
| customers.csv | customers_city_capitalization | City names appear with inconsistent capitalization (e.g. 'MUMBAI' or 'mumbai' instead of 'Mumbai'). | 200 |
| customers.csv | customers_invalid_age | A few customers have implausible age values (e.g. 0, negative, or over 100) — likely manual entry errors. | 5 |
| customers.csv | customers_duplicate_rows | A number of customers appear twice in the file with identical data — a classic 'duplicate export/import' issue. | 12 |
| orders.csv | orders_negative_discount | A small number of orders show a negative discount_amount, which is not logically valid and should be flagged during cleaning. | 15 |
| orders.csv | orders_missing_payment_method | payment_method is missing for a subset of orders. | 413 |
| orders.csv | orders_duplicate_rows | A number of orders appear twice with identical data (duplicate export issue). | 20 |
| ? | order_items_zero_price | unit_price recorded as 0 for a handful of line items — likely a promo/glitch rather than a real free item. | 12 |
| ? | order_items_outlier_quantity | A few line items have unusually large quantities (25-60 units) compared to the typical 1-3, worth investigating as bulk orders or errors. | 10 |
| ? | order_items_negative_quantity | A few line items have a negative quantity, which is not physically valid for a sales record. | 8 |
| ? | order_items_duplicate_rows | A number of order line items appear twice with identical data (duplicate export issue). | 25 |
# Gold model notes

## Grain and keys

`gold.fact_sales` has one row per order/product line in the supplied files. The sample has no repeated order/product pairs, but the source has no separate line number. Add one if future extracts can contain repeated products on a single order.

`gold.dim_customers.customer_key` uses the CRM customer ID. `gold.dim_products.product_key` uses the normalized product number. They are stable source keys rather than generated surrogate keys; the original dimension views generated row numbers that could change when source rows changed.

The product view chooses the latest available record for each product number, including discontinued products. This makes all product keys in the supplied sales file joinable. It does not reconstruct the product attributes that were current on the sale date.

## Measures and KPIs

- **Revenue:** sum of sales amount after Silver reconciles positive unit price and quantity.
- **Units:** sum of sales quantity.
- **Orders:** distinct order numbers, not fact rows.
- **Revenue per order:** revenue divided by distinct orders.
- **Repeat customer:** more than one distinct order in the supplied data period.

Customer metrics cover only the dates in the included extracts; they are not lifetime value estimates.

## Date dimension

`gold.dim_date` uses `YYYYMMDD` as `date_key` and includes year, quarter, month, and day attributes. Run `gold.load_date_dimension` after `silver.load_silver` to add every date between the earliest and latest order, shipping, and due date.

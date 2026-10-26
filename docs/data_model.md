# Gold model

## `gold.fact_sales`

One row per source order/product line for the included extract. `order_number` repeats when an order contains multiple products. The current files contain no duplicate order/product pairs, but there is no source line ID to distinguish repeated occurrences if that changes.

| Column | Meaning |
| --- | --- |
| `order_number` | Source order number; count distinct values for orders |
| `customer_key` | Persisted key into `gold.dim_customers` |
| `product_key` | Persisted key into `gold.dim_products` |
| `order_date_key`, `shipping_date_key`, `due_date_key` | `YYYYMMDD` keys into `gold.dim_date`; null when source date is invalid or absent |
| `sales_amount` | Cleaned line sales amount |
| `quantity` | Source line quantity |
| `unit_price` | Source unit price or price inferred from sales divided by quantity |

When a positive source price is available but line sales disagree with `quantity * price`, Silver recalculates sales from quantity and price. If price is missing or invalid but sales and quantity are positive, it derives price. Rows that cannot be reconciled remain null and appear in the quality checks.

## Dimensions

- **`gold.dim_customers`** is keyed by `customer_key` (identity) and matched on `customer_id` from CRM. CRM supplies gender when populated; ERP supplies a fallback. Repeated loads update attributes in place.
- **`gold.dim_products`** is keyed by `product_key` (identity) and matched on the product number. The most recent source version is used, including products with no active version, so sales for discontinued products still resolve. This is a current/latest-state dimension, not a type 2 history.
- **`gold.dim_date`** uses the calendar date as its natural identity and `YYYYMMDD` as `date_key`. It covers the continuous range between the earliest and latest order, shipping, or due date seen in Silver.

## KPI definitions

- **Revenue:** sum of `sales_amount`.
- **Orders:** distinct count of `order_number`, not fact rows.
- **Units sold:** sum of `quantity`.
- **Revenue per order:** revenue divided by distinct orders.
- **Repeat customer:** customer with more than one distinct order in the available extract.

These are descriptive metrics for the supplied data window. Customer lifetime revenue is limited to that window; it is not a prediction or a full customer lifetime value calculation.

## Load behavior

Bronze and Silver are full refreshes. Gold merges current customer and product attributes into persisted dimension tables and inserts missing calendar dates. Identity keys stay the same while a natural key remains present. The project does not implement source deletion handling, incremental watermarks, or type 2 history.

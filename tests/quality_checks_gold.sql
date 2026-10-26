-- Gold checks. Run after gold.load_gold.

-- Natural keys and date keys are unique.
SELECT customer_id, COUNT(*) AS row_count FROM gold.dim_customers GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT product_number, COUNT(*) AS row_count FROM gold.dim_products GROUP BY product_number HAVING COUNT(*) > 1;
SELECT date_key, COUNT(*) AS row_count FROM gold.dim_date GROUP BY date_key HAVING COUNT(*) > 1;

-- Fact rows must resolve to customer and product dimensions.
SELECT f.* FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products AS p ON p.product_key = f.product_key
WHERE c.customer_key IS NULL OR p.product_key IS NULL;

-- Present order dates must resolve to the calendar dimension.
SELECT f.order_number, f.order_date FROM gold.fact_sales AS f
LEFT JOIN gold.dim_date AS d ON d.date_key = f.order_date_key
WHERE f.order_date IS NOT NULL AND d.date_key IS NULL;

-- Declared sample grain: one row per order/product. Add a source line key if that changes.
SELECT order_number, product_key, COUNT(*) AS row_count
FROM gold.fact_sales GROUP BY order_number, product_key HAVING COUNT(*) > 1;

-- Row count reconciliation
SELECT (SELECT COUNT(*) FROM silver.crm_sales_details) AS silver_sales_rows,
       (SELECT COUNT(*) FROM gold.fact_sales) AS gold_fact_rows;
-- Shipping and due dates must also resolve when populated.
SELECT f.order_number, f.shipping_date FROM gold.fact_sales AS f
LEFT JOIN gold.dim_date AS d ON d.date_key = f.shipping_date_key
WHERE f.shipping_date IS NOT NULL AND d.date_key IS NULL;
SELECT f.order_number, f.due_date FROM gold.fact_sales AS f
LEFT JOIN gold.dim_date AS d ON d.date_key = f.due_date_key
WHERE f.due_date IS NOT NULL AND d.date_key IS NULL;

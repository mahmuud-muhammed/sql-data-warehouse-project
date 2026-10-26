-- Monthly revenue and order trend. Order count is distinct orders, not fact rows.
SELECT d.[year], d.[month], d.month_name,
       SUM(f.sales_amount) AS revenue,
       COUNT(DISTINCT f.order_number) AS order_count,
       SUM(f.quantity) AS units_sold,
       CAST(SUM(f.sales_amount) / NULLIF(COUNT(DISTINCT f.order_number), 0) AS DECIMAL(19,2)) AS revenue_per_order
FROM gold.fact_sales AS f
JOIN gold.dim_date AS d ON d.date_key = f.order_date_key
GROUP BY d.[year], d.[month], d.month_name
ORDER BY d.[year], d.[month];

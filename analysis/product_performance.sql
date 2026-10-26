-- Product performance: latest available product attributes, by category and product.
SELECT p.category, p.subcategory, p.product_number, p.product_name,
       SUM(f.sales_amount) AS revenue,
       SUM(f.quantity) AS units_sold,
       COUNT(DISTINCT f.order_number) AS orders,
       CAST(SUM(f.sales_amount) / NULLIF(SUM(f.quantity), 0) AS DECIMAL(19,2)) AS realized_unit_revenue
FROM gold.fact_sales AS f
JOIN gold.dim_products AS p ON p.product_key = f.product_key
GROUP BY p.category, p.subcategory, p.product_number, p.product_name
ORDER BY revenue DESC;

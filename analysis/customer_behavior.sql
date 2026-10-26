-- Customer behavior: identifies repeat purchasers and revenue concentration.
WITH customer_orders AS (
    SELECT c.customer_key, c.customer_id, c.customer_number,
           CONCAT(c.first_name, N' ', c.last_name) AS customer_name,
           COUNT(DISTINCT f.order_number) AS order_count,
           SUM(f.sales_amount) AS lifetime_revenue,
           MIN(f.order_date) AS first_order_date,
           MAX(f.order_date) AS most_recent_order_date
    FROM gold.fact_sales AS f
    JOIN gold.dim_customers AS c ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.customer_id, c.customer_number, c.first_name, c.last_name
)
SELECT *, CASE WHEN order_count > 1 THEN 1 ELSE 0 END AS is_repeat_customer
FROM customer_orders
ORDER BY lifetime_revenue DESC;

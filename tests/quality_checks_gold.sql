/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency,
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of dimension keys.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'gold.dim_customers'
-- ====================================================================
-- Check for Uniqueness of Customer Key in gold.dim_customers
-- Expectation: No results
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.dim_products'
-- ====================================================================
-- Check for Uniqueness of Product Key in gold.dim_products
-- Expectation: No results
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.fact_sales'
-- ====================================================================
-- Check the data model connectivity between fact and dimensions
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;

-- Product/customer keys in the fact must resolve to their dimensions.
SELECT f.order_number, f.product_key, f.customer_key
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p ON p.product_key = f.product_key
LEFT JOIN gold.dim_customers AS c ON c.customer_key = f.customer_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;

-- Each populated date key must be present in the calendar dimension.
SELECT f.order_number, f.order_date
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_date AS d ON d.date_key = f.order_date_key
WHERE f.order_date IS NOT NULL AND d.date_key IS NULL;
SELECT f.order_number, f.shipping_date
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_date AS d ON d.date_key = f.shipping_date_key
WHERE f.shipping_date IS NOT NULL AND d.date_key IS NULL;
SELECT f.order_number, f.due_date
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_date AS d ON d.date_key = f.due_date_key
WHERE f.due_date IS NOT NULL AND d.date_key IS NULL;

-- The supplied sample has one row per order/product pair.
SELECT order_number, product_key, COUNT(*) AS row_count
FROM gold.fact_sales
GROUP BY order_number, product_key
HAVING COUNT(*) > 1;

-- Compare Silver sales rows with Gold fact rows.
SELECT (SELECT COUNT(*) FROM silver.crm_sales_details) AS silver_rows,
       (SELECT COUNT(*) FROM gold.fact_sales) AS gold_rows;

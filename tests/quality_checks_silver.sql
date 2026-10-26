-- Silver layer checks. Run after silver.load_silver; investigate any returned rows.

-- Business key uniqueness
SELECT cst_id, COUNT(*) AS row_count FROM silver.crm_cust_info GROUP BY cst_id HAVING COUNT(*) > 1;
SELECT prd_id, COUNT(*) AS row_count FROM silver.crm_prd_info GROUP BY prd_id HAVING COUNT(*) > 1;

-- Unexpected whitespace and standardization
SELECT cst_id FROM silver.crm_cust_info WHERE cst_key <> TRIM(cst_key) OR cst_firstname <> TRIM(cst_firstname) OR cst_lastname <> TRIM(cst_lastname);
SELECT prd_id FROM silver.crm_prd_info WHERE prd_nm <> TRIM(prd_nm) OR prd_cost < 0 OR prd_cost IS NULL;
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;
SELECT DISTINCT prd_line FROM silver.crm_prd_info;

-- Product effective date ranges
SELECT * FROM silver.crm_prd_info WHERE prd_end_dt < prd_start_dt;

-- Sales date order, unresolved measures, and arithmetic within currency precision.
SELECT * FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL OR sls_ship_dt IS NULL OR sls_due_dt IS NULL
   OR sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_quantity <= 0
   OR sls_price IS NULL OR sls_price <= 0;
SELECT * FROM silver.crm_sales_details
WHERE ABS(sls_sales - (sls_quantity * sls_price)) > 0.01;

-- Compare source and target row counts after the load; customer Silver deduplicates by cst_id.
SELECT 'crm_cust_info' AS table_name,
       (SELECT COUNT(*) FROM bronze.crm_cust_info) AS bronze_rows,
       (SELECT COUNT(*) FROM silver.crm_cust_info) AS silver_rows;
SELECT 'crm_prd_info' AS table_name,
       (SELECT COUNT(*) FROM bronze.crm_prd_info WHERE prd_id IS NOT NULL AND prd_key IS NOT NULL) AS eligible_bronze_rows,
       (SELECT COUNT(*) FROM silver.crm_prd_info) AS silver_rows;
SELECT 'crm_sales_details' AS table_name,
       (SELECT COUNT(*) FROM bronze.crm_sales_details WHERE sls_ord_num IS NOT NULL AND sls_prd_key IS NOT NULL AND sls_cust_id IS NOT NULL) AS eligible_bronze_rows,
       (SELECT COUNT(*) FROM silver.crm_sales_details) AS silver_rows;

-- ERP standardization inventory
SELECT DISTINCT gen FROM silver.erp_cust_az12;
SELECT DISTINCT cntry FROM silver.erp_loc_a101 ORDER BY cntry;
SELECT * FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat) OR subcat <> TRIM(subcat) OR maintenance <> TRIM(maintenance);
-- ERP integration keys should be unique after standardization.
SELECT cid, COUNT(*) AS row_count FROM silver.erp_cust_az12 GROUP BY cid HAVING COUNT(*) > 1;
SELECT cid, COUNT(*) AS row_count FROM silver.erp_loc_a101 GROUP BY cid HAVING COUNT(*) > 1;
SELECT id, COUNT(*) AS row_count FROM silver.erp_px_cat_g1v2 GROUP BY id HAVING COUNT(*) > 1;

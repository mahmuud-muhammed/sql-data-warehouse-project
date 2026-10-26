-- Rebuild Silver in one transaction so a failed transformation leaves the previous load intact.
CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE silver.crm_cust_info;
        INSERT INTO silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
        SELECT cst_id, cst_key, TRIM(cst_firstname), TRIM(cst_lastname),
            CASE UPPER(TRIM(cst_marital_status)) WHEN 'S' THEN 'Single' WHEN 'M' THEN 'Married' ELSE 'n/a' END,
            CASE UPPER(TRIM(cst_gndr)) WHEN 'F' THEN 'Female' WHEN 'M' THEN 'Male' ELSE 'n/a' END,
            cst_create_date
        FROM (
            SELECT *, ROW_NUMBER() OVER (
                PARTITION BY cst_id ORDER BY cst_create_date DESC, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr
            ) AS rn
            FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL
        ) AS src
        WHERE rn = 1;

        TRUNCATE TABLE silver.crm_prd_info;
        INSERT INTO silver.crm_prd_info (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
        SELECT prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
            SUBSTRING(prd_key, 7, LEN(prd_key)),
            TRIM(prd_nm), prd_cost,
            CASE UPPER(TRIM(prd_line)) WHEN 'M' THEN 'Mountain' WHEN 'R' THEN 'Road' WHEN 'S' THEN 'Other Sales' WHEN 'T' THEN 'Touring' ELSE 'n/a' END,
            CAST(prd_start_dt AS DATE),
            CAST(DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt, prd_id)) AS DATE)
        FROM bronze.crm_prd_info
        WHERE prd_id IS NOT NULL AND prd_key IS NOT NULL;

        -- Keep unresolved source values as NULL; the quality checks identify them for review.
        TRUNCATE TABLE silver.crm_sales_details;
        ;WITH parsed AS (
            SELECT sls_ord_num, sls_prd_key, sls_cust_id,
                CASE WHEN LEN(CONVERT(VARCHAR(20), sls_order_dt)) = 8 THEN TRY_CONVERT(DATE, CONVERT(CHAR(8), sls_order_dt), 112) END AS sls_order_dt,
                CASE WHEN LEN(CONVERT(VARCHAR(20), sls_ship_dt)) = 8 THEN TRY_CONVERT(DATE, CONVERT(CHAR(8), sls_ship_dt), 112) END AS sls_ship_dt,
                CASE WHEN LEN(CONVERT(VARCHAR(20), sls_due_dt)) = 8 THEN TRY_CONVERT(DATE, CONVERT(CHAR(8), sls_due_dt), 112) END AS sls_due_dt,
                sls_sales, sls_quantity, sls_price
            FROM bronze.crm_sales_details
        ), cleaned AS (
            SELECT *,
                CASE WHEN sls_price > 0 THEN sls_price
                     WHEN sls_sales > 0 AND sls_quantity > 0 THEN sls_sales / NULLIF(CAST(sls_quantity AS DECIMAL(19,4)), 0)
                     ELSE NULL END AS clean_price,
                CASE WHEN sls_quantity > 0 AND sls_price > 0 AND (sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price))
                          THEN sls_quantity * ABS(sls_price)
                     WHEN sls_sales > 0 THEN sls_sales
                     WHEN sls_quantity > 0 AND sls_price > 0 THEN sls_quantity * ABS(sls_price)
                     ELSE NULL END AS clean_sales
            FROM parsed
        )
        INSERT INTO silver.crm_sales_details (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
        SELECT sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, clean_sales, sls_quantity, clean_price
        FROM cleaned
        WHERE sls_ord_num IS NOT NULL AND sls_prd_key IS NOT NULL AND sls_cust_id IS NOT NULL;

        TRUNCATE TABLE silver.erp_cust_az12;
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END,
            CASE WHEN bdate > CONVERT(DATE, SYSUTCDATETIME()) THEN NULL ELSE bdate END,
            CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male' ELSE 'n/a' END
        FROM bronze.erp_cust_az12 WHERE cid IS NOT NULL;

        TRUNCATE TABLE silver.erp_loc_a101;
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT REPLACE(TRIM(cid), '-', ''),
            CASE UPPER(TRIM(cntry)) WHEN 'DE' THEN 'Germany' WHEN 'US' THEN 'United States' WHEN 'USA' THEN 'United States' ELSE COALESCE(NULLIF(TRIM(cntry), ''), 'n/a') END
        FROM bronze.erp_loc_a101 WHERE cid IS NOT NULL;

        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT TRIM(id), TRIM(cat), TRIM(subcat), TRIM(maintenance)
        FROM bronze.erp_px_cat_g1v2 WHERE id IS NOT NULL;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

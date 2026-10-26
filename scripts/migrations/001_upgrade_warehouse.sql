-- Upgrade the original portfolio schema in place. Safe to run after Bronze and Silver tables exist.
-- Fresh installs already use these types and this script makes no data changes.
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'silver.crm_prd_info', N'cat_id') IS NULL
        ALTER TABLE silver.crm_prd_info ADD cat_id NVARCHAR(50) NULL;

    IF OBJECT_ID(N'bronze.crm_prd_info', N'U') IS NOT NULL
    BEGIN
        UPDATE s
        SET cat_id = REPLACE(SUBSTRING(b.prd_key, 1, 5), N'-', N'_')
        FROM silver.crm_prd_info AS s
        JOIN bronze.crm_prd_info AS b ON b.prd_id = s.prd_id
        WHERE s.cat_id IS NULL;
    END;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_prd_info') AND name = N'prd_start_dt' AND TYPE_NAME(system_type_id) <> N'date')
        ALTER TABLE silver.crm_prd_info ALTER COLUMN prd_start_dt DATE NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_prd_info') AND name = N'prd_end_dt' AND TYPE_NAME(system_type_id) <> N'date')
        ALTER TABLE silver.crm_prd_info ALTER COLUMN prd_end_dt DATE NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_prd_info') AND name = N'prd_cost' AND TYPE_NAME(system_type_id) <> N'decimal')
        ALTER TABLE silver.crm_prd_info ALTER COLUMN prd_cost DECIMAL(19,4) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_prd_info') AND name = N'prd_nm' AND max_length < 200)
        ALTER TABLE silver.crm_prd_info ALTER COLUMN prd_nm NVARCHAR(100) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'bronze.crm_prd_info') AND name = N'prd_nm' AND max_length < 200)
        ALTER TABLE bronze.crm_prd_info ALTER COLUMN prd_nm NVARCHAR(100) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.erp_loc_a101') AND name = N'cntry' AND max_length < 200)
        ALTER TABLE silver.erp_loc_a101 ALTER COLUMN cntry NVARCHAR(100) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'bronze.erp_loc_a101') AND name = N'cntry' AND max_length < 200)
        ALTER TABLE bronze.erp_loc_a101 ALTER COLUMN cntry NVARCHAR(100) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.erp_px_cat_g1v2') AND name = N'cat' AND max_length < 200)
        ALTER TABLE silver.erp_px_cat_g1v2 ALTER COLUMN cat NVARCHAR(100) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.erp_px_cat_g1v2') AND name = N'subcat' AND max_length < 200)
        ALTER TABLE silver.erp_px_cat_g1v2 ALTER COLUMN subcat NVARCHAR(100) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'bronze.erp_px_cat_g1v2') AND name = N'cat' AND max_length < 200)
        ALTER TABLE bronze.erp_px_cat_g1v2 ALTER COLUMN cat NVARCHAR(100) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'bronze.erp_px_cat_g1v2') AND name = N'subcat' AND max_length < 200)
        ALTER TABLE bronze.erp_px_cat_g1v2 ALTER COLUMN subcat NVARCHAR(100) NULL;

    DECLARE @column SYSNAME, @type SYSNAME, @sql NVARCHAR(MAX);
    DECLARE date_columns CURSOR LOCAL FAST_FORWARD FOR
        SELECT c.name, TYPE_NAME(c.system_type_id)
        FROM sys.columns AS c
        WHERE c.object_id = OBJECT_ID(N'silver.crm_sales_details')
          AND c.name IN (N'sls_order_dt', N'sls_ship_dt', N'sls_due_dt');
    OPEN date_columns;
    FETCH NEXT FROM date_columns INTO @column, @type;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @type <> N'date'
        BEGIN
            SET @sql = N'ALTER TABLE silver.crm_sales_details ADD ' + QUOTENAME(@column + N'_v2') + N' DATE NULL;'
                + N' UPDATE silver.crm_sales_details SET ' + QUOTENAME(@column + N'_v2')
                + N' = CASE WHEN LEN(CONVERT(VARCHAR(20), ' + QUOTENAME(@column) + N')) = 8 THEN TRY_CONVERT(DATE, CONVERT(CHAR(8), ' + QUOTENAME(@column) + N'), 112) END;'
                + N' ALTER TABLE silver.crm_sales_details DROP COLUMN ' + QUOTENAME(@column) + N';'
                + N' EXEC sys.sp_rename N''silver.crm_sales_details.' + @column + N'_v2'', N''' + @column + N''', N''COLUMN'';';
            EXEC sys.sp_executesql @sql;
        END;
        FETCH NEXT FROM date_columns INTO @column, @type;
    END;
    CLOSE date_columns;
    DEALLOCATE date_columns;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_sales_details') AND name = N'sls_sales' AND TYPE_NAME(system_type_id) <> N'decimal')
        ALTER TABLE silver.crm_sales_details ALTER COLUMN sls_sales DECIMAL(19,4) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_sales_details') AND name = N'sls_price' AND TYPE_NAME(system_type_id) <> N'decimal')
        ALTER TABLE silver.crm_sales_details ALTER COLUMN sls_price DECIMAL(19,4) NULL;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'bronze.crm_sales_details') AND name = N'sls_sales' AND TYPE_NAME(system_type_id) <> N'decimal')
        ALTER TABLE bronze.crm_sales_details ALTER COLUMN sls_sales DECIMAL(19,4) NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'bronze.crm_sales_details') AND name = N'sls_price' AND TYPE_NAME(system_type_id) <> N'decimal')
        ALTER TABLE bronze.crm_sales_details ALTER COLUMN sls_price DECIMAL(19,4) NULL;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

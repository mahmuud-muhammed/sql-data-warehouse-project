/*
The Bronze tables keep their source formats. Silver needs a category column for
products and DATE columns for sales dates. This script is safe to rerun.
*/
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'silver.crm_prd_info', N'cat_id') IS NULL
        ALTER TABLE silver.crm_prd_info ADD cat_id NVARCHAR(50) NULL;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_prd_info') AND name = N'prd_start_dt' AND TYPE_NAME(system_type_id) <> N'date')
        ALTER TABLE silver.crm_prd_info ALTER COLUMN prd_start_dt DATE NULL;
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_prd_info') AND name = N'prd_end_dt' AND TYPE_NAME(system_type_id) <> N'date')
        ALTER TABLE silver.crm_prd_info ALTER COLUMN prd_end_dt DATE NULL;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_sales_details') AND name = N'sls_order_dt' AND TYPE_NAME(system_type_id) <> N'date')
    BEGIN
        ALTER TABLE silver.crm_sales_details ADD sls_order_dt_v2 DATE NULL;
        UPDATE silver.crm_sales_details
        SET sls_order_dt_v2 = TRY_CONVERT(DATE, CONVERT(CHAR(8), sls_order_dt), 112);
        ALTER TABLE silver.crm_sales_details DROP COLUMN sls_order_dt;
        EXEC sys.sp_rename N'silver.crm_sales_details.sls_order_dt_v2', N'sls_order_dt', N'COLUMN';
    END;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_sales_details') AND name = N'sls_ship_dt' AND TYPE_NAME(system_type_id) <> N'date')
    BEGIN
        ALTER TABLE silver.crm_sales_details ADD sls_ship_dt_v2 DATE NULL;
        UPDATE silver.crm_sales_details
        SET sls_ship_dt_v2 = TRY_CONVERT(DATE, CONVERT(CHAR(8), sls_ship_dt), 112);
        ALTER TABLE silver.crm_sales_details DROP COLUMN sls_ship_dt;
        EXEC sys.sp_rename N'silver.crm_sales_details.sls_ship_dt_v2', N'sls_ship_dt', N'COLUMN';
    END;

    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'silver.crm_sales_details') AND name = N'sls_due_dt' AND TYPE_NAME(system_type_id) <> N'date')
    BEGIN
        ALTER TABLE silver.crm_sales_details ADD sls_due_dt_v2 DATE NULL;
        UPDATE silver.crm_sales_details
        SET sls_due_dt_v2 = TRY_CONVERT(DATE, CONVERT(CHAR(8), sls_due_dt), 112);
        ALTER TABLE silver.crm_sales_details DROP COLUMN sls_due_dt;
        EXEC sys.sp_rename N'silver.crm_sales_details.sls_due_dt_v2', N'sls_due_dt', N'COLUMN';
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- Load the six CSV extracts as one full refresh. @source_root is the datasets directory, not the repo root.
CREATE OR ALTER PROCEDURE bronze.load_bronze
    @source_root NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@source_root)), N'') IS NULL
        THROW 50001, 'Provide @source_root, the directory containing datasets.', 1;

    SET @source_root = RTRIM(@source_root);
    WHILE RIGHT(@source_root, 1) IN (N'\', N'/')
        SET @source_root = LEFT(@source_root, LEN(@source_root) - 1);

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @escaped_root NVARCHAR(8000) = REPLACE(@source_root, N'''', N'''''');

    SET @sql = N'
BULK INSERT bronze.crm_cust_info FROM ''' + @escaped_root + N'\source_crm\cust_info.csv'' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);
BULK INSERT bronze.crm_prd_info FROM ''' + @escaped_root + N'\source_crm\prd_info.csv'' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);
BULK INSERT bronze.crm_sales_details FROM ''' + @escaped_root + N'\source_crm\sales_details.csv'' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);
BULK INSERT bronze.erp_cust_az12 FROM ''' + @escaped_root + N'\source_erp\CUST_AZ12.csv'' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);
BULK INSERT bronze.erp_loc_a101 FROM ''' + @escaped_root + N'\source_erp\LOC_A101.csv'' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);
BULK INSERT bronze.erp_px_cat_g1v2 FROM ''' + @escaped_root + N'\source_erp\PX_CAT_G1V2.csv'' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);';

    BEGIN TRY
        BEGIN TRANSACTION;
        TRUNCATE TABLE bronze.crm_cust_info;
        TRUNCATE TABLE bronze.crm_prd_info;
        TRUNCATE TABLE bronze.crm_sales_details;
        TRUNCATE TABLE bronze.erp_cust_az12;
        TRUNCATE TABLE bronze.erp_loc_a101;
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        EXEC sys.sp_executesql @sql;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

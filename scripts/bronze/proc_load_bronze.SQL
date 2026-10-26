/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Pass the datasets directory as @source_root. SQL Server's service account must
be able to read that directory. Each call performs a full refresh.
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze
    @source_root NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@source_root)), N'') IS NULL
        THROW 50001, 'Provide @source_root, the directory containing source_crm and source_erp.', 1;

    SET @source_root = RTRIM(@source_root);
    WHILE RIGHT(@source_root, 1) IN (N'\', N'/')
        SET @source_root = LEFT(@source_root, LEN(@source_root) - 1);

    DECLARE @file_path NVARCHAR(4000), @bulk_command NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;
        PRINT 'Loading Bronze Layer';

        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;
        PRINT '>> Inserting Data Into: bronze.crm_cust_info';
        SET @file_path = @source_root + N'\source_crm\cust_info.csv';
        SET @bulk_command = N'BULK INSERT bronze.crm_cust_info FROM ''' + REPLACE(@file_path, N'''', N'''''') + N''' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);';
        EXEC sys.sp_executesql @bulk_command;

        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;
        PRINT '>> Inserting Data Into: bronze.crm_prd_info';
        SET @file_path = @source_root + N'\source_crm\prd_info.csv';
        SET @bulk_command = N'BULK INSERT bronze.crm_prd_info FROM ''' + REPLACE(@file_path, N'''', N'''''') + N''' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);';
        EXEC sys.sp_executesql @bulk_command;

        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;
        PRINT '>> Inserting Data Into: bronze.crm_sales_details';
        SET @file_path = @source_root + N'\source_crm\sales_details.csv';
        SET @bulk_command = N'BULK INSERT bronze.crm_sales_details FROM ''' + REPLACE(@file_path, N'''', N'''''') + N''' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);';
        EXEC sys.sp_executesql @bulk_command;

        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;
        PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
        SET @file_path = @source_root + N'\source_erp\CUST_AZ12.csv';
        SET @bulk_command = N'BULK INSERT bronze.erp_cust_az12 FROM ''' + REPLACE(@file_path, N'''', N'''''') + N''' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);';
        EXEC sys.sp_executesql @bulk_command;

        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;
        PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
        SET @file_path = @source_root + N'\source_erp\LOC_A101.csv';
        SET @bulk_command = N'BULK INSERT bronze.erp_loc_a101 FROM ''' + REPLACE(@file_path, N'''', N'''''') + N''' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);';
        EXEC sys.sp_executesql @bulk_command;

        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        SET @file_path = @source_root + N'\source_erp\PX_CAT_G1V2.csv';
        SET @bulk_command = N'BULK INSERT bronze.erp_px_cat_g1v2 FROM ''' + REPLACE(@file_path, N'''', N'''''') + N''' WITH (FORMAT = ''CSV'', FIRSTROW = 2, CODEPAGE = ''65001'', TABLOCK, KEEPNULLS);';
        EXEC sys.sp_executesql @bulk_command;

        COMMIT TRANSACTION;
        PRINT 'Loading Bronze Layer is Completed';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        PRINT 'Bronze load failed: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Create the schemas once. Bronze stores source-shaped rows and intentionally has no keys.
IF OBJECT_ID(N'bronze.crm_cust_info', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_cust_info (
        cst_id INT NULL,
        cst_key NVARCHAR(50) NULL,
        cst_firstname NVARCHAR(50) NULL,
        cst_lastname NVARCHAR(50) NULL,
        cst_marital_status NVARCHAR(50) NULL,
        cst_gndr NVARCHAR(50) NULL,
        cst_create_date DATE NULL
    );
END;
GO

IF OBJECT_ID(N'bronze.crm_prd_info', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_prd_info (
        prd_id INT NULL,
        prd_key NVARCHAR(50) NULL,
        prd_nm NVARCHAR(100) NULL,
        prd_cost DECIMAL(19,4) NULL,
        prd_line NVARCHAR(50) NULL,
        prd_start_dt DATETIME2 NULL,
        prd_end_dt DATETIME2 NULL
    );
END;
GO

IF OBJECT_ID(N'bronze.crm_sales_details', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_sales_details (
        sls_ord_num NVARCHAR(50) NULL,
        sls_prd_key NVARCHAR(50) NULL,
        sls_cust_id INT NULL,
        sls_order_dt INT NULL,
        sls_ship_dt INT NULL,
        sls_due_dt INT NULL,
        sls_sales DECIMAL(19,4) NULL,
        sls_quantity INT NULL,
        sls_price DECIMAL(19,4) NULL
    );
END;
GO

IF OBJECT_ID(N'bronze.erp_loc_a101', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_loc_a101 (
        cid NVARCHAR(50) NULL,
        cntry NVARCHAR(100) NULL
    );
END;
GO

IF OBJECT_ID(N'bronze.erp_cust_az12', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_cust_az12 (
        cid NVARCHAR(50) NULL,
        bdate DATE NULL,
        gen NVARCHAR(50) NULL
    );
END;
GO

IF OBJECT_ID(N'bronze.erp_px_cat_g1v2', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_px_cat_g1v2 (
        id NVARCHAR(50) NULL,
        cat NVARCHAR(100) NULL,
        subcat NVARCHAR(100) NULL,
        maintenance NVARCHAR(50) NULL
    );
END;
GO

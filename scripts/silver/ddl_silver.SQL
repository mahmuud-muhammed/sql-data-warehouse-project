-- Create Silver tables if they are not already present. Keys are enforced where the
-- source has a clear business key; the sales source has no separate line identifier.
IF OBJECT_ID(N'silver.crm_cust_info', N'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_cust_info (
        cst_id INT NOT NULL CONSTRAINT PK_silver_crm_cust_info PRIMARY KEY,
        cst_key NVARCHAR(50) NULL,
        cst_firstname NVARCHAR(50) NULL,
        cst_lastname NVARCHAR(50) NULL,
        cst_marital_status NVARCHAR(50) NOT NULL,
        cst_gndr NVARCHAR(50) NOT NULL,
        cst_create_date DATE NULL,
        dwh_create_date DATETIME2(0) NOT NULL
            CONSTRAINT DF_silver_crm_cust_info_dwh_create_date DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'silver.crm_prd_info', N'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_prd_info (
        prd_id INT NOT NULL CONSTRAINT PK_silver_crm_prd_info PRIMARY KEY,
        cat_id NVARCHAR(50) NULL,
        prd_key NVARCHAR(50) NOT NULL,
        prd_nm NVARCHAR(100) NULL,
        prd_cost DECIMAL(19,4) NULL,
        prd_line NVARCHAR(50) NOT NULL,
        prd_start_dt DATE NULL,
        prd_end_dt DATE NULL,
        dwh_create_date DATETIME2(0) NOT NULL
            CONSTRAINT DF_silver_crm_prd_info_dwh_create_date DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'silver.crm_sales_details', N'U') IS NULL
BEGIN
    CREATE TABLE silver.crm_sales_details (
        sls_ord_num NVARCHAR(50) NOT NULL,
        sls_prd_key NVARCHAR(50) NOT NULL,
        sls_cust_id INT NOT NULL,
        sls_order_dt DATE NULL,
        sls_ship_dt DATE NULL,
        sls_due_dt DATE NULL,
        sls_sales DECIMAL(19,4) NULL,
        sls_quantity INT NULL,
        sls_price DECIMAL(19,4) NULL,
        dwh_create_date DATETIME2(0) NOT NULL
            CONSTRAINT DF_silver_crm_sales_details_dwh_create_date DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'silver.erp_loc_a101', N'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_loc_a101 (
        cid NVARCHAR(50) NOT NULL,
        cntry NVARCHAR(100) NULL,
        dwh_create_date DATETIME2(0) NOT NULL
            CONSTRAINT DF_silver_erp_loc_a101_dwh_create_date DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'silver.erp_cust_az12', N'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_cust_az12 (
        cid NVARCHAR(50) NOT NULL,
        bdate DATE NULL,
        gen NVARCHAR(50) NOT NULL,
        dwh_create_date DATETIME2(0) NOT NULL
            CONSTRAINT DF_silver_erp_cust_az12_dwh_create_date DEFAULT SYSUTCDATETIME()
    );
END;
GO

IF OBJECT_ID(N'silver.erp_px_cat_g1v2', N'U') IS NULL
BEGIN
    CREATE TABLE silver.erp_px_cat_g1v2 (
        id NVARCHAR(50) NOT NULL,
        cat NVARCHAR(100) NULL,
        subcat NVARCHAR(100) NULL,
        maintenance NVARCHAR(50) NULL,
        dwh_create_date DATETIME2(0) NOT NULL
            CONSTRAINT DF_silver_erp_px_cat_g1v2_dwh_create_date DEFAULT SYSUTCDATETIME()
    );
END;
GO

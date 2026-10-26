-- Replace the old view-based dimensions with tables that keep their keys between loads.
IF OBJECT_ID(N'gold.fact_sales', N'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
IF OBJECT_ID(N'gold.dim_customers', N'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
IF OBJECT_ID(N'gold.dim_products', N'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

IF OBJECT_ID(N'gold.dim_customers', N'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_customers (
        customer_key INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_gold_dim_customers PRIMARY KEY,
        customer_id INT NOT NULL CONSTRAINT UQ_gold_dim_customers_customer_id UNIQUE,
        customer_number NVARCHAR(50) NULL,
        first_name NVARCHAR(50) NULL,
        last_name NVARCHAR(50) NULL,
        country NVARCHAR(100) NULL,
        marital_status NVARCHAR(50) NOT NULL,
        gender NVARCHAR(50) NOT NULL,
        birthdate DATE NULL,
        create_date DATE NULL
    );
END;
GO

IF OBJECT_ID(N'gold.dim_products', N'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_products (
        product_key INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_gold_dim_products PRIMARY KEY,
        product_id INT NOT NULL,
        product_number NVARCHAR(50) NOT NULL CONSTRAINT UQ_gold_dim_products_product_number UNIQUE,
        product_name NVARCHAR(100) NULL,
        category_id NVARCHAR(50) NULL,
        category NVARCHAR(100) NULL,
        subcategory NVARCHAR(100) NULL,
        maintenance NVARCHAR(50) NULL,
        cost DECIMAL(19,4) NULL,
        product_line NVARCHAR(50) NOT NULL,
        start_date DATE NULL
    );
END;
GO

IF OBJECT_ID(N'gold.dim_date', N'U') IS NULL
BEGIN
    CREATE TABLE gold.dim_date (
        date_key INT NOT NULL CONSTRAINT PK_gold_dim_date PRIMARY KEY,
        [date] DATE NOT NULL CONSTRAINT UQ_gold_dim_date_date UNIQUE,
        [year] SMALLINT NOT NULL,
        [quarter] TINYINT NOT NULL,
        [month] TINYINT NOT NULL,
        month_name NVARCHAR(20) NOT NULL,
        day_of_month TINYINT NOT NULL,
        day_of_week TINYINT NOT NULL,
        day_name NVARCHAR(20) NOT NULL
    );
END;
GO

-- Fact is a view over Silver sales and the persisted dimensions.
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT sd.sls_ord_num AS order_number,
       pr.product_key,
       cu.customer_key,
       CONVERT(INT, CONVERT(CHAR(8), sd.sls_order_dt, 112)) AS order_date_key,
       CONVERT(INT, CONVERT(CHAR(8), sd.sls_ship_dt, 112)) AS shipping_date_key,
       CONVERT(INT, CONVERT(CHAR(8), sd.sls_due_dt, 112)) AS due_date_key,
       sd.sls_order_dt AS order_date,
       sd.sls_ship_dt AS shipping_date,
       sd.sls_due_dt AS due_date,
       sd.sls_sales AS sales_amount,
       sd.sls_quantity AS quantity,
       sd.sls_price AS unit_price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON pr.product_number = sd.sls_prd_key
LEFT JOIN gold.dim_customers AS cu
    ON cu.customer_id = sd.sls_cust_id;
GO

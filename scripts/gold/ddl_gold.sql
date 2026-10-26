/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ci.cst_id                           AS customer_key,    -- Stable CRM key
    ci.cst_id                           AS customer_id,
    ci.cst_key                          AS customer_number,
    ci.cst_firstname                    AS first_name,
    ci.cst_lastname                     AS last_name,
    la.cntry                            AS country,
    ci.cst_marital_status               AS marital_status,
    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the primary source for gender
        ELSE COALESCE(ca.gen, 'n/a')               -- Fallback to ERP data
    END                                 AS gender,
    ca.bdate                            AS birthdate,
    ci.cst_create_date                  AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    pn.prd_key      AS product_key, -- Stable product number
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY prd_key ORDER BY prd_start_dt DESC, prd_id DESC) AS row_num
    FROM silver.crm_prd_info
) pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.row_num = 1; -- Keep the latest version, including discontinued products
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    CONVERT(INT, CONVERT(CHAR(8), sd.sls_order_dt, 112)) AS order_date_key,
    CONVERT(INT, CONVERT(CHAR(8), sd.sls_ship_dt, 112))  AS shipping_date_key,
    CONVERT(INT, CONVERT(CHAR(8), sd.sls_due_dt, 112))   AS due_date_key,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO

-- Calendar dimension; gold.load_date_dimension adds dates from Silver sales.
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

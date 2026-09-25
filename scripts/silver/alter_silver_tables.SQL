/*
===============================================================
Adjust Silver Tables Before Cleaning
===============================================================
While checking the bronze data, I found that the silver tables
needed a few changes before the cleaning could work:

  1. crm_prd_info needs a new column (cat_id), because the
     category ID is inside prd_key and has to be split out.
  2. The product start and end dates only need the date, not the time.
  3. The sales dates come in as numbers like 20240131, so the
     columns must be DATE to hold the cleaned values.

Run this once, after creating the silver tables and before
creating the load procedure.
===============================================================
*/

-- 1. Add a column for the category ID
ALTER TABLE silver.crm_prd_info
ADD cat_id NVARCHAR(50);
GO

-- 2. Product dates: keep the date only
ALTER TABLE silver.crm_prd_info
ALTER COLUMN prd_start_dt DATE;

ALTER TABLE silver.crm_prd_info
ALTER COLUMN prd_end_dt DATE;
GO

-- 3. Sales dates: SQL Server can't turn INT into DATE directly,
--    so drop the old columns and add them again as DATE
--    (the table is still empty at this point, so nothing is lost)
ALTER TABLE silver.crm_sales_details
DROP COLUMN sls_order_dt, sls_ship_dt, sls_due_dt;

ALTER TABLE silver.crm_sales_details
ADD sls_order_dt DATE,
    sls_ship_dt  DATE,
    sls_due_dt   DATE;
GO

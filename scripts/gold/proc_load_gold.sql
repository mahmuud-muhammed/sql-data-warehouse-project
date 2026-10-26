CREATE OR ALTER PROCEDURE gold.load_gold
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- CRM is the preferred source for gender; use ERP where CRM has no value.
        ;WITH customer_source AS (
            SELECT ci.cst_id AS customer_id,
                   ci.cst_key AS customer_number,
                   ci.cst_firstname AS first_name,
                   ci.cst_lastname AS last_name,
                   la.cntry AS country,
                   ci.cst_marital_status AS marital_status,
                   CASE WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr ELSE COALESCE(ca.gen, 'n/a') END AS gender,
                   ca.bdate AS birthdate,
                   ci.cst_create_date AS create_date,
                   ROW_NUMBER() OVER (
                       PARTITION BY ci.cst_id
                       ORDER BY ca.bdate DESC, la.cntry, ca.gen, ci.cst_key,
                                ci.cst_firstname, ci.cst_lastname,
                                ci.cst_marital_status, ci.cst_gndr, ci.cst_create_date DESC
                   ) AS rn
            FROM silver.crm_cust_info AS ci
            LEFT JOIN silver.erp_cust_az12 AS ca
                ON ci.cst_key = ca.cid
            LEFT JOIN silver.erp_loc_a101 AS la
                ON ci.cst_key = la.cid
        )
        MERGE gold.dim_customers WITH (HOLDLOCK) AS target
        USING (SELECT * FROM customer_source WHERE rn = 1) AS source
            ON target.customer_id = source.customer_id
        WHEN MATCHED THEN UPDATE SET
            customer_number = source.customer_number,
            first_name = source.first_name,
            last_name = source.last_name,
            country = source.country,
            marital_status = source.marital_status,
            gender = source.gender,
            birthdate = source.birthdate,
            create_date = source.create_date
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (customer_id, customer_number, first_name, last_name, country,
                    marital_status, gender, birthdate, create_date)
            VALUES (source.customer_id, source.customer_number, source.first_name,
                    source.last_name, source.country, source.marital_status,
                    source.gender, source.birthdate, source.create_date);

        -- Pick the newest record for every product number. Keeping discontinued products
        -- lets older sales lines still resolve to a product in the fact view.
        ;WITH product_source AS (
            SELECT pn.prd_id AS product_id,
                   pn.prd_key AS product_number,
                   pn.prd_nm AS product_name,
                   pn.cat_id AS category_id,
                   pc.cat AS category,
                   pc.subcat AS subcategory,
                   pc.maintenance,
                   pn.prd_cost AS cost,
                   pn.prd_line AS product_line,
                   pn.prd_start_dt AS start_date,
                   ROW_NUMBER() OVER (
                       PARTITION BY pn.prd_key
                       ORDER BY pn.prd_start_dt DESC, pn.prd_id DESC
                   ) AS rn
            FROM silver.crm_prd_info AS pn
            LEFT JOIN silver.erp_px_cat_g1v2 AS pc
                ON pn.cat_id = pc.id
        )
        MERGE gold.dim_products WITH (HOLDLOCK) AS target
        USING (SELECT * FROM product_source WHERE rn = 1) AS source
            ON target.product_number = source.product_number
        WHEN MATCHED THEN UPDATE SET
            product_id = source.product_id,
            product_name = source.product_name,
            category_id = source.category_id,
            category = source.category,
            subcategory = source.subcategory,
            maintenance = source.maintenance,
            cost = source.cost,
            product_line = source.product_line,
            start_date = source.start_date
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (product_id, product_number, product_name, category_id, category,
                    subcategory, maintenance, cost, product_line, start_date)
            VALUES (source.product_id, source.product_number, source.product_name,
                    source.category_id, source.category, source.subcategory,
                    source.maintenance, source.cost, source.product_line, source.start_date);

        -- Fill the calendar continuously so all three sales date roles are available.
        DECLARE @min_date DATE, @max_date DATE;
        SELECT @min_date = MIN(d), @max_date = MAX(d)
        FROM (
            SELECT sls_order_dt AS d FROM silver.crm_sales_details
            UNION ALL SELECT sls_ship_dt FROM silver.crm_sales_details
            UNION ALL SELECT sls_due_dt FROM silver.crm_sales_details
        ) AS all_dates;

        IF @min_date IS NOT NULL
        BEGIN
            ;WITH dates AS (
                SELECT @min_date AS d
                UNION ALL
                SELECT DATEADD(day, 1, d)
                FROM dates
                WHERE d < @max_date
            )
            INSERT INTO gold.dim_date (
                date_key, [date], [year], [quarter], [month], month_name,
                day_of_month, day_of_week, day_name
            )
            SELECT CONVERT(INT, CONVERT(CHAR(8), d, 112)),
                   d,
                   YEAR(d),
                   DATEPART(quarter, d),
                   MONTH(d),
                   DATENAME(month, d),
                   DAY(d),
                   (DATEDIFF(day, CONVERT(DATE, '19000101', 112), d) % 7) + 1,
                   DATENAME(weekday, d)
            FROM dates AS src
            WHERE NOT EXISTS (
                SELECT 1 FROM gold.dim_date AS tgt WHERE tgt.[date] = src.d
            )
            OPTION (MAXRECURSION 0);
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

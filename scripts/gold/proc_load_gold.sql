CREATE OR ALTER PROCEDURE gold.load_date_dimension
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @first_date DATE, @last_date DATE;
    SELECT @first_date = MIN(d), @last_date = MAX(d)
    FROM (
        SELECT sls_order_dt AS d FROM silver.crm_sales_details
        UNION ALL SELECT sls_ship_dt FROM silver.crm_sales_details
        UNION ALL SELECT sls_due_dt FROM silver.crm_sales_details
    ) AS sales_dates;

    IF @first_date IS NULL RETURN;

    ;WITH calendar_dates AS (
        SELECT @first_date AS d
        UNION ALL
        SELECT DATEADD(day, 1, d)
        FROM calendar_dates
        WHERE d < @last_date
    )
    INSERT INTO gold.dim_date (
        date_key, [date], [year], [quarter], [month], month_name,
        day_of_month, day_of_week, day_name
    )
    SELECT CONVERT(INT, CONVERT(CHAR(8), d, 112)),
           d, YEAR(d), DATEPART(quarter, d), MONTH(d), DATENAME(month, d),
           DAY(d), (DATEDIFF(day, CONVERT(DATE, '19000101', 112), d) % 7) + 1,
           DATENAME(weekday, d)
    FROM calendar_dates AS src
    WHERE NOT EXISTS (SELECT 1 FROM gold.dim_date AS tgt WHERE tgt.[date] = src.d)
    OPTION (MAXRECURSION 0);
END;
GO

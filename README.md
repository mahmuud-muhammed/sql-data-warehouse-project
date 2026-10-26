# SQL Data Warehouse Project

This repository loads the supplied CRM and ERP CSV extracts into a SQL Server warehouse. The Gold layer supports product, customer, and sales trend analysis.

The input contains 60,398 sales rows and 397 product records. The sales grain in this sample is one row per order and product. The files do not include a separate order-line ID, so a future source that repeats a product on one order will need a line identifier.

## Layers

- **Bronze** keeps the CSV fields in source form.
- **Silver** cleans customer and product records, standardizes ERP values, converts sales dates, and reconciles sales and unit price.
- **Gold** exposes customer, product, and sales views plus a calendar table.

The customer dimension uses `cst_id` as its stable key. The product dimension uses the normalized product number as its stable key. These are source keys rather than generated surrogate keys, so they do not shift when rows are added to the views. Product attributes use the latest source version for each product number, including discontinued products, so the supplied sales rows can still join.

## Setup

Requirements: SQL Server 2017 or later on Windows, SSMS or another client that supports `GO`, and read access for the SQL Server service account to the repository's `datasets` folder.

1. Run `scripts/init.database.sql`.
2. In `DataWH`, run `scripts/bronze/ddl_bronze.SQL` and `scripts/silver/ddl_silver.SQL`.
3. Run `scripts/migrations/001_upgrade_warehouse.sql`, then `scripts/silver/alter_silver_tables.SQL`. Both are safe to rerun.
4. Run `scripts/gold/ddl_gold.sql`.
5. Create the load procedures by running `scripts/bronze/proc_load_bronze.SQL`, `scripts/silver/proc_load_silver.SQL`, and `scripts/gold/proc_load_gold.sql`.
6. Load and transform the data. Point `@source_root` to the `datasets` folder, which contains `source_crm` and `source_erp`:

   ```sql
   EXEC bronze.load_bronze @source_root = N'C:\path\to\sql-data-warehouse-project\datasets';
   EXEC silver.load_silver;
   EXEC gold.load_date_dimension;
   ```

7. Run `tests/quality_checks_silver.sql` and `tests/quality_checks_gold.sql`. Review any rows they return.
8. Run the queries in `analysis/`.

The load procedures do full refreshes. Run the Bronze and Silver DDL scripts before loading data; they drop and recreate their tables.

## Analysis

- `analysis/sales_trends.sql` reports monthly revenue, distinct order count, units, and revenue per order.
- `analysis/product_performance.sql` compares revenue and units by product and category.
- `analysis/customer_behavior.sql` shows order frequency, revenue in the supplied period, and repeat customers.

Order counts use distinct order numbers, not fact rows. The customer query describes purchases in this dataset, not lifetime customer value. These are SQL analyses; a dashboard is not included yet.

## Files

- `datasets/` — sample CRM and ERP extracts
- `docs/requirements.md` — project scope and reporting questions
- `docs/data_model.md` — key choices, grain, and KPI definitions
- `scripts/` — database setup, layer DDL, schema migration, and load procedures
- `tests/` — data quality and reconciliation queries
- `analysis/` — business analysis queries

The included extracts contain customer names, dates of birth, and gender fields. They are sample data; do not replace them with production customer records before publishing.

## License

MIT. See [LICENSE](LICENSE).

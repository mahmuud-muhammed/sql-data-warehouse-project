/* Create DataWH and the three layer schemas when they do not already exist. */
USE master;
GO

IF DB_ID(N'DataWH') IS NULL
    EXEC(N'CREATE DATABASE DataWH;');
GO

USE DataWH;
GO

IF SCHEMA_ID(N'bronze') IS NULL EXEC(N'CREATE SCHEMA bronze;');
IF SCHEMA_ID(N'silver') IS NULL EXEC(N'CREATE SCHEMA silver;');
IF SCHEMA_ID(N'gold') IS NULL EXEC(N'CREATE SCHEMA gold;');
GO

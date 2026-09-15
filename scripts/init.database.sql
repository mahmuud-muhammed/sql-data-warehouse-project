/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWH' , the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
*/

Use master;
GO

-- Create the 'DataWH' database
CREATE DATABASE DataWH;
GO

USE DataWH;
GO

-- Create Schemas
CREATE SCHEMA Bronze;
GO
  
CREATE SCHEMA Silver;
GO
  
CREATE SCHEMA Gold;
GO

/* =============================================================================
   Create the database and the bronze (raw) tables.

   What this script does:
     1. Creates a new database called  VLineDataWarehouse
     2. Creates three schemas:  bronze (raw), silver (clean), gold (analytics)
     3. Creates the 11 bronze tables — one for each GTFS .txt file.
        Every column is VARCHAR so the data loads safely no matter what's in it.
       

   HOW TO RUN:
     - Open SQL Server Management Studio (SSMS)
     - Connect to your local server  (e.g.  localhost\SQLEXPRESS )
     - Open this file
     - Press F5
   ============================================================================= */

USE master;
GO
-- ---------------------------------------------------------------------------
-- 1. Create the database (if it doesn't already exist)
-- ---------------------------------------------------------------------------

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'VlineDataWarehouse')
BEGIN
    ALTER DATABASE VlineDataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE VlineDataWarehouse;
END;
GO

CREATE DATABASE VLineDataWarehouse;
GO

USE VLineDataWarehouse;
GO


-- ---------------------------------------------------------------------------
-- 2. Create the three medallion schemas
-- ---------------------------------------------------------------------------
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO





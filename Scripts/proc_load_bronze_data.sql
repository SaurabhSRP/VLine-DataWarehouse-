/*
===============================================================================
Stored Procedure: Load Bronze data (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze_data;
===============================================================================
*/




CREATE OR ALTER PROCEDURE bronze.load_bronze_data AS 
BEGIN
    DECLARE @start_time DATETIME,@end_time DATETIME

    PRINT 'Loading agency.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.agency;
    BULK INSERT bronze.agency
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\agency.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading routes.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.routes;
    BULK INSERT bronze.routes
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\routes.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading calendar.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.calendar;
    BULK INSERT bronze.calendar
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\calendar.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading calendar_dates.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.calendar_dates;
    -- This file is empty in your feed — we wrap it in TRY/CATCH so the script
    -- keeps going if BULK INSERT complains about an empty file.
    BEGIN TRY
        BULK INSERT bronze.calendar_dates
        FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\calendar_dates.txt'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    END TRY
    BEGIN CATCH
        PRINT '  (file is empty, skipping)';
    END CATCH
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading levels.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.levels;
    BULK INSERT bronze.levels
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\levels.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading stops.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.stops;
    BULK INSERT bronze.stops
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\stops.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading trips.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.trips;
    BULK INSERT bronze.trips
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\trips.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading stop_times.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.stop_times;
    BULK INSERT bronze.stop_times
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\stop_times.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading shapes.txt (commit 50,000rows since ~1.5 million rows exist)';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.shapes;
    BULK INSERT bronze.shapes
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\shapes.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001',
          BATCHSIZE=50000, TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'
    -- BATCHSIZE=50000 means SQL Server commits every 50,000 rows so the
    -- transaction log doesn't grow huge.

    PRINT 'Loading pathways.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.pathways;
    BULK INSERT bronze.pathways
    FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\pathways.txt'
    WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'

    PRINT 'Loading transfers.txt';
    SET @start_time = GETDATE();
    TRUNCATE TABLE bronze.transfers;
    BEGIN TRY
        BULK INSERT bronze.transfers
        FROM 'C:\Users\Public\Documents\PTV DataWarehouse\data\transfers.txt'
        WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', CODEPAGE='65001', TABLOCK);
    END TRY
    BEGIN CATCH
        PRINT '  (file is empty, skipping)';
    END CATCH
    SET @end_time = GETDATE();
    PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------'


END

EXEC bronze.load_bronze_data;



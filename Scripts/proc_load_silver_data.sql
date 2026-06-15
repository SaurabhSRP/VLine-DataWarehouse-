/*
===============================================================================
Stored Procedure: Load Silver data (Bronze -> Silver)
===============================================================================
What this script does:
     Takes the 5 most important bronze tables, casts the VARCHAR data into
     proper types (numbers, dates, booleans), and saves the cleaned result
     into the silver schema.

   The other 6 bronze tables (agency, calendar_dates, levels, shapes,
   pathways, transfers) stay in bronze — they're either tiny, empty, or
   reference-only, so they don't need a silver version.

===============================================================================
*/








CREATE OR ALTER PROCEDURE silver.load_silver_data AS
BEGIN
	DECLARE @start_time DATETIME,@end_time DATETIME

	PRINT '----------------------------------------------';
	PRINT 'insert bronze.routes in silver.routes';
	SET @start_time = GETDATE();
	TRUNCATE TABLE silver.routes;
	INSERT INTO silver.routes (
		route_id,
		route_short_name,
		route_long_name,
		route_color	
	)
	SELECT
		route_id,
		route_short_name,
		route_long_name,
		route_color
	FROM bronze.routes
	SET @end_time = GETDATE();
	PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------';

	PRINT '------------------------------------------';
	PRINT 'insert bronze.stops in silver.stops';
	SET @start_time = GETDATE();
	TRUNCATE TABLE silver.stops;
	INSERT INTO silver.stops (
		stop_id, 
		stop_name, 
		stop_lat, 
		stop_lon, 
		parent_station, 
		wheelchair_boarding
		)
	SELECT
		stop_id,
		stop_name,
		TRY_CAST(stop_lat AS DECIMAL(10,7)) AS stop_lat,
		TRY_CAST(stop_lon AS DECIMAL(10,7)) AS stop_lon,
		COALESCE(PARSENAME(REPLACE(parent_station,':','.'),1), PARSENAME(REPLACE(stop_id,':','.'),1)) AS parent_station,
		CASE 
			WHEN wheelchair_boarding = 1 THEN 'Yes'
			WHEN wheelchair_boarding = 2 THEN 'No'
			WHEN wheelchair_boarding IS NULL THEN 'n/a'
		END AS wheelchair_boarding
	FROM bronze.stops;
	SET @end_time = GETDATE();
	PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------';



	PRINT '------------------------------------------';
	PRINT 'insert bronze.calendar in silver.calendar';
	SET @start_time = GETDATE();
	TRUNCATE TABLE silver.calendar;
	INSERT INTO silver.calendar (
		service_id,
		monday,
		tuesday,
		wednesday,
		thursday,
		friday,
		saturday,
		sunday,
		start_date,
		end_date 
		)

	SELECT
		service_id,
		CAST(monday    AS BIT) AS monday,
		CAST(tuesday   AS BIT) AS tuesday,
		CAST(wednesday AS BIT) AS wednesday,
		CAST(thursday  AS BIT) AS thursday,
		CAST(friday    AS BIT) AS friday,
		CAST(saturday  AS BIT) AS saturday,
		CAST(sunday    AS BIT) AS sunday,
		TRY_CONVERT(DATE, start_date, 112) AS start_date,
		TRY_CONVERT(DATE, end_date, 112) AS end_date
	FROM bronze.calendar;
	SET @end_time = GETDATE();
	PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------';












	PRINT '------------------------------------------';
	PRINT 'insert bronze.trips in silver.trips';
	SET @start_time = GETDATE();
	TRUNCATE TABLE silver.trips;
	INSERT INTO silver.trips (
		trip_id,
		route_id,
		service_id,
		trip_headsign,
		direction_id,
		wheelchair_accessible,
		bikes_allowed
		)
	SELECT 
		trip_id,
		route_id,
		service_id,
		trip_headsign,
		CASE
			WHEN direction_id=0 THEN 'outbound'
			WHEN direction_id=1 THEN 'inbound'
		END AS direction_id  ,
		CASE 
			WHEN wheelchair_accessible = 1 THEN 'Yes'
			WHEN wheelchair_accessible = 2 THEN 'No'
			WHEN wheelchair_accessible IS NULL THEN 'n/a'
		END AS wheelchair_accessible,
		CASE
			WHEN bikes_allowed = 1 THEN 'Yes'
			WHEN bikes_allowed = 2 THEN 'No'
			WHEN bikes_allowed IS NULL THEN 'n/a'
		END
	FROM bronze.trips;
	SET @end_time = GETDATE();
	PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------';

	PRINT '------------------------------------------';
	PRINT 'insert bronze.stops_times in silver.stops_times';
	SET @start_time = GETDATE();
	TRUNCATE TABLE silver.stop_times;
	INSERT INTO silver.stop_times (
		trip_id,
		stop_sequence,
		stop_id,
		arrival_seconds,
		departure_seconds,
		distance_meters
		)
	SELECT
		trip_id,
		TRY_CAST(stop_sequence AS SMALLINT) AS stop_sequence,
		stop_id,
		TRY_CAST(PARSENAME(REPLACE(arrival_time,':','.'), 3) AS INT) * 3600 +
		TRY_CAST(PARSENAME(REPLACE(arrival_time,':','.'), 2) AS INT) * 60 +
		TRY_CAST(PARSENAME(REPLACE(arrival_time,':','.'), 1) AS INT) AS arrival_seconds,

		TRY_CAST(PARSENAME(REPLACE(departure_time,':','.'), 3) AS INT) * 3600 +
		TRY_CAST(PARSENAME(REPLACE(departure_time,':','.'), 2) AS INT) * 60 +
		TRY_CAST(PARSENAME(REPLACE(departure_time,':','.'), 1) AS INT) AS departure_seconds,

		TRY_CAST(shape_dist_traveled AS DECIMAL(12,2)) AS distance_meters
	FROM bronze.stop_times ;
	SET @end_time = GETDATE();
	PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------';
END
GO





















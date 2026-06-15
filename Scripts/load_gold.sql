/* =============================================================================
    Build the gold (star schema) layer for analytics.

   What this script does:
     Builds a classic "star schema" — one big fact table in the middle,
     surrounded by smaller dimension tables that describe what each
     measurement is about.


   Each dimension has a "surrogate key" (a simple integer 1, 2, 3, ...)
   created automatically by IDENTITY. The fact table uses these integer
   keys to link to the dimensions — much faster than joining on text.
   ============================================================================= */


DECLARE @start_time DATETIME ,@end_time DATETIME;
PRINT '----------------------------------------------';
SET @start_time = GETDATE();
IF OBJECT_ID('gold.dim_date','U') IS NOT NULL
	DROP TABLE gold.dim_date;


CREATE TABLE gold.dim_date (
	date_key INT PRIMARY KEY,
	full_date DATE NOT NULL,
	year	SMALLINT,
	quarter TINYINT,
	month	TINYINT,
	month_name VARCHAR(30),
	day_of_month	TINYINT,
	day_of_week	TINYINT,
	day_name	VARCHAR(20),
	is_weekend	BIT
		);

DECLARE @start_date DATE = (SELECT MIN(start_date) FROM silver.calendar);
DECLARE @end_date DATE=(SELECT MAX(end_date) FROM silver.calendar);
DECLARE @d DATE=@start_date;

TRUNCATE TABLE gold.dim_date;
WHILE @d <= @end_date
BEGIN
	INSERT INTO gold.dim_date
	VALUES (
		CONVERT(INT,CONVERT(VARCHAR(8),@d,112)),
		@d,
		YEAR(@d),
		DATEPART(QUARTER,@d),
		MONTH(@d),
		DATENAME(MONTH,@d),
		DAY(@d),
		CASE DATENAME(WEEKDAY, @d)
			WHEN 'Monday'    THEN 1
			WHEN 'Tuesday'   THEN 2
			WHEN 'Wednesday' THEN 3
			WHEN 'Thursday'  THEN 4
			WHEN 'Friday'    THEN 5
			WHEN 'Saturday'  THEN 6
			WHEN 'Sunday'    THEN 7
		END,
		DATENAME(WEEKDAY,@d),
		CASE 
			WHEN DATENAME(WEEKDAY,@d) IN ('Saturday','Sunday') THEN 1
			ELSE 0
		END
		);
		SET @d = DATEADD(DAY, 1, @d);
END
	SET @end_time = GETDATE();
	PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '------------------------------------------';

-- ===========================================================================
-- DIMENSION 2: dim_route
-- The 13 V/Line routes, with origin and destination parsed out for easier
-- filtering in Power BI.
-- ===========================================================================
PRINT '----------------------------------------------';
SET @start_time = GETDATE();
IF OBJECT_ID('gold.dim_route','U') IS NOT NULL
	DROP TABLE gold.dim_route;


CREATE TABLE gold.dim_route(
	route_key INT IDENTITY(1,1) PRIMARY KEY,
	route_id VARCHAR(100) NOT NULL ,
	route_short_name VARCHAR(100),
	route_long_name VARCHAR(100),
	origin_town VARCHAR(100),
	destination_town VARCHAR(100),
	line_color_hex VARCHAR(10)
	);

TRUNCATE TABLE gold.dim_route;
INSERT INTO gold.dim_route(
	route_id,
	route_short_name,
	route_long_name,
	origin_town,
	destination_town,
	line_color_hex
	)
SELECT
	route_id,
	route_short_name,
	route_long_name,
	TRIM(LEFT(route_long_name,CHARINDEX(' - ',route_long_name)-1)),
	-- DESTINATION: text between " - " and " Via "
    TRIM(SUBSTRING(
        route_long_name,
        CHARINDEX(' - ', route_long_name) + 3,                                 -- start after " - "
        CHARINDEX(' Via ', route_long_name) - CHARINDEX(' - ', route_long_name) - 3
    )) ,
	route_color
FROM silver.routes;
SET @end_time = GETDATE();
PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
PRINT '------------------------------------------';

-- ===========================================================================
-- DIMENSION 3: dim_stop
-- The 641 train stations.
-- ===========================================================================

PRINT '----------------------------------------------';
SET @start_time = GETDATE();
IF OBJECT_ID('gold.dim_stops','U') IS NOT NULL
	DROP TABLE gold.dim_stops;



CREATE TABLE gold.dim_stops (
	stop_key INT IDENTITY(1,1) PRIMARY KEY,
	stop_id VARCHAR(50) NOT NULL,
	stop_name VARCHAR(200),
	stop_lat DECIMAL(10,7),
	stop_lon DECIMAL(10,7),
	wheelchair_boarding VARCHAR(10)
	);


TRUNCATE TABLE gold.dim_stops;
INSERT INTO gold.dim_stops(stop_id,stop_name,stop_lat,stop_lon,wheelchair_boarding)
SELECT stop_id,stop_name,stop_lat,stop_lon,wheelchair_boarding
FROM silver.stops;
SET @end_time = GETDATE();
PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
PRINT '------------------------------------------';

-- ===========================================================================
-- DIMENSION 4: dim_service_pattern
-- The 23 service patterns, with friendly labels like "Weekday Only"
-- ===========================================================================

PRINT '----------------------------------------------';
SET @start_time = GETDATE();
IF OBJECT_ID('gold.dim_service_days','U') IS NOT NULL
	DROP TABLE gold.dim_service_days;



CREATE TABLE gold.dim_service_days(
	service_pattern_key INT IDENTITY(1,1) PRIMARY KEY,
	service_id VARCHAR(50) NOT NULL,
	pattern_label VARCHAR(30),
	days_per_week TINYINT,
	start_date DATE,
	end_date DATE
	);

TRUNCATE TABLE gold.dim_service_days;
INSERT INTO gold.dim_service_days (service_id,pattern_label,days_per_week,start_date,end_date)
SELECT
	service_id,
	CASE
        WHEN saturday = 1 AND sunday = 1
             AND monday = 1 AND tuesday = 1 AND wednesday = 1
             AND thursday = 1 AND friday = 1   THEN 'Daily'
        WHEN saturday = 0 AND sunday = 0       THEN 'Weekday Only'
        WHEN saturday = 1 AND sunday = 0       THEN 'Saturday'
        WHEN saturday = 0 AND sunday = 1       THEN 'Sunday'
        WHEN saturday = 1 AND sunday = 1       THEN 'Weekend'
        ELSE 'Other'
    END,
	CAST(monday AS TINYINT) + tuesday + wednesday + thursday + friday + saturday + sunday,
	start_date,
	end_date
FROM silver.calendar;

SET @end_time = GETDATE();
PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
PRINT '------------------------------------------';

-- ===========================================================================
-- DIMENSION 5: dim_trip
-- The 6,182 trips. Links to route and service pattern via their surrogate keys.
-- ===========================================================================

PRINT '----------------------------------------------';
SET @start_time = GETDATE();
IF OBJECT_ID('gold.dim_trip','U') IS NOT NULL
	DROP TABLE gold.dim_trip;



CREATE TABLE gold.dim_trip (
	trip_key	INT IDENTITY(1,1) PRIMARY KEY,
	trip_id VARCHAR(100) NOT NULL,
	route_key INT,
	service_pattern_key INT,
	trip_headsign VARCHAR(100),
	direction_label VARCHAR(20),
	wheelchair_accessible VARCHAR(50),
	bikes_allowed VARCHAR(50)
	);

	TRUNCATE TABLE gold.dim_trip;
	INSERT INTO gold.dim_trip (trip_id,route_key,service_pattern_key,trip_headsign,direction_label,wheelchair_accessible,bikes_allowed)
	SELECT
		t.trip_id,
		r.route_key,
		sp.service_pattern_key,
		t.trip_headsign,
		t.direction_id,
		t.wheelchair_accessible,
		t.bikes_allowed
	FROM silver.trips t
	JOIN gold.dim_route r ON r.route_id = t.route_id
	JOIN gold.dim_service_days sp ON sp.service_id = t.service_id;

SET @end_time = GETDATE();
PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
PRINT '------------------------------------------';

	-- ===========================================================================
-- FACT TABLE: fact_stop_event
-- One row per trip stopping at a station.
-- "Measures" are the numbers we want to analyse (dwell time, distance,
-- what hour of the day it happened).
-- ===========================================================================

PRINT '----------------------------------------------';
SET @start_time = GETDATE();
IF OBJECT_ID('gold.fact_stop_event','U') IS NOT NULL
	DROP TABLE gold.fact_stop_event;



CREATE TABLE gold.fact_stop_event (
	stop_event_key INT IDENTITY(1,1) PRIMARY KEY,
	trip_key INT NOT NULL,
	stop_key INT NOT NULL,
	route_key INT NOT NULL,
	stop_sequence SMALLINT,
	arrival_seconds INT,
	departure_seconds INT,
	dwell_seconds INT, -- seconds between arrival and departure
	arrival_hour TINYINT, --0-23 hours
	distance_meters DECIMAL(12,2)
	);

TRUNCATE TABLE gold.fact_stop_event
INSERT INTO gold.fact_stop_event(trip_key ,stop_key ,route_key ,stop_sequence ,arrival_seconds ,departure_seconds ,
	dwell_seconds ,arrival_hour ,distance_meters)
SELECT
    dt.trip_key,
    ds.stop_key,
    dt.route_key,
    st.stop_sequence,
    st.arrival_seconds,
    st.departure_seconds,
    st.departure_seconds - st.arrival_seconds AS dwell_seconds,
    -- Convert seconds to hour 0-23 (use modulo for trips past midnight)
    (st.arrival_seconds / 3600) % 24 AS arrival_hour,
    st.distance_meters
FROM silver.stop_times st
JOIN gold.dim_trip dt ON dt.trip_id = st.trip_id
JOIN gold.dim_stops ds ON ds.stop_id = st.stop_id;
SET @end_time = GETDATE();
PRINT '>> load duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR) + 'seconds';
PRINT '------------------------------------------';
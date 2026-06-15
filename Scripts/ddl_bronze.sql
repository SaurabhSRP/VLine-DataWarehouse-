/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/


IF OBJECT_ID('bronze.agency','U') IS NOT NULL 
    DROP TABLE bronze.agency;
GO

CREATE TABLE bronze.agency (
    agency_id        VARCHAR(50),
    agency_name      VARCHAR(200),
    agency_url       VARCHAR(500),
    agency_timezone  VARCHAR(100),
    agency_lang      VARCHAR(10),
    agency_fare_url  VARCHAR(500),
);
GO




IF OBJECT_ID('bronze.routes','U')  IS NOT NULL 
    DROP TABLE bronze.routes;
GO

CREATE TABLE bronze.routes (
    route_id          VARCHAR(100),
    agency_id         VARCHAR(50),
    route_short_name  VARCHAR(100),
    route_long_name   VARCHAR(200),
    route_type        VARCHAR(10),
    route_color       VARCHAR(10),
    route_text_color  VARCHAR(10)
);

GO




IF OBJECT_ID('bronze.calendar','U') IS NOT NULL 
    DROP TABLE bronze.calendar;
GO

CREATE TABLE bronze.calendar(
    service_id   VARCHAR(50),
    monday       VARCHAR(1),
    tuesday      VARCHAR(1),
    wednesday    VARCHAR(1),
    thursday     VARCHAR(1),
    friday       VARCHAR(1),
    saturday     VARCHAR(1),
    sunday       VARCHAR(1),
    start_date   VARCHAR(8),
    end_date     VARCHAR(8)
);

GO


IF OBJECT_ID('bronze.calendar_dates','U') IS NOT NULL 
    DROP TABLE bronze.calendar_dates;
GO

CREATE TABLE bronze.calendar_dates (
    service_id          VARCHAR(50),
    [date]              VARCHAR(8),
    exception_type      VARCHAR(2)
);
GO

 


IF OBJECT_ID('bronze.levels','U')   IS NOT NULL 
    DROP TABLE bronze.levels;
GO

CREATE TABLE bronze.levels (
    level_id    VARCHAR(50),
    level_index VARCHAR(10),
    level_name  VARCHAR(100)
);
GO


IF OBJECT_ID('bronze.stops','U') IS NOT NULL 
    DROP TABLE bronze.stops;
GO

CREATE TABLE bronze.stops (
    stop_id              VARCHAR(50),
    stop_name            VARCHAR(200),
    stop_lat             VARCHAR(30),
    stop_lon             VARCHAR(30),
    stop_url             VARCHAR(500),
    location_type        VARCHAR(2),
    parent_station       VARCHAR(50),
    wheelchair_boarding  VARCHAR(2),
    level_id             VARCHAR(50)
);
GO


IF OBJECT_ID('bronze.trips','U') IS NOT NULL 
    DROP TABLE bronze.trips;
GO

CREATE TABLE bronze.trips (
    route_id              VARCHAR(100),
    service_id            VARCHAR(50),
    trip_id               VARCHAR(100),
    shape_id              VARCHAR(100),
    trip_headsign         VARCHAR(200),
    direction_id          VARCHAR(2),
    block_id              VARCHAR(50),
    wheelchair_accessible VARCHAR(2),
    bikes_allowed         VARCHAR(2)
);
GO


IF OBJECT_ID('bronze.stop_times','U') IS NOT NULL 
    DROP TABLE bronze.stop_times;
GO

CREATE TABLE bronze.stop_times (
    trip_id              VARCHAR(100),
    arrival_time         VARCHAR(10),
    departure_time       VARCHAR(10),
    stop_id              VARCHAR(50),
    stop_sequence        VARCHAR(10),
    stop_headsign        VARCHAR(200),
    pickup_type          VARCHAR(2),
    drop_off_type        VARCHAR(2),
    shape_dist_traveled  VARCHAR(30)
);
GO


IF OBJECT_ID('bronze.shapes','U') IS NOT NULL 
    DROP TABLE bronze.shapes;
GO

CREATE TABLE bronze.shapes (
    shape_id             VARCHAR(100),
    shape_pt_lat         VARCHAR(30),
    shape_pt_lon         VARCHAR(30),
    shape_pt_sequence    VARCHAR(10),
    shape_dist_traveled  VARCHAR(30)
);
GO


IF OBJECT_ID('bronze.pathways','U')       IS NOT NULL DROP TABLE bronze.pathways;

CREATE TABLE bronze.pathways (
    pathway_id        VARCHAR(200),
    from_stop_id      VARCHAR(50),
    to_stop_id        VARCHAR(50),
    pathway_mode      VARCHAR(2),
    is_bidirectional  VARCHAR(2),
    traversal_time    VARCHAR(10)
);
GO

IF OBJECT_ID('bronze.transfers','U')  IS NOT NULL 
    DROP TABLE bronze.transfers;
GO

CREATE TABLE bronze.transfers (
    from_stop_id      VARCHAR(50),
    to_stop_id        VARCHAR(50),
    from_route_id     VARCHAR(100),
    to_route_id       VARCHAR(100),
    from_trip_id      VARCHAR(100),
    to_trip_id        VARCHAR(100),
    transfer_type     VARCHAR(2),
    min_transfer_time VARCHAR(10)
);
GO


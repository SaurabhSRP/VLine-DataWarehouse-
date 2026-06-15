/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'Silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'Silver' Tables
===============================================================================
*/


IF OBJECT_ID('silver.routes' , 'U') IS NOT NULL
	DROP TABLE silver.routes ;
GO 

CREATE TABLE silver.routes (
	route_id VARCHAR(100) PRIMARY KEY,
	route_short_name VARCHAR(100),
	route_long_name VARCHAR(200),
	route_color VARCHAR(6)
	);

IF OBJECT_ID('silver.stops','U') IS NOT NULL 
	DROP TABLE silver.stops;
GO


CREATE TABLE silver.stops (
	stop_id VARCHAR(100) PRIMARY KEY,
	stop_name VARCHAR(200),
	stop_lat DECIMAL(10,7),
	stop_lon DECIMAL(10,7),
	parent_station VARCHAR(50),
	wheelchair_boarding VARCHAR(50)
	)

IF OBJECT_ID('silver.calendar','U') IS NOT NULL
	DROP TABLE silver.calendar;
GO

CREATE TABLE silver.calendar (
	service_id VARCHAR(50) PRIMARY KEY,
	monday BIT,
	tuesday BIT,
	wednesday BIT,
	thursday BIT,
	friday BIT,
	saturday BIT,
	sunday BIT,
	start_date DATE,
	end_date DATE
	);

IF OBJECT_ID('silver.trips','U') IS NOT NULL
	DROP TABLE silver.trips;
GO


CREATE TABLE silver.trips (
	trip_id	VARCHAR(100) PRIMARY KEY,
	route_id VARCHAR(100),
	service_id VARCHAR(50),
	trip_headsign VARCHAR(200),
	direction_id VARCHAR(100),
	wheelchair_accessible VARCHAR(50),
	bikes_allowed	VARCHAR(50)
	);



IF OBJECT_ID('silver.stop_times','U') IS NOT NULL
	DROP TABLE silver.stop_times;
GO

CREATE TABLE silver.stop_times (
	trip_id VARCHAR(100),
	stop_sequence SMALLINT,
	stop_id VARCHAR(50),
	arrival_seconds INT,
	departure_seconds INT,
	distance_meters DECIMAL(12,2),
	PRIMARY KEY (trip_id,stop_sequence)
	);





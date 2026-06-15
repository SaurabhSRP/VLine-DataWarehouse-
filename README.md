# V/Line GTFS Data Warehouse

A production-shaped data warehouse built on Microsoft SQL Server Express, implementing the medallion architecture (Bronze → Silver → Gold) over the Public Transport Victoria V/Line regional rail GTFS feed. The project transforms raw transit schedule data into a Kimball-style dimensional model suitable for analytical reporting.

![SQL Server](https://img.shields.io/badge/SQL%20Server-Express%202022-CC2927?logo=microsoftsqlserver&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-Stored%20Procedures-blue)
![Medallion](https://img.shields.io/badge/Architecture-Medallion-orange)
![License](https://img.shields.io/badge/Data%20License-CC%20BY%204.0-lightgrey)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Data Source](#data-source)
- [Technology Stack](#technology-stack)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Data Flow](#data-flow)
- [Data Model](#data-model)
- [Future Enhancements](#future-enhancements)
- [License and Attribution](#license-and-attribution)

---

## Overview

This project demonstrates the end-to-end design and implementation of an analytical data warehouse for public transit schedule data. The pipeline ingests 11 General Transit Feed Specification (GTFS) files published by Transport Victoria, applies progressive cleansing and conformance transformations across three architectural layers, and produces a business-ready star schema covering 13 routes, 641 stations, 6,182 trips, and approximately 82,000 scheduled stop events.

The warehouse supports analytical questions such as service density by route, peak-hour stop activity, accessibility coverage, schedule pattern composition, and dwell-time profiling across the V/Line regional network.

---

## Architecture

The warehouse follows the medallion (Bronze / Silver / Gold) architecture pattern, with each layer carrying explicit responsibilities and clear contracts between stages.

<p align="center">
  <img src="docs/images/01_data_architecture.png" alt="Data Architecture Diagram" width="100%"/>
</p>

| Layer | Purpose | Object Type | Transformations |
|-------|---------|-------------|-----------------|
| **Bronze** | Raw landing zone — preserves source fidelity | Tables (all `VARCHAR`) | None; data lands as-is with lineage columns |
| **Silver** | Cleansed, typed, validated, conformed | Tables with PK/FK enforcement | Type casting, time normalisation, referential integrity, derived columns |
| **Gold** | Business-ready dimensional model | Tables (star schema) | Surrogate key generation, business labels, aggregations |

Loading from source to bronze is implemented with `BULK INSERT` for maximum throughput. Transformations between bronze→silver are encapsulated in stored procedures using `TRUNCATE` + `INSERT` patterns for idempotent execution. The gold layer is constructed through a single deployment script that builds dimensions and the fact table from the silver model.

---

## Data Source

| Attribute | Detail |
|-----------|--------|
| **Publisher** | Public Transport Victoria (Department of Transport and Planning) |
| **Feed** | V/Line regional rail GTFS Schedule |
| **URL** | https://data.ptv.vic.gov.au/downloads/gtfs.zip |
| **Format** | Eleven `.txt` files in CSV format (GTFS standard) |
| **Update Frequency** | Monthly |
| **Licence** | Creative Commons Attribution 4.0 International |
| **Coverage** | 13 V/Line regional rail routes connecting Melbourne to regional Victorian centres |

The GTFS Schedule format is a forward-looking timetable specification, not a historical record. The pipeline can be re-run against updated feed downloads without schema modifications.

---

## Technology Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Microsoft SQL Server Express | 2022 | Database engine |
| SQL Server Management Studio (SSMS) | 19+ | Development environment |
| T-SQL | — | Schema definition, ETL logic, stored procedures |
| draw.io | — | Architecture and data model documentation |

---

## Repository Structure

```
vline-gtfs-warehouse/
├── README.md
├── docs/
│   └── images/
│       ├── 01_data_architecture.png
│       ├── 02_data_flow_lineage.png
│       └── 03_star_schema.png
├── data/
│   └── gtfs/                          # GTFS source files (not committed)
└── scripts/
    ├── init_database.sql              # Database and schema initialisation
    ├── ddl_bronze.sql                 # Bronze layer table definitions
    ├── proc_load_bronze_data.sql      # Stored procedure for bronze loading
    ├── ddl_silver.sql                 # Silver layer table definitions
    ├── proc_load_silver_data.sql      # Stored procedure for silver transformations
    └── load_gold.sql                  # Gold layer star schema construction
```

### Script Responsibilities

| Script | Responsibility |
|--------|----------------|
| `init_database.sql` | Creates the `VLineDW` database and the `bronze`, `silver`, `gold` schemas |
| `ddl_bronze.sql` | Defines the 11 bronze tables (one per GTFS file) with `VARCHAR` columns and lineage metadata |
| `proc_load_bronze_data.sql` | Creates `bronze.load_bronze_data` stored procedure that executes `BULK INSERT` for each GTFS file |
| `ddl_silver.sql` | Defines the silver layer tables with typed columns, primary keys, and foreign key constraints |
| `proc_load_silver_data.sql` | Creates `silver.load_silver_data` stored procedure containing all bronze→silver transformations |
| `load_gold.sql` | Builds the gold layer in a single deployment: drops, creates, and populates all dimensions and the fact table |

---

## Prerequisites

The following components must be installed before executing the pipeline:

- Microsoft SQL Server Express 2019 or 2022 (free edition)
- SQL Server Management Studio (SSMS) 19 or later
- Read access to a working directory containing the GTFS source files (default: `C:\GTFS\`)

The SQL Server service account requires `READ` permission on the directory containing the GTFS files. For default Express installations on Windows, this account is typically `NT Service\MSSQL$SQLEXPRESS`.

---

## Setup Instructions

### 1. Acquire the GTFS Source Files

Download the latest GTFS feed from the Transport Victoria open data portal:

```
https://data.ptv.vic.gov.au/downloads/gtfs.zip
```

Extract the eleven `.txt` files for the V/Line subset into a working directory (default: `C:\GTFS\`). The required files are:

```
agency.txt           levels.txt           shapes.txt
calendar.txt         pathways.txt         stops.txt
calendar_dates.txt   routes.txt           stop_times.txt
                                          transfers.txt
                                          trips.txt
```

### 2. Grant Filesystem Permissions

Right-click the source folder → **Properties** → **Security** → **Edit** → **Add** → grant `Read` permission to `NT Service\MSSQL$SQLEXPRESS`.

### 3. Execute the Pipeline Scripts in Order

Open each script in SSMS, ensure the active database context is correct, and execute (F5):

| Step | Script | Action |
|------|--------|--------|
| 1 | `init_database.sql` | Creates the `VLineDW` database and three medallion schemas |
| 2 | `ddl_bronze.sql` | Creates the 11 raw landing tables |
| 3 | `proc_load_bronze_data.sql` | Creates the bronze load procedure |
| 4 | `EXEC bronze.load_bronze_data` | Loads all 11 GTFS files via `BULK INSERT` |
| 5 | `ddl_silver.sql` | Creates the cleansed silver tables with referential integrity |
| 6 | `proc_load_silver_data.sql` | Creates the silver transformation procedure |
| 7 | `EXEC silver.load_silver_data` | Executes bronze→silver transformations |
| 8 | `load_gold.sql` | Builds the gold-layer star schema (5 dimensions + 1 fact) |

After successful execution, the warehouse contains approximately 1.6 million rows across all layers, with the analytical gold layer ready for downstream consumption.

---

## Data Flow

The diagram below traces each GTFS source file through the bronze and silver layers into the gold dimensional model:

<p align="center">
  <img src="docs/images/02_data_flow_lineage.png" alt="Data Flow Lineage Diagram" width="100%"/>
</p>

Reference-only tables (`agency`, `levels`, `shapes`, `pathways`) and empty feeds (`calendar_dates`, `transfers`) are retained in bronze for completeness but are not promoted to silver or gold, as they do not contribute to the analytical model.

---

## Data Model

The gold layer implements a classic Kimball-style star schema with a central fact table and five conformed dimensions:

<p align="center">
  <img src="docs/images/03_star_schema.png" alt="Star Schema Data Model" width="100%"/>
</p>

### Dimensions

| Table | Grain | Row Count | Description |
|-------|-------|-----------|-------------|
| `gold.dim_date` | One row per calendar day | ~3,650 | Date dimension covering the active calendar range, with AU financial-year attributes |
| `gold.dim_route` | One row per V/Line route | 13 | Routes with parsed origin/destination attributes |
| `gold.dim_stops` | One row per train-boarding stop | ~200 | Filtered to physical platforms (excludes station entrances, lifts, taxi ranks) |
| `gold.dim_service_pattern` | One row per service calendar | 23 | Day-of-week patterns with human-readable labels (`Daily`, `Weekday Only`, `Saturday`, `Sunday`, `Weekend`) |
| `gold.dim_trip` | One row per individual trip | 6,182 | Trips linked to route and service pattern via surrogate keys |

### Fact

| Table | Grain | Row Count | Description |
|-------|-------|-----------|-------------|
| `gold.fact_stop_event` | One row per trip × stop | ~82,000 | Scheduled stop events with arrival/departure seconds, dwell time, and arrival hour |



---

## Future Enhancements

The current implementation establishes the analytical foundation. The following extensions are planned or recommended:

- **Power BI semantic model and dashboard** — Connect Power BI Desktop to the gold layer via the SQL Server connector, define a star-schema semantic model with DAX measures, and publish operational dashboards covering service density, accessibility coverage, and peak-hour analysis.
- **GTFS-Realtime integration** — Ingest live vehicle positions and delay data to enable on-time performance analysis comparing scheduled (gold) against actual arrivals via a new fact table.
- **Public holiday dimension extension** — Enrich `dim_date` with Australian public holidays from `data.gov.au` for accurate weekday/holiday segmentation.
- **dbt migration** — Re-implement transformations as `dbt-mssql` models with declarative tests, lineage documentation, and CI/CD-friendly deployment.
- **Automated monthly refresh** — Schedule pipeline execution via Windows Task Scheduler or SQL Server Agent (on a non-Express edition) to coincide with PTV's monthly GTFS publication cadence.

---

## License and Attribution

### Source Data

GTFS feed © State of Victoria (Department of Transport and Planning), licensed under [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/).

### Project Code

This project is released under the [MIT License](LICENSE). All SQL and documentation may be used, modified, and redistributed with attribution.

### Acknowledgments

- Public Transport Victoria for publishing the GTFS feed as open data

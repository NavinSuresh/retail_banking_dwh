# Naming Conventions

This document outlines the naming conventions used for schemas, tables, views, columns, and other objects in the data warehouse.

## Table of Contents
1. [General Principles](#general-principles)
2. [Table Naming Conventions](#table-naming-conventions)
   - [Bronze Rules](#bronze-rules)
   - [Silver Rules](#silver-rules)
   - [Gold Rules](#gold-rules)
3. [Column Naming Conventions](#column-naming-conventions)
   - [Surrogate Keys](#surrogate-keys)
   - [Technical Columns](#technical-columns)
4. [Stored Procedures](#stored-procedures)

---

## General Principles
- **snake_case**: Use lowercase letters and underscores to separate words.
- **English**: Use English for all names.
- **Avoid Reserved Words**: Do not use SQL reserved words as object names.
- **Descriptive**: Names should convey meaning and context.

---

## Table Naming Conventions

### Bronze Rules
Tables represent raw data from source systems; all names reflect the origin.

```
<source_system>_<entity>
```
- `source_system`: Name of the source system ('cbs', 'tps', 'ref')
- `entity`: Exact name of the csv file from the source system
- Example: `tps_txn_log.csv`

### Silver Rules
Cleansed and conformed tables; same names as the bronze layer.

```
<source_system>_<entity>
```
- Example: `tps_txn_log.csv`

### Gold Rules
Business-ready star schema materialized views; all names should be meaningful and represent the business entity .

```
<table_role>_<entity>
```
- `table_role`: Describes whether the table is a Fact or Dimension table.
- `entity`: Descriptive and business aligned name (eg: 'customers', 'accounts')
- Example: `fact_transactions`

---

## Column Naming Conventions

### Surrogate Keys
All primary keys in dimension tables use the `_key` suffix.

```
<entity>_key
```
- Example: `customer_key` in `dim_customers`.

### Technical Columns
System metadata columns prefixed with `dwh_`, followed by a descriptive name indicating the column's purpose.

```
dwh_<description>
```
- Example: `dwh_load_date`

---

## Stored Procedures
Naming pattern for ETL stored procedures:

```
<layer>_load_sp
```
- `<layer>`: `bronze` or `silver`
- Example: `bronze_load_sp`


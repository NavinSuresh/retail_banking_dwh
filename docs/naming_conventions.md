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
Tables represent raw data from source systems; names reflect the origin.

```
<source>_<entity>
```
- `cbs_customer_master` (from `raw_customer.csv`)
- `cbs_account_master` (from `raw_accounts.csv`)
- `tps_transaction_log` (from `raw_transactions.csv`)
- `ref_transaction_codes` (from `transaction_code.csv`)
- `ref_branch_master` (from `raw_branch.csv`)

### Silver Rules
Cleansed and conformed tables; preserve source prefix and append `_silver`.

```
<source>_<entity>_silver
```
- `cbs_customer_master_silver`
- `tps_transaction_log_silver`

### Gold Rules
Business-ready star schema tables.

```
dim_<entity>
fact_<entity>
```
- `dim_customers`
- `dim_branches`
- `dim_accounts`
- `fact_transactions`

---

## Column Naming Conventions

### Surrogate Keys
All primary keys in dimension tables use the `_key` suffix.

```
<entity>_key
```
- Example: `customer_key` in `dim_customers`.

### Technical Columns
System metadata columns prefixed with `dwh_`.

```
dwh_<description>
```
- Example: `dwh_load_date`, `dwh_batch_id`

---

## Stored Procedures
Naming pattern for ETL stored procedures:

```
load_<layer>_<entity>
```
- `<layer>`: `bronze`, `silver`, or `gold`
- `<entity>`: target table name
- Examples:
  - `load_bronze_cbs_customer_master`
  - `load_silver_tps_transaction_log`
  - `load_gold_fact_transactions`

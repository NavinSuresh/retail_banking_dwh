/*
--------------------------------------
Create Gold Layer Materialized Views
--------------------------------------
Purpose:
	> Creates fact and dimension tables as materialized views following the Star Schema
	> Integrates silver layer tables for 'customers', 'accounts', and 'transactions' business entities
	> Generates surrogate keys to establish relationships between entities
Note:
	> The gold layer materialised views are optimised for BI/Analytics consumption
*/



-- 1. Dimension: gold.dim_customer

DROP MATERIALIZED VIEW IF EXISTS gold.dim_customer;
CREATE MATERIALIZED VIEW gold.dim_customer AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cust_id) AS customer_key,
    cust_id AS customer_id,
    cust_name AS full_name,
    cust_address AS address,
    cust_gender AS gender,
    cust_phone AS phone_number,
    cust_email AS email_id,
    cust_dob AS birthdate,
    cust_create_dt AS create_date
FROM silver.cbs_cust_master;

-- 2. Dimension: gold.dim_account

DROP MATERIALIZED VIEW IF EXISTS gold.dim_account;
CREATE MATERIALIZED VIEW gold.dim_account AS
SELECT
    ROW_NUMBER() OVER (ORDER BY acc_num) AS account_key,
    acc_num AS account_number,
    cust_id AS customer_id,     -- Only as a descriptive attribute, not a FK
    acc_type AS account_type,
    open_dt AS open_date,
    close_dt AS close_date,
    a.branch_id,
    branch_name,
    zone
FROM silver.cbs_acc_master a
LEFT JOIN silver.ref_branch_master b ON a.branch_id = b.branch_id
 
-- 3. Fact: gold.fact_transaction

DROP MATERIALIZED VIEW IF EXISTS gold.fact_transaction;
CREATE MATERIALIZED VIEW gold.fact_transaction AS
SELECT
    t.txn_id AS transaction_id,
    t.txn_dt AS transaction_date,
    dc.customer_key AS customer_key,
    da.account_key AS account_key,
    t.txn_type AS transaction_type,
    t.txn_code AS transaction_code,
	tc.subtype AS transaction_subtype,
	tc.channel AS transaction_channel,
    t.amnt AS amount,
    t.bal AS account_balance
FROM silver.tps_txn_log t
JOIN silver.ref_txn_codes tc ON t.txn_code = tc.txn_code
JOIN gold.dim_account da ON t.acc_num = da.account_number
JOIN gold.dim_customer dc ON da.customer_id = dc.customer_id;

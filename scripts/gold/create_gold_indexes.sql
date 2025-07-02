/*
------------------------------------------------
Create Indexes For Gold Layer Materialized Views
-------------------------------------------------

Purpose:
    > Creates indexes on Gold Layer materialized views to optimize query performance and support analytical workloads.
    > Adds unique indexes on surrogate keys and additional indexes on frequently queried or joined columns.
   
*/

-- 1. Dimension: gold.dim_customer

CREATE UNIQUE INDEX IF NOT EXISTS idx_dim_customer_customer_key
    ON gold.dim_customer (customer_key);

CREATE INDEX IF NOT EXISTS idx_dim_customer_customer_id
    ON gold.dim_customer (customer_id);

-- 2. Dimension: gold.dim_account

CREATE UNIQUE INDEX IF NOT EXISTS idx_dim_account_account_key
    ON gold.dim_account (account_key);

CREATE INDEX IF NOT EXISTS idx_dim_account_account_number
    ON gold.dim_account (account_number);

CREATE INDEX IF NOT EXISTS idx_dim_account_customer_id
    ON gold.dim_account (customer_id);

CREATE INDEX IF NOT EXISTS idx_dim_account_branch_id
    ON gold.dim_account (branch_id);

-- 3. Fact: gold.fact_transaction

CREATE INDEX IF NOT EXISTS idx_fact_transaction_customer_key
    ON gold.fact_transaction (customer_key);

CREATE INDEX IF NOT EXISTS idx_fact_transaction_account_key
    ON gold.fact_transaction (account_key);

CREATE INDEX IF NOT EXISTS idx_fact_transaction_transaction_date
    ON gold.fact_transaction (transaction_date);

CREATE INDEX IF NOT EXISTS idx_fact_transaction_transaction_type
    ON gold.fact_transaction (transaction_type);

CREATE INDEX IF NOT EXISTS idx_fact_transaction_transaction_code
    ON gold.fact_transaction (transaction_code);


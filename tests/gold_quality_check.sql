-- =======================================
-- Data Quality Checks: Gold Layer Views
-- =======================================

-- 1. Check for NULLs in surrogate keys (PKs)
-- ----------------------------

SELECT 'dim_customer' AS table_name, COUNT(*) AS null_pk_count
FROM gold.dim_customer
WHERE customer_key IS NULL

UNION ALL
SELECT 'dim_account', COUNT(*)
FROM gold.dim_account
WHERE account_key IS NULL

UNION ALL
SELECT 'fact_transaction', COUNT(*)
FROM gold.fact_transaction
WHERE transaction_id IS NULL;


-- 2. Check for duplicate business keys (customer_id, account_number, transaction_id)
-- ----------------------------

SELECT 'dim_customer' AS table_name, customer_id::TEXT, COUNT(*) AS dup_count
FROM gold.dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1

UNION ALL
SELECT 'dim_account', account_number::TEXT, COUNT(*)
FROM gold.dim_account
GROUP BY account_number
HAVING COUNT(*) > 1

UNION ALL
SELECT 'fact_transaction', transaction_id::TEXT, COUNT(*)
FROM gold.fact_transaction
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- 3. Referential Integrity Checks (fact â†’ dim)
-- ----------------------------

-- Orphan account_key
SELECT transaction_id, account_key
FROM gold.fact_transaction f
WHERE NOT EXISTS (
    SELECT 1 FROM gold.dim_account a WHERE a.account_key = f.account_key
);

-- Orphan customer_key
SELECT transaction_id, customer_key
FROM gold.fact_transaction f
WHERE NOT EXISTS (
    SELECT 1 FROM gold.dim_customer c WHERE c.customer_key = f.customer_key
);


-- 4. Business Logic Checks
-- ----------------------------

-- Negative transaction amounts (if unexpected)
SELECT *
FROM gold.fact_transaction
WHERE amount < 0

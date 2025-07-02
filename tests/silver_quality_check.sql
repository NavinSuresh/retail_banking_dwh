-- =======================================
-- Data Quality Checks: Silver Layer Tables
-- =======================================

-- 1. Check for NULLs in primary keys (PKs)
-- ----------------------------
SELECT 'cbs_cust_master' AS table_name, COUNT(*) AS null_pk_count
FROM silver.cbs_cust_master
WHERE cust_id IS NULL

UNION ALL
SELECT 'cbs_acc_master', COUNT(*)
FROM silver.cbs_acc_master
WHERE acc_num IS NULL OR cust_id IS NULL

UNION ALL
SELECT 'ref_branch_master', COUNT(*)
FROM silver.ref_branch_master
WHERE branch_id IS NULL

UNION ALL
SELECT 'ref_txn_codes', COUNT(*)
FROM silver.ref_txn_codes
WHERE txn_code IS NULL

UNION ALL
SELECT 'tps_txn_log', COUNT(*)
FROM silver.tps_txn_log
WHERE txn_id IS NULL;


-- 2. Check for duplicate PKs
-- ----------------------------
SELECT 'cbs_cust_master' AS table_name, cust_id::TEXT, COUNT(*) AS dup_count
FROM silver.cbs_cust_master
GROUP BY cust_id
HAVING COUNT(*) > 1

UNION ALL
SELECT 'cbs_acc_master', acc_num::TEXT, COUNT(*)
FROM silver.cbs_acc_master
GROUP BY acc_num
HAVING COUNT(*) > 1

UNION ALL
SELECT 'ref_branch_master', branch_id::TEXT, COUNT(*)
FROM silver.ref_branch_master
GROUP BY branch_id
HAVING COUNT(*) > 1

UNION ALL
SELECT 'ref_txn_codes', txn_code::TEXT, COUNT(*)
FROM silver.ref_txn_codes
GROUP BY txn_code
HAVING COUNT(*) > 1

UNION ALL
SELECT 'tps_txn_log', txn_id, COUNT(*)
FROM silver.tps_txn_log
GROUP BY txn_id
HAVING COUNT(*) > 1;


-- 3. Referential Integrity Checks
-- ----------------------------

-- Transactions referencing non-existent accounts
SELECT txn_id, acc_num
FROM silver.tps_txn_log t
WHERE NOT EXISTS (
    SELECT 1 FROM silver.cbs_acc_master a WHERE a.acc_num = t.acc_num
);

-- Accounts referencing non-existent customers
SELECT acc_num, cust_id
FROM silver.cbs_acc_master a
WHERE NOT EXISTS (
    SELECT 1 FROM silver.cbs_cust_master c WHERE c.cust_id = a.cust_id
);

-- Accounts referencing non-existent branches
SELECT acc_num, branch_id
FROM silver.cbs_acc_master a
WHERE NOT EXISTS (
    SELECT 1 FROM silver.ref_branch_master b WHERE b.branch_id = a.branch_id
);

-- Transactions referencing non-existent txn codes
SELECT txn_id, txn_code
FROM silver.tps_txn_log t
WHERE NOT EXISTS (
    SELECT 1 FROM silver.ref_txn_codes r WHERE r.txn_code = t.txn_code
);


-- 4. Business Logic Checks
-- ----------------------------

-- DOB later than account open date (should be impossible)
SELECT c.cust_id, c.cust_dob, a.acc_num, a.open_dt
FROM silver.cbs_cust_master c
JOIN silver.cbs_acc_master a ON c.cust_id = a.cust_id
WHERE c.cust_dob > a.open_dt;

-- Transactions with negative balance or amount
SELECT * FROM silver.tps_txn_log
WHERE amnt < 0 OR bal < 0;

-- Email format issues
SELECT cust_id, cust_email
FROM silver.cbs_cust_master
WHERE cust_email NOT LIKE '%@%.%';

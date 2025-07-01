/*
---------------------------
Create Silver Layer Tables
---------------------------
Purpose:
	> Creates data tables and a log table in the silver schema		
Note:
	> The silver layer data tables stores data from the bronze layer after cleaning and transforming it.
*/

-- 1. Customer Master (Core Banking System)
DROP TABLE IF EXISTS silver.cbs_cust_master;
CREATE TABLE silver.cbs_cust_master (
    cust_id				INTEGER,
    cust_name           TEXT,
    cust_address        TEXT,
    cust_gender         VARCHAR(10),
    cust_phone          TEXT,
    cust_email          TEXT,
    cust_dob            DATE,
    cust_create_dt  	DATE,
	dwh_table_create_date TIMESTAMP DEFAULT NOW()
);

-- 2. Account Master (Core Banking System)
DROP TABLE IF EXISTS silver.cbs_acc_master;
CREATE TABLE silver.cbs_acc_master (
    acc_num		INTEGER,
    cust_id		INTEGER,
    acc_type	VARCHAR(50),
    branch_id	INTEGER,
    open_dt		DATE,
    close_dt	DATE,
	dwh_table_create_date TIMESTAMP DEFAULT NOW()
);

-- 3. Transaction Log (Transaction Processing System)
DROP TABLE IF EXISTS silver.tps_txn_log;
CREATE TABLE silver.tps_txn_log (
    txn_dt		TIMESTAMP,
    txn_id      VARCHAR(10),
    acc_num     INTEGER,
    txn_type    VARCHAR(10),
    txn_code    INTEGER,
    amnt        NUMERIC(12,2),
    bal         NUMERIC(12,2),
	dwh_table_create_date TIMESTAMP DEFAULT NOW()
);

-- 4. Transaction Codes (Reference Data Management)
DROP TABLE IF EXISTS silver.ref_txn_codes;
CREATE TABLE silver.ref_txn_codes (
    txn_code	INTEGER,
    subtype     TEXT,
    channel     TEXT,
    descr   	TEXT,
	dwh_table_create_date TIMESTAMP DEFAULT NOW()
);

-- 5. Branch Master (Reference Data Management)
DROP TABLE IF EXISTS silver.ref_branch_master;
CREATE TABLE silver.ref_branch_master (
    branch_id       INTEGER,
    branch_name     TEXT,
    sort_code       INTEGER,
    branch_address  TEXT,
    zone            TEXT,
	dwh_table_create_date TIMESTAMP DEFAULT NOW()
);


-- 6. Data Load Log Table 
DROP TABLE IF EXISTS silver.silver_load_log;
CREATE TABLE silver.silver_load_log (
    batch_id 		TEXT,    
    start_time 		TIMESTAMP,
    end_time 		TIMESTAMP,
    duration_secs 	NUMERIC,
    status 			TEXT,
    error_message 	TEXT,
	dwh_table_create_date TIMESTAMP DEFAULT NOW()
);


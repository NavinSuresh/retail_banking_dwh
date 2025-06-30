/*
---------------------------
Create Bronze Layer Tables
---------------------------
Purpose:
	> Creates data tables and a log table in the bronze schema		
Note:
	> The bronze layer data tables are used to store raw, immutable data from the source systems
*/

-- 1. Customer Master (Core Banking System)
DROP TABLE IF EXISTS bronze.cbs_cust_master;
CREATE TABLE bronze.cbs_cust_master (
    cust_id				INTEGER,
    cust_name           TEXT,
    cust_address        TEXT,
    cust_gender         VARCHAR(10),
    cust_phone          TEXT,
    cust_email          TEXT,
    cust_dob            DATE,
    cust_create_dt  	DATE
);

-- 2. Account Master (Core Banking System)
DROP TABLE IF EXISTS bronze.cbs_acc_master;
CREATE TABLE bronze.cbs_acc_master (
    acc_num		INTEGER,
    cust_id		INTEGER,
    acc_type	VARCHAR(10),
    branch_id	INTEGER,
    open_dt		DATE,
    close_dt	DATE
);

-- 3. Transaction Log (Transaction Processing System)
DROP TABLE IF EXISTS bronze.tps_txn_log;
CREATE TABLE bronze.tps_txn_log (
    txn_dt		TIMESTAMP,
    txn_id      VARCHAR(10),
    acc_num     INTEGER,
    txn_type    VARCHAR(10),
    txn_code    INTEGER,
    amnt        NUMERIC(12,2),
    bal         NUMERIC(12,2)
);

-- 4. Transaction Codes (Reference Data Management)
DROP TABLE IF EXISTS bronze.ref_txn_codes;
CREATE TABLE bronze.ref_txn_codes (
    txn_code	INTEGER,
    subtype     TEXT,
    channel     TEXT,
    descr   	TEXT
);

-- 5. Branch Master (Reference Data Management)
DROP TABLE IF EXISTS bronze.ref_branch_master;
CREATE TABLE bronze.ref_branch_master (
    branch_id       INTEGER,
    branch_name     TEXT,
    sort_code       INTEGER,
    branch_address  TEXT,
    zone            TEXT
);


-- 6. Data Load Log Table 
DROP TABLE IF EXISTS bronze.bronze_load_log;
CREATE TABLE bronze.bronze_load_log (
    batch_id 		TEXT,    
    start_time 		TIMESTAMP,
    end_time 		TIMESTAMP,
    duration_secs 	NUMERIC,
    status 			TEXT,
    error_message 	TEXT
);


/*
-----------------------------------------
Stored Procedure : Source to Bronze Layer
-----------------------------------------
Purpose:
	> Ingest raw data from the source csv files to bronze layer tables
	> Truncates the target tables first and then loads them with source data
	> Logs the success or errors in a seperate table for auditing
Usage:
	> CALL bronze_layer_load();
*/

CREATE OR REPLACE PROCEDURE bronze.bronze_layer_load()
LANGUAGE plpgsql
AS $$
	DECLARE
		batch_id		TEXT := TO_CHAR ( NOW(), 'YYYYMMDD_HH24MISS'); -- Converting the timestamp to human readable string for logging
		start_time 		TIMESTAMP := clock_timestamp();
		end_time	 	TIMESTAMP;
		runtime_secs 	NUMERIC;
		records_loaded 	INTEGER;
		status 			TEXT;
		error_message	TEXT;
		tbl_name		TEXT;
		csv_path		TEXT;
	BEGIN
		RAISE NOTICE '===============================================';
		RAISE NOTICE 'Starting Bronze Layer Load Process';
		RAISE NOTICE '----------------------------------';
		RAISE NOTICE 'Process start time: %', start_time;
		RAISE NOTICE 'Batch ID: %', batch_id ;
		RAISE NOTICE '===============================================';	

	    FOR tbl_name, csv_path IN
	      	VALUES
	        ('cbs_cust_master',    'C:/projects data/2/CBS/cust_master.csv'),
	        ('cbs_acc_master',     'C:/projects data/2/CBS/acc_master.csv'),
	        ('tps_txn_log',    'C:/projects data/2/TPS/txn_log.csv'),
	        ('ref_txn_codes',  'C:/projects data/2/REF/txn_codes.csv'),
	        ('ref_branch_master',      'C:/projects data/2/REF/branch_master.csv')
    	LOOP
			-----* Truncate
		EXECUTE format('TRUNCATE bronze.%I', tbl_name);
		RAISE NOTICE 'Truncated table bronze.%', tbl_name;

			-----* Load
		EXECUTE format('COPY bronze.%I FROM %L WITH (FORMAT csv, HEADER true)', tbl_name, csv_path);
		EXECUTE format('SELECT COUNT(*) FROM bronze.%I', tbl_name)
		INTO records_loaded;
		RAISE NOTICE 'Loaded table bronze.% with % records', tbl_name, records_loaded;
		RAISE NOTICE '------------------------------------';

		END LOOP;
		
		end_time:= clock_timestamp(); status:= 'SUCCESS'; error_message = null; 
		RAISE NOTICE 'Bronze Layer Load Completed Successfully';
		RAISE NOTICE 'Process end time: %', end_time;

			-----* Log
		INSERT INTO bronze.bronze_load_log
		(batch_id, start_time, end_time, duration_secs, status, error_message)
		VALUES
		(batch_id, start_time, end_time, EXTRACT(EPOCH FROM (end_time - start_time)), status, error_message);

			-----* Error Handling
		EXCEPTION WHEN OTHERS THEN
		
		end_time:= clock_timestamp(); status:= 'FAIL'; error_message = SQLERRM;
		RAISE WARNING 'Bronze Layer Load Failed on table % due to %', tbl_name, error_message;
		RAISE NOTICE 'Process end time: %', end_time;

		INSERT INTO bronze.bronze_load_log
		(batch_id, start_time, end_time, duration_secs, status, error_message)
		VALUES
		(batch_id, start_time, end_time, EXTRACT(EPOCH FROM (end_time - start_time)), status, error_message);
END$$;

/*
-----------------------------------------------
Stored Procedure : Bronze Layer to Silver Layer
-----------------------------------------------
Purpose:
	> Cleans,transforms and standardises bronze layer data and loads it into silver layer data tables
	> Truncates the target tables first and then loads them with transformed data
	> Logs the success or errors in a seperate table for auditing
Usage:
	> CALL silver.silver_load_sp();
*/

CREATE OR REPLACE PROCEDURE silver.silver_load_sp()
LANGUAGE plpgsql
AS $$
	DECLARE
	    batch_id       TEXT := TO_CHAR(NOW(), 'YYYYMMDD_HH24MISS');
	    start_time     TIMESTAMP := clock_timestamp();
	    end_time       TIMESTAMP;
	    runtime_secs   NUMERIC;
	    status         TEXT;
	    error_message  TEXT := NULL;
		tbl_name	   TEXT;
	BEGIN
		BEGIN
		    RAISE NOTICE '===============================================';
			RAISE NOTICE 'Starting Silver Layer Load Process';
			RAISE NOTICE '----------------------------------';
			RAISE NOTICE 'Process start time: %', start_time;
			RAISE NOTICE 'Batch ID: %', batch_id ;
			RAISE NOTICE '===============================================';	
		
		    --1. ===== silver.cbs_cust_master =====================
		    BEGIN
		        RAISE NOTICE 'Processing: silver.cbs_cust_master';
				tbl_name := 'silver.cbs_cust_master';
				
				-----* Truncate
		        TRUNCATE TABLE silver.cbs_cust_master;
				-----* Transform
		        WITH raw AS 
					(
		            SELECT * FROM bronze.cbs_cust_master
		            WHERE cust_id IS NOT NULL AND cust_dob < cust_create_dt
		        	),
				phone_digits AS 
					(
        			SELECT *,
               			   REGEXP_REPLACE(TRIM(cust_phone), '\D', '', 'g') AS cleaned_phone
        			FROM raw
   					),
		        final_cleaned AS 
					(
		            SELECT
		                cust_id,
		                INITCAP(TRIM(COALESCE(cust_name, 'NA'))) AS cust_name,
						TRIM(COALESCE(cust_address, 'NA')) AS cust_address,
		                CASE 
		                    WHEN LOWER(TRIM(cust_gender)) = 'm' THEN 'Male'
		                    WHEN LOWER(TRIM(cust_gender)) = 'f' THEN 'Female'
		                    ELSE 'NA'
		                END AS cust_gender,
				  		CASE 
                			WHEN cleaned_phone IS NULL THEN 'NA'
                			WHEN RIGHT(cleaned_phone, 10) ~ '^\d{10}$' THEN RIGHT(cleaned_phone, 10)
                			ELSE 'NA'
            			END AS cust_phone,
		                TRIM(COALESCE(cust_email, 'NA')) AS cust_email,
		                cust_dob,
						cust_create_dt
		            FROM phone_digits
		        	)
		        INSERT INTO silver.cbs_cust_master
		        SELECT * FROM final_cleaned;
				RAISE NOTICE 'Completed: silver.cbs_cust_master';
				RAISE NOTICE '---------------------------------';
		    END;
		
		    --2. ===== silver.cbs_acc_master =====================
		    BEGIN
		        RAISE NOTICE 'Processing: silver.cbs_acc_master';
				tbl_name := 'silver.cbs_acc_master';
				
				-----* Truncate
		        TRUNCATE TABLE silver.cbs_acc_master;
				-----* Transform
		        WITH cleaned AS 
					(
		            SELECT
		                acc_num,
		                cust_id,
		                CASE TRIM(acc_type)
		                    WHEN 'SB' THEN 'Savings Account'
		                    WHEN 'CA' THEN 'Current Account'
		                    WHEN 'SL' THEN 'Salary Account'
		                    WHEN 'SBP' THEN 'Savings Premium'
		                    ELSE 'NA'
		                END AS acc_type,
						branch_id,
		                open_dt,
						close_dt	                
		            FROM bronze.cbs_acc_master
		            WHERE cust_id IS NOT NULL 	               
		        	)
		        INSERT INTO silver.cbs_acc_master
		        SELECT * FROM cleaned;
				RAISE NOTICE 'Completed: silver.cbs_acc_master';
				RAISE NOTICE '---------------------------------';
		    END;

  			--3. ===== silver.ref_branch_master =====================
		    BEGIN
		        RAISE NOTICE 'Processing: silver.ref_branch_master';
				tbl_name := 'silver.ref_branch_master';
				
				-----* Truncate
		        TRUNCATE TABLE silver.ref_branch_master;
				-----* Transform
		        WITH cleaned AS 
					(
		            SELECT
		                branch_id,
		                TRIM(branch_name) AS branch_name,
		                sort_code,
		                TRIM(branch_address) AS branch_address,
						TRIM(zone) AS zone
		            FROM bronze.ref_branch_master
		        	)
		        INSERT INTO silver.ref_branch_master
		        SELECT * FROM cleaned;
				RAISE NOTICE 'Completed: silver.ref_branch_master';
				RAISE NOTICE '---------------------------------';
		    END;
			
			--4. ===== silver.ref_txn_codes =====================
		    BEGIN
		        RAISE NOTICE 'Processing: silver.ref_txn_codes';
				tbl_name := 'silver.ref_txn_codes';
				
				-----* Truncate
		        TRUNCATE TABLE silver.ref_txn_codes;
				-----* Transform				
		        WITH cleaned AS 
					(
		            SELECT
		                txn_code,
		                TRIM(subtype) AS subtype,
		                TRIM(channel) AS channel,
		                TRIM(descr) AS descr	               
		            FROM bronze.ref_txn_codes
		        	)
		        INSERT INTO silver.ref_txn_codes
		        SELECT * FROM cleaned;
				RAISE NOTICE 'Completed: silver.ref_txn_codes';
				RAISE NOTICE '---------------------------------';
			END;  
		
		    --5. ===== silver.tps_txn_log =====================
		    BEGIN
		        RAISE NOTICE 'Processing: silver.tps_txn_log';
				tbl_name := 'silver.tps_txn_log';
				
				-----* Truncate
		        TRUNCATE TABLE silver.tps_txn_log;
				-----* Transform		
		        WITH cleaned AS 
					(
		            SELECT
		                txn_dt,
		                TRIM(txn_id) AS txn_id,
		                acc_num,
		                TRIM(txn_type) AS txn_type,
		                txn_code,
		                amnt,
		                bal
		            FROM bronze.tps_txn_log
					WHERE bal >= 0
		        	)
		        INSERT INTO silver.tps_txn_log
		        SELECT * FROM cleaned;
				RAISE NOTICE 'Completed: silver.tps_txn_log';
				RAISE NOTICE '---------------------------------';
		    END;
		END;    
		end_time:= clock_timestamp(); status:= 'SUCCESS'; error_message = null; 
		RAISE NOTICE 'Silver Layer Load Completed Successfully';
		RAISE NOTICE 'Process end time: %', end_time;
		
			-----* Log	
	    INSERT INTO silver.silver_load_log
	    (batch_id, start_time, end_time, duration_secs, status, error_message)
	    VALUES
	    (batch_id, start_time, end_time, EXTRACT(EPOCH FROM (end_time - start_time)), status, error_message);
	
			-----* Error Handling
		EXCEPTION WHEN OTHERS THEN
		
		end_time:= clock_timestamp(); status:= 'FAIL'; error_message = SQLERRM;
		RAISE WARNING 'Silver Layer Load Failed on table % due to %', tbl_name, error_message;
		RAISE NOTICE 'Process end time: %', end_time;

		INSERT INTO silver.silver_load_log
		(batch_id, start_time, end_time, duration_secs, status, error_message)
		VALUES
		(batch_id, start_time, end_time, EXTRACT(EPOCH FROM (end_time - start_time)), status, error_message);

END;
$$;

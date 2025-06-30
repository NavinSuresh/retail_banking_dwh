/*
---------------------------
Create Database and Schemas
---------------------------

Purpose:
	> Creates a new database 'dwh_retail_bank' after dropping any existing database of the same name.
	> Creates 3 schemas 'bronze', 'silver', and 'gold' within the new database for ETL.
*/


--Step 1.1: Run the following code inside the default 'postgres' database
--Warning: Running this permanently removes the database 'dwh_retail_bank' and all data in it
DROP DATABASE IF EXISTS dwh_retail_bank;

--Step 1.2: Run the following code inside the default 'postgres' database
CREATE DATABASE dwh_retail_bank;

--Step 2: Open a new query window from the 'dwh_retail_bank' database and run the following code
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
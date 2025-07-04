
# Data Catalog for Gold Layer

## Overview
The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of **dimension tables** and **fact tables** for specific business metrics.

---

### 1. **gold.dim_customer**
- **Purpose:** Stores customer details enriched with cleaned and formatted attributes.


| Column Name     | Data Type | Description |
|------------------|-----------|-------------|
| customer_key     | INT       | Surrogate key uniquely identifying each customer record in the dimension table. |
| customer_id      | INT       | Original source system customer identifier. |
| full_name        | TEXT      | Cleaned and title-cased full name of the customer. |
| address          | TEXT      | Residential address of the customer. |
| gender           | VARCHAR10 | Normalized gender ("Male", "Female", "NA"). |
| phone_number     | TEXT      | Cleaned 10-digit phone number. |
| email_id         | TEXT      | Email address of the customer. |
| birthdate        | DATE      | Date of birth of the customer. |
| create_date      | DATE      | Date the customer was created in the system. |

---

### 2. **gold.dim_account**
- **Purpose:** Combines account and branch information for reporting purposes.


| Column Name     | Data Type | Description |
|------------------|-----------|-------------|
| account_key      | INT       | Surrogate key uniquely identifying each account. |
| account_number   | INT       | Unique account number from source system. |
| customer_id      | INT       | Customer ID owning the account (descriptive only). |
| account_type     | VARCHAR50 | Mapped business-readable account type. |
| open_date        | DATE      | Date when the account was opened. |
| close_date       | DATE      | Date when the account was closed, if applicable. |
| branch_id        | INT       | Branch ID where account is held. |
| branch_name      | TEXT      | Name of the branch. |
| zone             | TEXT      | Zone or region the branch belongs to. |

---

### 3. **gold.fact_transaction**
- **Purpose:** Stores transactional financial data linked to customer and account dimensions.


| Column Name         | Data Type | Description |
|----------------------|-----------|-------------|
| transaction_id       | VARCHAR10 | Unique ID for the transaction. |
| transaction_date     | TIMESTAMP | Date of the transaction. |
| customer_key         | INT       | Foreign key to `dim_customer.customer_key`. |
| account_key          | INT       | Foreign key to `dim_account.account_key`. |
| transaction_type     | VARCHAR10 | Type of transaction ("Credit", "Debit"). |
| transaction_code     | INT       | Code representing the transaction type. |
| transaction_subtype  | TEXT      | More detailed subtype of the transaction. |
| transaction_channel  | TEXT      | Channel used (e.g., Online, Branch). |
| amount               | NUMERIC   | Monetary value of the transaction. |
| account_balance      | NUMERIC   | Account balance after the transaction. |

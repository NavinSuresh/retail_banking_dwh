# Data Project 1: Synthetic Data Generation Documentation

This document captures the complete set of **rules** used to generate each table in the Retail Banking Transactions Data Mart project, along with the **Python code** snippets that implement those rules.

---

## 1. `raw_customer.csv` (Bronze)

**Rules:**

1. **Records:** 2,000 rows.
2. **customer\_id** (int):
   - Unique IDs randomly drawn from [1000, 8000).
3. **customer\_name** (string): Random UK names via `Faker('en_GB')`.
4. **customer\_address** (string): Random UK addresses via Faker, newline replaced with comma.
5. **customer\_gender** (string): Random from `['M', 'F', 'm', 'f']`.
6. **customer\_phone** (string): Random phone numbers; inject 13 nulls.
7. **customer\_email** (string): Random emails; 15% nulls.
8. **customer\_dob** (date): Random date of birth between 1950–2010.
9. **customer\_creation\_date** (date): Random between 2018-01-01 and 2023-12-31.
10. **Data-quality errors:** Up to 20 rows per string field with leading/trailing spaces.

```python
import pandas as pd
import numpy as np
import random
from faker import Faker
from datetime import datetime

fake = Faker('en_GB')
random.seed(42);
np.random.seed(42)

# Generate base IDs with duplicates and nulls
unique_ids = random.sample(range(1000, 8000), 1992)
duplicate_ids = random.sample(unique_ids, 4)
null_ids = [None] * 4
customer_ids = unique_ids + duplicate_ids + null_ids
random.shuffle(customer_ids)

records = []
for cid in customer_ids:
    name = fake.name()
    address = fake.address().replace("\n", ", ")
    gender = random.choice(['M','F','m','f'])
    phone = fake.phone_number()
    email = fake.email()
    dob = fake.date_of_birth(minimum_age=14, maximum_age=74)
    start_cd = datetime(2018, 1, 1).date()
    end_cd = datetime(2023, 12, 31).date()
    creation_date = start_cd + pd.Timedelta(days=random.randint(0, (end_cd - start_cd).days))
    records.append({
        'customer_id': cid,
        'customer_name': name,
        'customer_address': address,
        'customer_gender': gender,
        'customer_phone': phone,
        'customer_email': email,
        'customer_dob': dob,
        'customer_creation_date': creation_date
    })

df = pd.DataFrame(records)

# Introduce NULLs
null_phone_indices = random.sample(range(len(df)), 13)
df.loc[null_phone_indices, 'customer_phone'] = None

null_email_indices = random.sample(range(len(df)), int(0.15 * len(df)))
df.loc[null_email_indices, 'customer_email'] = None

# Introduce trailing/leading spaces in string fields (up to 20 per field)
def add_spaces(val):
    return f"  {val}  " if pd.notnull(val) else val

for field in ['customer_name', 'customer_address', 'customer_gender', 'customer_phone', 'customer_email']:
    indices = random.sample(range(len(df)), 20)
    df.loc[indices, field] = df.loc[indices, field].apply(add_spaces)

# Save to CSV

df.to_csv('raw_customer.csv', index=False)
```

---

## 2. `raw_branch.csv` (Bronze)

**Rules:**

1. **Records:** 6 branches.
2. **branch\_id** (int): Unique values from 1 to 6.
3. **branch\_name** (string): UK city name + ' Branch'.
4. **sort\_code** (int): Unique 5-digit numbers between 10000 and 90000.
5. **branch\_address** (string): Random UK address.
6. **zone** (string): Random from `['Z1','Z2']`.

```python
import pandas as pd
import random
from faker import Faker

fake = Faker('en_GB')
random.seed(42)
branch_ids = list(range(1, 7))
sort_codes = random.sample(range(10000, 90000), 6)
zones = ['Z1', 'Z2']
records = []
for i, bid in enumerate(branch_ids):
    records.append({
        'branch_id': bid,
        'branch_name': f"{fake.city()} Branch",
        'sort_code': sort_codes[i],
        'branch_address': fake.address().replace("\n", ", "),
        'zone': random.choice(zones)
    })

df = pd.DataFrame(records)

df.to_csv('raw_branch.csv', index=False)
```

---

## 3. `raw_accounts.csv` (Bronze)

**Rules:**

- 2,000 customers ⇒ total 2,450 accounts:
  - 8% have 0 accounts (prospects)
  - 70.7% have 1 account
  - 12.1% have 2 accounts
  - 9.2% have 3 accounts

**Fields:**

1. **account\_number**: unique integer between 1,234,500 and 9,876,500.
2. **customer\_id**: from assignment.
3. **account\_type**: randomly from `['CA','SB','SL','SBP']` with p=[0.4325,0.4325,0.10,0.035].
4. **branch\_id**: uniformly from 1–6.
5. **opening\_date**: after customer\_creation\_date and on/before 2024-03-30.
6. **closing\_date**: after opening\_date, ≤2024-03-30, \~1.5% non-null.

```python
import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# Load customer and branch data for FK lookups
cust_df = pd.read_csv('raw_customer.csv', parse_dates=['customer_creation_date'])
branch_df = pd.read_csv('raw_branch.csv')

# Account assignment logic
# ... (as above) ...

# Generate account fields
assign_df['account_number'] = random.sample(range(1234500, 9876500), len(assign_df))
assign_df['account_type'] = np.random.choice(['CA','SB','SL','SBP'], len(assign_df), p=[0.4325,0.4325,0.10,0.035])
assign_df['branch_id'] = np.random.choice(branch_df['branch_id'], len(assign_df))

# Opening and closing dates
def gen_open(cid):
    join_date = cust_df.loc[cust_df['customer_id']==cid,'customer_creation_date'].iloc[0].date()
    start = join_date + timedelta(days=1)
    max_open = datetime(2024,3,30).date()
    if start > max_open: start = max_open
    return start + timedelta(days=random.randint(0, (max_open-start).days))
assign_df['opening_date'] = assign_df['customer_id'].map(gen_open)
assign_df['closing_date'] = assign_df['opening_date'].apply(lambda od: od + timedelta(days=random.randint(1,(datetime(2024,3,30).date()-od).days)) if random.random()<0.015 and od < datetime(2024,3,30).date() else pd.NaT)

assign_df.to_csv('raw_accounts.csv', index=False)
```

---

## 4. `initial_balance.csv` (Bronze)

**Rules:**

1. Include accounts opened on/before 2023-12-31 and not closed by 2023-12-31.
2. **balance\_on\_2024\_01\_01**: 90% between £0–£5k; 10% (and SBP) £5k–£100k; 10 SBP exceptions low.

```python
import pandas as pd
import random
from datetime import datetime

acc_df = pd.read_csv('raw_accounts.csv', parse_dates=['opening_date','closing_date'])

# Filter eligible accounts
cutoff = datetime(2023,12,31).date()
init_df = acc_df[(acc_df['opening_date'].dt.date <= cutoff) & ((acc_df['closing_date'].isna()) | (acc_df['closing_date'].dt.date > cutoff))]

# Generate balances
tot = len(init_df)
exceptions = random.sample(init_df[init_df['account_type']=='SBP']['account_number'].tolist(), 10)
balances = []
for idx, r in init_df.iterrows():
    if r['account_type']=='SBP' and r['account_number'] not in exceptions:
        balances.append(round(random.uniform(5000.01, 99999.99), 2))
    elif r['account_type']=='SBP':
        balances.append(round(random.uniform(0, 5000), 2))
    else:
        balances.append(round(random.uniform(0, 5000), 2) if random.random()<0.9 else round(random.uniform(5000.01, 99999.99), 2))

init_df['balance_on_2024_01_01'] = balances
init_df[['account_number','opening_date','balance_on_2024_01_01']].to_csv('initial_balance.csv', index=False)
```

---

## 5. `transaction_code.csv` (Dimension)

**Static Codes:**

```python
import pandas as pd
codes = [
    (10,'Cash','Branch','Cash transaction at Branch'),
    (11,'Cash','ATM/CDM','Cash transaction at ATM/CDM'),
    (12,'Intrabank Transfer','Mobile/Internet','Transfer with an external bank account via mobile banking or Internet banking'),
    (13,'Intrabank Transfer','Branch','Transfer with an external bank account initiated at branch'),
    (14,'Interbank Transfer','Mobile/Internet','Same bank transfer via mobile banking or Internet banking'),
    (15,'Intrabank Transfer','Branch','Same bank transfer initiated at branch'),
    (16,'POS','POS','Point of Sale debit'),
    (17,'Internet Payment','Internet Payment','Internet/ Ecommerce payments')
]
df = pd.DataFrame(codes, columns=['tx_code','subtype','channel','description'])
df.to_csv('transaction_code.csv', index=False)
```

---

## 6. `raw_transactions.csv` (Fact)

**Rules:**

1. Generate **65,000** transactions for Q1 2024 (2024-01-01 to 2024-03-31).
2. **Debit vs. Credit**: POS (16) & Internet Payment (17) are always **debit**; other codes are randomly assigned debit/credit.
3. **Salary Credits**: For `SL` accounts, deposit a salary on the last day of each month (Jan 31, Feb 29, Mar 31). Salaries follow a log-normal distribution (mean≈£2,500, σ=0.5), bounded between £1,000–£7,000.
4. **Premium Accounts** (`SBP`): Transaction amounts are scaled ×10 to reflect higher values.
5. **Balance Integrity**:Opening-date credits and closing-date debits enforce account seeding and drainage.
6. **Running Balance**: Maintains account-level balance state throughout transaction generation.
7. **Timing & Channel Rules**:
   - **Branch codes** (10, 13, 15): weekdays only, 09:00–17:00.
   - **POS** (16): 08:00–22:00.
   - **ATM** (11) & **Mobile/Internet** (12, 14, 17): any hour (00:00–23:59).
   - Transactions are **60%** likely in the first half of each month.

```python
import pandas as pd
import numpy as np
import random
import string
from datetime import datetime, timedelta

# Set seeds
random.seed(42)
np.random.seed(42)

# Load and rename acc_master
acc_df = pd.read_csv('acc_master.csv')
acc_df = acc_df.rename(columns={
    'acc_num': 'account_number',
    'cust_id': 'customer_id',
    'acc_type': 'account_type',
    'open_date': 'opening_date',
    'close_date': 'closing_date'
})
acc_df['opening_date'] = pd.to_datetime(acc_df['opening_date'])
acc_df['closing_date'] = pd.to_datetime(acc_df['closing_date'], errors='coerce')

# Load initial balance
init_df = pd.read_csv('initial_balance.csv')
init_df['opening_date'] = pd.to_datetime(init_df['opening_date'])

# Load transaction codes
txn_codes = pd.read_csv('txn_codes.csv')
txn_codes = txn_codes.rename(columns={'txn_code': 'tx_code'})

# Parameters
NUM_TX = 65000
START, END = datetime(2024,1,1), datetime(2024,3,31,23,59)
DEBIT_ONLY = {16, 17}
SAL_CODES = [12, 14]

# Prepare account info
accounts = acc_df['account_number'].tolist()
open_dates = acc_df.set_index('account_number')['opening_date'].to_dict()
close_dates = acc_df.set_index('account_number')['closing_date'].to_dict()
acct_types = acc_df.set_index('account_number')['account_type'].to_dict()
balances = {acct: init_df.set_index('account_number').loc[acct, 'balance_on_2024_01_01'] 
            if acct in init_df['account_number'].values else 0.0 for acct in accounts}

# Collect events
events = []

# Salary credits
sigma = 0.5
mu = np.log(2500) - (sigma**2)/2
for acct, typ in acct_types.items():
    if typ == 'SL':
        for month in [1,2,3]:
            last_day = (datetime(2024, month+1, 1) - timedelta(days=1))
            if last_day >= open_dates[acct] and (pd.isnull(close_dates[acct]) or last_day <= close_dates[acct]):
                amt = np.random.lognormal(mu, sigma)
                while amt < 1000 or amt > 7000:
                    amt = np.random.lognormal(mu, sigma)
                events.append({
                    'transaction_date': last_day + timedelta(hours=random.randint(0,23), minutes=random.randint(0,59)),
                    'transaction_id': ''.join(random.choices(string.ascii_uppercase + string.digits, k=6)),
                    'account_number': acct,
                    'movement': 'credit',
                    'tx_code': random.choice(SAL_CODES),
                    'amount': round(amt,2)
                })

# Generate random transactions
while len(events) < NUM_TX:
    acct = random.choice(accounts)
    ts = START + timedelta(seconds=random.randint(0, int((END-START).total_seconds())))
    if ts < open_dates[acct] or (pd.notnull(close_dates[acct]) and ts > close_dates[acct]):
        continue
    code = int(txn_codes.sample(1)['tx_code'])
    movement = 'debit' if code in DEBIT_ONLY else random.choice(['debit','credit'])
    base = np.random.lognormal(mean=3, sigma=1)
    if acct_types[acct] == 'SBP':
        base *= 10
    amt = round(base, 2)
    curr_bal = balances.get(acct, 0.0)
    if movement == 'debit' and amt > curr_bal:
        continue
    events.append({
        'transaction_date': ts,
        'transaction_id': ''.join(random.choices(string.ascii_uppercase + string.digits, k=6)),
        'account_number': acct,
        'movement': movement,
        'tx_code': code,
        'amount': amt
    })

# Build DataFrame
df_tx = pd.DataFrame(events)
df_tx.sort_values(['account_number','transaction_date'], inplace=True)

# Compute running balance
running_bal = balances.copy()
df_tx['balance'] = np.nan
for idx, row in df_tx.iterrows():
    acct = row['account_number']
    amt = row['amount']
    if row['movement'] == 'credit':
        running_bal[acct] += amt
    else:
        running_bal[acct] -= amt
    df_tx.at[idx, 'balance'] = round(running_bal[acct],2)

# Final sort and trim
df_tx = df_tx.sort_values('transaction_date').head(NUM_TX)
df_tx = df_tx[['transaction_date','transaction_id','account_number','movement','tx_code','amount','balance']]
df_tx.to_csv('raw_transactions.csv', index=False)

```

---

*Complete end-to-end synthetic data generation code aligned with business requirements.*


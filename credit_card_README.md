# Credit Card Transaction Analysis | SQL

![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue?logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/Language-SQL-orange)
![Domain](https://img.shields.io/badge/Domain-FinTech%20%7C%20Fraud%20Analytics-green)
![Rows](https://img.shields.io/badge/Dataset-107K%20Transactions-lightgrey)

---

## Project Overview

SQL-based analysis of 107K credit card transactions (2019–2021) to uncover spending behavior, detect fraud patterns, and generate actionable recommendations for marketing and risk teams.

**Key business questions answered:**
- Which categories and states drive the most revenue?
- Which categories are fraud hotspots?
- When is fraud most likely to occur?
- What does a fraudulent transaction look like vs a legitimate one?
- Are larger cities more prone to fraud?

---

## Dataset

**Source:** Credit Card Transactions Dataset (Kaggle)
**Size:** ~107K transactions after cleaning | 2019–2021

**Columns used (10 of 24):**

| Column | Description |
|---|---|
| `trans_datetime` | Date and time of transaction |
| `category` | Merchant category |
| `amt` | Transaction amount ($) |
| `gender` | Customer gender |
| `city` | Customer city |
| `state` | Customer state |
| `city_pop` | Population of customer's city |
| `job` | Customer occupation |
| `dob` | Customer date of birth |
| `is_fraud` | 1 = fraudulent, 0 = legitimate |

---

## Key Findings

| Metric | Value |
|---|---|
| Total Transactions | 107,753 |
| Total Revenue | $7,547,984 |
| Avg Transaction | $70.05 |
| Fraud Cases | 548 |
| Fraud Rate | 0.51% |
| Fraud Loss | $298,450 |

---

## Analysis & Business Recommendations

**Fraud Hotspots by Category**
- `shopping_net` (1.54%) and `misc_net` (1.50%) have the highest fraud rates
- Online categories need stricter 2FA verification
- Gas transactions show micro-fraud pattern ($541 total) — likely test transactions before larger fraud

**Late Night Fraud Surge**
- Hours 22–23 have **2.44–2.76% fraud rate** — nearly 5x higher than daytime
- Recommendation: Trigger automatic verification for all transactions between 10pm–2am

**Fraudsters Spend 8x More**
- Avg fraud transaction = **$544** vs legitimate = **$67**
- Max fraud = **$1,313** — fraudsters stay below a threshold to avoid detection
- Recommendation: Flag transactions above $500 in high-risk categories for manual review

**Geography**
- TX, NY, PA are the top 3 revenue states — prioritize marketing budget here
- OH (1.12%) and MI (0.90%) have the highest state-level fraud rates
- Small cities have **higher fraud rates than metro areas** (0.55% vs 0.38%) — rural customers need fraud education

**Seasonality**
- June, October, December are peak spending months
- December consistently shows the highest fraud count — increase Q4 monitoring

**High-Value Customers**
- Travel dominates high-value transactions (up to $28,948) — all legitimate
- These premium customers should receive concierge-level service and card benefits

---

## How to Run

1. Open terminal and connect to MySQL:
```bash
mysql -u root -p --local-infile=1
```

2. Run `CREATE DATABASE` and `CREATE TABLE` sections

3. Import the CSV:
```sql
SET GLOBAL local_infile=1;
USE credit_card_analysis;

LOAD DATA LOCAL INFILE '/path/to/credit_card_transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@dummy, trans_datetime, category, amt, gender, city, state, city_pop, job, dob, is_fraud);
```

4. Run cleaning steps, then execute queries section by section

---

## Resume Description

> Analyzed 107K credit card transactions using MySQL to identify spending patterns, fraud hotspots by category and time of day, and high-risk transaction profiles — generating actionable recommendations for fraud prevention and targeted marketing strategies.

---

*Built as part of a FinTech product analytics portfolio demonstrating SQL-based fraud and spending analysis.*

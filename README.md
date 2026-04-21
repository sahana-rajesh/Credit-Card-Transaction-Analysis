# Credit Card Transaction Analysis | SQL

![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue?logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/Language-SQL-orange)
![Domain](https://img.shields.io/badge/Domain-FinTech%20%7C%20Fraud%20Analytics-green)
![Rows](https://img.shields.io/badge/Dataset-107K%20Transactions-lightgrey)

---

## Project Overview

SQL-based analysis of 107K credit card transactions (2019–2021) to uncover spending behavior, detect fraud patterns, and generate actionable recommendations for marketing and risk teams. Demonstrates a range of SQL techniques including aggregations, window functions, CTEs, and JOINs.

**Key business questions answered:**
- Which categories and states drive the most revenue?
- Which categories are fraud hotspots?
- When is fraud most likely to occur?
- What does a fraudulent transaction look like vs a legitimate one?
- Which U.S. regions carry the highest fraud risk?
- Which months had unusual fraud spikes?

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

## Key Results

| Metric | Value |
|---|---|
| Total Transactions | 107,753 |
| Total Revenue | $7,547,984 |
| Avg Transaction | $70.05 |
| Fraud Cases | 548 |
| Fraud Rate | 0.51% |
| Fraud Loss | $298,450 |

---

## Queries

| # | Query | Technique |
|---|---|---|
| 1 | Data overview — total transactions, revenue, date range | Aggregation |
| 2 | Fraud vs legitimate split | Window function |
| 3 | Spending by category | GROUP BY, ORDER BY |
| 4 | Fraud rate by category | CASE WHEN, aggregation |
| 5 | Spending and fraud by gender | GROUP BY |
| 6 | Top 10 states by revenue and fraud rate | GROUP BY, LIMIT |
| 7 | Fraud patterns by hour of day | HOUR(), GROUP BY |
| 8 | Monthly spending and fraud trend | DATE_FORMAT(), GROUP BY |
| 9 | Fraud vs legitimate amount analysis | GROUP BY, MIN/MAX/AVG |
| 10 | Executive summary dashboard | UNION ALL |
| 11 | Flag high-risk categories vs average fraud rate | **CTE** |
| 12 | Identify months with fraud spikes above average | **CTE** |
| 13 | Fraud and spend analysis by U.S. region | **JOIN** |

---

## Business Recommendations

**Fraud Prevention**
- Online categories (`shopping_net` 1.54%, `misc_net` 1.50%) are the highest fraud risk — apply stricter 2FA verification
- Transactions between **10pm–2am** are 5x more likely to be fraudulent — trigger automatic verification during these hours
- Fraudulent transactions average **8x higher spend** ($544 vs $67) — flag any transaction above $500 in high-risk categories for manual review
- December consistently shows the highest fraud activity — increase monitoring and review team capacity in Q4

**Marketing Strategy**
- **TX, NY, PA** are the top 3 revenue states — prioritize marketing budget and merchant partnerships here
- **Grocery and shopping** categories drive the most revenue — prime candidates for cashback offers and loyalty rewards
- Peak transaction volume occurs between **12pm–9pm** — optimal window for push notifications and promotional campaigns
- June, October, and December are seasonal spending peaks — align campaigns with these months

**Regional Risk Strategy**
- Regions with above-average fraud rates need stricter real-time monitoring rules and localized fraud alert campaigns
- High revenue, low fraud regions are ideal targets for premium card feature rollouts and loyalty program expansion

---

## SQL Techniques Demonstrated

- Aggregations — `SUM`, `AVG`, `MIN`, `MAX`, `COUNT`
- Filtering — `WHERE`, `HAVING`
- Grouping & sorting — `GROUP BY`, `ORDER BY`
- Window functions — `SUM() OVER()`
- Date functions — `HOUR()`, `DATE_FORMAT()`, `YEAR()`, `DATE_ADD()`
- Conditional logic — `CASE WHEN`
- CTEs — `WITH` clause for multi-step logic
- JOINs — `JOIN` with a lookup table for regional mapping
- Set operations — `UNION ALL`

---


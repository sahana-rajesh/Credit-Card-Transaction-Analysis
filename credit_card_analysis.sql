-- ============================================================
-- Credit Card Transaction Analysis
-- Tool: MySQL
-- Author: Sahana Rajesh
-- Dataset: ~107K credit card transactions (2019-2021)
-- Description: SQL-based fraud and spending analysis to surface
-- actionable insights for marketing and risk teams.
-- ============================================================


-- ============================================================
-- STEP 1: CREATE DATABASE & TABLE
-- ============================================================

CREATE DATABASE IF NOT EXISTS credit_card_analysis;
USE credit_card_analysis;

DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
    trans_datetime       DATETIME,
    category             VARCHAR(50),
    amt                  DECIMAL(10,2),
    gender               VARCHAR(5),
    city                 VARCHAR(50),
    state                VARCHAR(5),
    city_pop             INT,
    job                  VARCHAR(100),
    dob                  DATE,
    is_fraud             TINYINT
);

LOAD DATA LOCAL INFILE '/path/to/credit_card_transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@dummy, trans_datetime, category, amt, gender, city, state, city_pop, job, dob, is_fraud);

-- Fix bad date rows after import
DELETE FROM transactions WHERE YEAR(trans_datetime) = 0;
DELETE FROM transactions WHERE YEAR(trans_datetime) < 2000;

-- Fix year offset if dates imported incorrectly (off by 9 years)
UPDATE transactions
SET trans_datetime = DATE_ADD(trans_datetime, INTERVAL 9 YEAR);


-- ============================================================
-- STEP 2: DATA CLEANING
-- ============================================================

-- Check for duplicates
-- Result: Duplicates only existed on bad date rows (now removed)
SELECT
    trans_datetime, category, amt, gender, city,
    COUNT(*) AS duplicate_count
FROM transactions
GROUP BY trans_datetime, category, amt, gender, city
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 10;

-- Check for NULLs in key columns
-- Result: No nulls found in any key column
SELECT
    SUM(CASE WHEN amt IS NULL THEN 1 ELSE 0 END)      AS null_amt,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END)  AS null_category,
    SUM(CASE WHEN is_fraud IS NULL THEN 1 ELSE 0 END)  AS null_fraud,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END)      AS null_city
FROM transactions;


-- ============================================================
-- STEP 3: DATA OVERVIEW
-- ============================================================

-- Total transactions, revenue and date range
-- Result: 107,753 transactions | $7.5M revenue | Avg $70.05 | 2019-2021
SELECT
    COUNT(*)                            AS total_transactions,
    ROUND(SUM(amt), 2)                  AS total_revenue,
    ROUND(AVG(amt), 2)                  AS avg_transaction_value,
    MIN(trans_datetime)                 AS earliest_transaction,
    MAX(trans_datetime)                 AS latest_transaction
FROM transactions;

-- Fraud vs legitimate split
-- Result: 99.49% legitimate | 0.51% fraud | $298K fraud losses
SELECT
    is_fraud,
    COUNT(*)                                               AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)    AS percentage,
    ROUND(SUM(amt), 2)                                     AS total_amount
FROM transactions
GROUP BY is_fraud;


-- ============================================================
-- STEP 4: SPENDING BY CATEGORY
-- Business Question: Where are customers spending the most?
-- Result: Grocery POS ($4.5M) > Shopping POS > Gas & Transport
-- ============================================================

SELECT
    category,
    COUNT(*)                            AS transaction_count,
    ROUND(SUM(amt), 2)                  AS total_spend,
    ROUND(AVG(amt), 2)                  AS avg_spend
FROM transactions
WHERE is_fraud = 0
GROUP BY category
ORDER BY total_spend DESC;

-- Business Recommendation:
-- Grocery and shopping categories drive the most revenue.
-- These are prime candidates for cashback offers and
-- merchant partnership campaigns.


-- ============================================================
-- STEP 5: FRAUD RATE BY CATEGORY
-- Business Question: Which categories are fraud hotspots?
-- Result: shopping_net (1.54%) and misc_net (1.50%) are highest
-- ============================================================

SELECT
    category,
    COUNT(*)                                                        AS total_transactions,
    SUM(is_fraud)                                                   AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                     AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2)      AS fraud_amount
FROM transactions
GROUP BY category
ORDER BY fraud_rate_pct DESC;

-- Business Recommendation:
-- Online categories (shopping_net, misc_net) are the highest
-- fraud risk. Apply stricter 2FA verification for these.
-- Gas transactions show low-value fraud ($541 total) —
-- likely test transactions before larger fraud attempts.


-- ============================================================
-- STEP 6: SPENDING & FRAUD BY GENDER
-- Business Question: Do males or females spend more? Who has higher fraud?
-- Result: Similar spend. Males have 53% higher fraud rate (0.63% vs 0.41%)
-- ============================================================

SELECT
    gender,
    COUNT(*)                                            AS transaction_count,
    ROUND(SUM(amt), 2)                                  AS total_spend,
    ROUND(AVG(amt), 2)                                  AS avg_spend,
    SUM(is_fraud)                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)          AS fraud_rate_pct
FROM transactions
GROUP BY gender;

-- Business Recommendation:
-- Males have a significantly higher fraud rate.
-- Apply additional verification for high-value male transactions
-- in high-risk categories.


-- ============================================================
-- STEP 7: TOP 10 STATES BY REVENUE
-- Business Question: Which states drive the most revenue?
-- Result: TX, NY, PA are top 3. OH (1.12%) and MI (0.90%) highest fraud.
-- ============================================================

SELECT
    state,
    COUNT(*)                                            AS transaction_count,
    ROUND(SUM(amt), 2)                                  AS total_spend,
    ROUND(AVG(amt), 2)                                  AS avg_spend,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)          AS fraud_rate_pct
FROM transactions
GROUP BY state
ORDER BY total_spend DESC
LIMIT 10;

-- Business Recommendation:
-- Focus marketing budget on TX, NY, PA — top revenue states.
-- OH and MI need enhanced fraud monitoring and
-- stricter regional risk rules.


-- ============================================================
-- STEP 8: TRANSACTION PATTERNS BY HOUR
-- Business Question: When do most transactions happen? When is fraud highest?
-- Result: Hours 22-23 have 2.44-2.76% fraud rate — 5x higher than daytime
-- ============================================================

SELECT
    HOUR(trans_datetime)                                AS hour_of_day,
    COUNT(*)                                            AS transaction_count,
    ROUND(AVG(amt), 2)                                  AS avg_spend,
    SUM(is_fraud)                                       AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)          AS fraud_rate_pct
FROM transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Business Recommendation:
-- Fraud spikes dramatically between 10pm-2am.
-- Trigger automatic 2FA for all transactions during these
-- hours, especially in high-risk categories.
-- Peak transaction volume at 12pm-9pm = best window
-- for push notifications and promotional offers.


-- ============================================================
-- STEP 9: MONTHLY SPENDING TREND
-- Business Question: How does spending change over time?
-- Result: June, March, October are peak months. December fraud spikes.
-- ============================================================

SELECT
    DATE_FORMAT(trans_datetime, '%Y-%m')                AS month,
    COUNT(*)                                            AS transaction_count,
    ROUND(SUM(amt), 2)                                  AS total_spend,
    ROUND(AVG(amt), 2)                                  AS avg_spend,
    SUM(is_fraud)                                       AS fraud_count
FROM transactions
GROUP BY month
ORDER BY month;

-- Business Recommendation:
-- Align marketing campaigns with June, October, December peaks.
-- Increase fraud monitoring in December — holiday season
-- consistently shows the highest fraud count.


-- ============================================================
-- STEP 10: HIGH-VALUE TRANSACTION ANALYSIS
-- Business Question: What do our biggest transactions look like?
-- Result: Travel dominates high-value transactions (up to $28,948)
--         All top 20 high-value transactions are legitimate
-- ============================================================

SELECT
    category,
    gender,
    state,
    ROUND(amt, 2)                                       AS transaction_amount,
    is_fraud,
    trans_datetime
FROM transactions
WHERE amt > (SELECT AVG(amt) * 3 FROM transactions)
ORDER BY amt DESC
LIMIT 20;

-- Business Recommendation:
-- High-value customers are legitimate travelers and shoppers.
-- Offer concierge-level service and premium card benefits
-- to retain these customers.


-- ============================================================
-- STEP 11: FRAUD AMOUNT ANALYSIS
-- Business Question: Are fraudulent transactions higher or lower value?
-- Result: Avg fraud = $544 vs avg legitimate = $67 (8x higher)
--         Max fraud = $1,313 — fraudsters stay under a threshold
-- ============================================================

SELECT
    is_fraud,
    COUNT(*)                                            AS transaction_count,
    ROUND(AVG(amt), 2)                                  AS avg_amount,
    ROUND(MIN(amt), 2)                                  AS min_amount,
    ROUND(MAX(amt), 2)                                  AS max_amount,
    ROUND(SUM(amt), 2)                                  AS total_amount
FROM transactions
GROUP BY is_fraud;

-- Business Recommendation:
-- Fraudsters spend 8x more per transaction than legitimate users.
-- Flag any transaction above $500 in high-risk categories
-- (shopping_net, misc_net) for immediate manual review.


-- ============================================================
-- STEP 12: CITY SIZE VS FRAUD RATE
-- Business Question: Are larger cities more prone to fraud?
-- Result: Small cities have the HIGHEST fraud rate (0.55%)
--         Metro cities are actually the safest (0.38%)
-- ============================================================

SELECT
    CASE
        WHEN city_pop < 10000   THEN 'Small (< 10K)'
        WHEN city_pop < 100000  THEN 'Medium (10K-100K)'
        WHEN city_pop < 500000  THEN 'Large (100K-500K)'
        ELSE 'Metro (500K+)'
    END AS city_size,
    COUNT(*)                                            AS transaction_count,
    ROUND(AVG(amt), 2)                                  AS avg_spend,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)          AS fraud_rate_pct
FROM transactions
GROUP BY city_size
ORDER BY fraud_rate_pct DESC;

-- Business Recommendation:
-- Counter-intuitively, small city customers face more fraud risk.
-- This may indicate weaker account security awareness.
-- Target fraud education campaigns and alerts at rural customers.


-- ============================================================
-- STEP 13: EXECUTIVE SUMMARY DASHBOARD
-- Key KPIs in a single view for reporting
-- ============================================================

SELECT 'Total Transactions'   AS metric, COUNT(*)                                                           AS value FROM transactions
UNION ALL
SELECT 'Total Revenue ($)',    ROUND(SUM(amt), 2)                                                           FROM transactions
UNION ALL
SELECT 'Avg Transaction ($)',  ROUND(AVG(amt), 2)                                                           FROM transactions
UNION ALL
SELECT 'Total Fraud Cases',    SUM(is_fraud)                                                                FROM transactions
UNION ALL
SELECT 'Fraud Rate (%)',       ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                                   FROM transactions
UNION ALL
SELECT 'Fraud Loss ($)',       ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2)                    FROM transactions;

-- Result:
-- Total Transactions  | 107,753
-- Total Revenue ($)   | 7,547,984.77
-- Avg Transaction ($) | 70.05
-- Total Fraud Cases   | 548
-- Fraud Rate (%)      | 0.51
-- Fraud Loss ($)      | 298,450.77

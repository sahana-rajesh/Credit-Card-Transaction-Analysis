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

-- Clean bad date rows after import
DELETE FROM transactions WHERE YEAR(trans_datetime) = 0;
DELETE FROM transactions WHERE YEAR(trans_datetime) < 2000;

-- Fix year offset (dates imported off by 9 years)
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
-- QUERY 1: DATA OVERVIEW
-- Result: 107,753 transactions | $7.5M revenue | Avg $70.05 | 2019-2021
-- ============================================================

SELECT
    COUNT(*)                            AS total_transactions,
    ROUND(SUM(amt), 2)                  AS total_revenue,
    ROUND(AVG(amt), 2)                  AS avg_transaction_value,
    MIN(trans_datetime)                 AS earliest_transaction,
    MAX(trans_datetime)                 AS latest_transaction
FROM transactions;


-- ============================================================
-- QUERY 2: FRAUD VS LEGITIMATE SPLIT
-- Business Question: What is our overall fraud rate?
-- Result: 99.49% legitimate | 0.51% fraud | $298K fraud losses
-- ============================================================

SELECT
    is_fraud,
    COUNT(*)                                                AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)     AS percentage,
    ROUND(SUM(amt), 2)                                      AS total_amount
FROM transactions
GROUP BY is_fraud;

-- Business Insight:
-- 0.51% fraud rate = $298K in losses on 548 transactions.
-- Small percentage but significant financial impact.


-- ============================================================
-- QUERY 3: SPENDING BY CATEGORY
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

-- Recommendation:
-- Grocery and shopping categories drive the most revenue.
-- Prime candidates for cashback offers and merchant partnerships.


-- ============================================================
-- QUERY 4: FRAUD RATE BY CATEGORY
-- Business Question: Which categories are fraud hotspots?
-- Result: shopping_net (1.54%) and misc_net (1.50%) highest fraud rates
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

-- Recommendation:
-- Online categories (shopping_net, misc_net) need stricter 2FA.
-- Gas transactions show micro-fraud pattern ($541 total loss) —
-- likely test transactions before larger fraud attempts.


-- ============================================================
-- QUERY 5: SPENDING & FRAUD BY GENDER
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

-- Recommendation:
-- Males have a significantly higher fraud rate.
-- Apply additional verification for high-value male transactions
-- in high-risk online categories.


-- ============================================================
-- QUERY 6: TOP 10 STATES BY REVENUE
-- Business Question: Which states drive the most revenue?
-- Result: TX, NY, PA top 3. OH (1.12%) and MI (0.90%) highest fraud.
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

-- Recommendation:
-- Focus marketing budget on TX, NY, PA.
-- OH and MI need enhanced fraud monitoring and stricter risk rules.


-- ============================================================
-- QUERY 7: FRAUD BY HOUR OF DAY
-- Business Question: When is fraud most likely to occur?
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

-- Recommendation:
-- Trigger automatic 2FA for all transactions between 10pm-2am.
-- Peak transaction volume at 12pm-9pm = best window for
-- push notifications and promotional offers.


-- ============================================================
-- QUERY 8: MONTHLY SPENDING TREND
-- Business Question: How does spending and fraud change over time?
-- Result: June, March, October peak months. December fraud spikes.
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

-- Recommendation:
-- Align marketing campaigns with June, October, December peaks.
-- Increase fraud monitoring in Q4 — holiday season consistently
-- shows the highest fraud activity.


-- ============================================================
-- QUERY 9: FRAUD AMOUNT ANALYSIS
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

-- Recommendation:
-- Flag any transaction above $500 in high-risk categories
-- (shopping_net, misc_net) for immediate manual review.


-- ============================================================
-- QUERY 10: EXECUTIVE SUMMARY DASHBOARD
-- Key KPIs in a single view for reporting
-- Result: 107,753 transactions | $7.5M revenue | 0.51% fraud | $298K loss
-- ============================================================

SELECT 'Total Transactions'   AS metric, COUNT(*)                                                        AS value FROM transactions
UNION ALL
SELECT 'Total Revenue ($)',    ROUND(SUM(amt), 2)                                                        FROM transactions
UNION ALL
SELECT 'Avg Transaction ($)',  ROUND(AVG(amt), 2)                                                        FROM transactions
UNION ALL
SELECT 'Total Fraud Cases',    SUM(is_fraud)                                                             FROM transactions
UNION ALL
SELECT 'Fraud Rate (%)',       ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                                FROM transactions
UNION ALL
SELECT 'Fraud Loss ($)',       ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END), 2)                 FROM transactions;


-- ============================================================
-- QUERY 11: CTE — FLAG HIGH-RISK CATEGORIES
-- Business Question: Which categories exceed the average fraud rate?
-- Technique: CTE to calculate avg fraud rate, then compare each category
-- Result: shopping_net and misc_net flagged as HIGH RISK
-- ============================================================

WITH category_fraud AS (
    -- Step 1: Calculate fraud rate per category
    SELECT
        category,
        COUNT(*)                                                AS total_transactions,
        SUM(is_fraud)                                           AS fraud_count,
        ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)             AS fraud_rate_pct
    FROM transactions
    GROUP BY category
),
avg_fraud AS (
    -- Step 2: Calculate the overall average fraud rate
    SELECT ROUND(AVG(fraud_rate_pct), 2) AS avg_fraud_rate
    FROM category_fraud
)
-- Step 3: Flag categories above average as HIGH RISK
SELECT
    cf.category,
    cf.total_transactions,
    cf.fraud_count,
    cf.fraud_rate_pct,
    af.avg_fraud_rate,
    CASE
        WHEN cf.fraud_rate_pct > af.avg_fraud_rate THEN 'HIGH RISK'
        ELSE 'Normal'
    END AS risk_flag
FROM category_fraud cf
CROSS JOIN avg_fraud af
ORDER BY cf.fraud_rate_pct DESC;

-- Recommendation:
-- Categories flagged as HIGH RISK should be prioritized for
-- enhanced fraud monitoring, stricter verification, and
-- real-time transaction alerts.


-- ============================================================
-- QUERY 12: CTE — MONTHS WHERE FRAUD SPIKED ABOVE AVERAGE
-- Business Question: Which months had unusually high fraud activity?
-- Technique: CTE to calculate monthly fraud count vs overall average
-- Result: Identifies specific months requiring increased monitoring
-- ============================================================

WITH monthly_fraud AS (
    -- Step 1: Get fraud count per month
    SELECT
        DATE_FORMAT(trans_datetime, '%Y-%m')            AS month,
        COUNT(*)                                        AS total_transactions,
        SUM(is_fraud)                                   AS fraud_count,
        ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)     AS fraud_rate_pct
    FROM transactions
    GROUP BY month
),
avg_monthly AS (
    -- Step 2: Calculate average monthly fraud count
    SELECT ROUND(AVG(fraud_count), 2) AS avg_monthly_fraud
    FROM monthly_fraud
)
-- Step 3: Flag months above average
SELECT
    mf.month,
    mf.total_transactions,
    mf.fraud_count,
    mf.fraud_rate_pct,
    am.avg_monthly_fraud,
    CASE
        WHEN mf.fraud_count > am.avg_monthly_fraud THEN 'Above Average'
        ELSE 'Normal'
    END AS fraud_spike_flag
FROM monthly_fraud mf
CROSS JOIN avg_monthly am
ORDER BY mf.fraud_count DESC;

-- Recommendation:
-- Months flagged as Above Average should trigger increased
-- staffing for fraud review teams and tighter transaction
-- monitoring rules during those periods.


-- ============================================================
-- QUERY 13: JOIN — FRAUD ANALYSIS BY U.S. REGION
-- Business Question: Which U.S. region has the highest fraud rate?
-- Technique: Create a state_regions lookup table and JOIN to transactions
-- Result: Regional fraud patterns to guide geographic risk strategy
-- ============================================================

-- Create region lookup table
DROP TABLE IF EXISTS state_regions;

CREATE TABLE state_regions (
    state       VARCHAR(5),
    region      VARCHAR(20)
);

INSERT INTO state_regions (state, region) VALUES
('CT','Northeast'), ('ME','Northeast'), ('MA','Northeast'),
('NH','Northeast'), ('RI','Northeast'), ('VT','Northeast'),
('NJ','Northeast'), ('NY','Northeast'), ('PA','Northeast'),
('IL','Midwest'),   ('IN','Midwest'),   ('MI','Midwest'),
('OH','Midwest'),   ('WI','Midwest'),   ('IA','Midwest'),
('KS','Midwest'),   ('MN','Midwest'),   ('MO','Midwest'),
('NE','Midwest'),   ('ND','Midwest'),   ('SD','Midwest'),
('AL','South'),     ('AR','South'),     ('FL','South'),
('GA','South'),     ('KY','South'),     ('LA','South'),
('MS','South'),     ('NC','South'),     ('SC','South'),
('TN','South'),     ('VA','South'),     ('WV','South'),
('TX','South'),     ('OK','South'),     ('MD','South'),
('DE','South'),     ('DC','South'),
('AZ','West'),      ('CO','West'),      ('ID','West'),
('MT','West'),      ('NV','West'),      ('NM','West'),
('UT','West'),      ('WY','West'),      ('AK','West'),
('CA','West'),      ('HI','West'),      ('OR','West'),
('WA','West');

-- JOIN transactions to regions and analyze fraud by region
SELECT
    sr.region,
    COUNT(*)                                            AS total_transactions,
    ROUND(SUM(t.amt), 2)                                AS total_spend,
    ROUND(AVG(t.amt), 2)                                AS avg_spend,
    SUM(t.is_fraud)                                     AS fraud_count,
    ROUND(SUM(t.is_fraud) * 100.0 / COUNT(*), 2)        AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN t.is_fraud = 1 THEN t.amt ELSE 0 END), 2) AS fraud_loss
FROM transactions t
JOIN state_regions sr ON t.state = sr.state
GROUP BY sr.region
ORDER BY fraud_rate_pct DESC;

-- Recommendation:
-- Regions with high fraud rates should have stricter real-time
-- monitoring rules and localized fraud alert campaigns.
-- High revenue regions with low fraud = ideal targets for
-- premium card feature rollouts and loyalty programs.

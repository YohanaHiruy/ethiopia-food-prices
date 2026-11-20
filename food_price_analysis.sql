-- =====================================================================
-- Ethiopia Food Prices (WFP) Analysis
-- Dataset : wfp_food_prices_eth.csv (66,125 rows, 2000-2026)
-- Database: MySQL 8.0
-- Author: Yohana Hiruy
-- =====================================================================

USE foods;


-- =====================================================================
-- 1. DATA QUALITY CHECKS
-- =====================================================================

-- 1.1 Row count and date range.
SELECT
    COUNT(*)    AS total_rows,
    MIN(`date`) AS first_date,
    MAX(`date`) AS last_date
FROM food_prices;

-- 1.2 Duplicate observations (same date, market, food, unit and price type).
SELECT
    `date`, market_id, commodity_id, unit, pricetype,
    COUNT(*) AS times
FROM food_prices
GROUP BY `date`, market_id, commodity_id, unit, pricetype
HAVING COUNT(*) > 1;

-- 1.3 i saw that Units are mixed (KG, 100 KG, Head, L, Day...), so prices cannot be compared directly.
SELECT
    unit,
    COUNT(*) AS rows_count
FROM food_prices
GROUP BY unit
ORDER BY rows_count DESC;

-- 1.4 Retail vs wholesale rows.
SELECT
    pricetype,
    COUNT(*) AS rows_count
FROM food_prices
GROUP BY pricetype;


-- =====================================================================
-- 2. CLEAN VIEW
-- Keeps only prices per KG and puts them on the same basis (100 KG prices / 100).
-- Excludes wages, livestock, liquids and exchange-rate rows.
-- =====================================================================

CREATE OR REPLACE VIEW food_clean AS
SELECT
    *,
    CASE
        WHEN unit = '100 KG' THEN price / 100
        ELSE price
    END           AS price_per_kg,
    YEAR(`date`)  AS yr,
    MONTH(`date`) AS mth
FROM food_prices
WHERE unit IN ('KG', '100 KG');

-- 2.1 Checking the view. 
SELECT
    COUNT(*)                  AS total_rows,
    COUNT(DISTINCT commodity) AS commodities
FROM food_clean;


-- =====================================================================
-- 3. DATA QUALITY CATCH: THERE ARE MAYBE LOW  PRICES
-- Some retail wheat prices labelled "100 KG" look like prices per KG,
-- so dividing them by 100 gives values under 1 birr. Mostly 2007-2015.
-- Very few rows are affected from 2020 onward, so the questions below use 2020+
-- unless stated otherwise.
-- =====================================================================

-- 3.1 Rows under 1 birr per kg, by year.
SELECT
    yr,
    COUNT(*) AS rows_under_1_etb
FROM food_clean
WHERE price_per_kg < 1
GROUP BY yr
ORDER BY yr;

-- 3.2 Example: wheat in Diredawa, 2010.
-- The retail price (about 5-6) is labelled 100 KG but looks like a price per KG,
-- because wholesale in the same market and month is about 450-580 per 100 KG.
SELECT
    wholesale.`date`,
    wholesale.market,
    wholesale.price AS wholesale_price_100kg,
    retail.price    AS retail_price_labelled_100kg
FROM food_prices AS wholesale
JOIN food_prices AS retail
    ON  wholesale.market_id    = retail.market_id
    AND wholesale.`date`       = retail.`date`
    AND wholesale.commodity_id = retail.commodity_id
WHERE wholesale.pricetype = 'Wholesale'
  AND retail.pricetype    = 'Retail'
  AND wholesale.commodity = 'Wheat'
  AND wholesale.market    = 'Diredawa'
ORDER BY wholesale.`date`
LIMIT 5;


-- =====================================================================
-- 4. MY ANALYSIS QUESTIONS
-- =====================================================================

-- Q1: How has the retail price of white maize changed since 2020?
SELECT
    yr,
    ROUND(AVG(price_per_kg), 2) AS avg_price_kg,
    COUNT(*)                    AS observations,
    COUNT(DISTINCT market)      AS markets
FROM food_clean
WHERE commodity = 'Maize (white)'
  AND pricetype = 'Retail'
  AND yr BETWEEN 2020 AND 2025
GROUP BY yr
ORDER BY yr;


-- Q2: Which foods grew or rose fastest in retail price between 2020 and 2025?
-- Only foods with at least 30 observations in both years are compared.
SELECT
    commodity,
    ROUND(AVG(CASE WHEN yr = 2020 THEN price_per_kg END), 2) AS avg_2020,
    ROUND(AVG(CASE WHEN yr = 2025 THEN price_per_kg END), 2) AS avg_2025,
    ROUND((AVG(CASE WHEN yr = 2025 THEN price_per_kg END)
         / AVG(CASE WHEN yr = 2020 THEN price_per_kg END) - 1) * 100, 0) AS pct_change
FROM food_clean
WHERE pricetype = 'Retail'
  AND yr IN (2020, 2025)
GROUP BY commodity
HAVING COUNT(CASE WHEN yr = 2020 THEN 1 END) >= 30
   AND COUNT(CASE WHEN yr = 2025 THEN 1 END) >= 30
ORDER BY pct_change DESC;

-- Only foods with at least 30 observations in both years are compared.
-- Q3: Do white maize prices differ between regions? Retail, 2025, regions with 3+ markets?
SELECT
    admin1                      AS region,
    ROUND(AVG(price_per_kg), 2) AS avg_price_kg,
    COUNT(*)                    AS observations,
    COUNT(DISTINCT market)      AS markets
FROM food_clean
WHERE commodity = 'Maize (white)'
  AND pricetype = 'Retail'
  AND yr = 2025
  AND admin1 IS NOT NULL
GROUP BY admin1
HAVING COUNT(DISTINCT market) >= 3
ORDER BY avg_price_kg;


-- Q4: How much higher is the retail price than the wholesale price for white maize?
-- Method: matched pairs (same market, month and food), so years and markets are not mixed.
SELECT
    COUNT(*)                                                              AS matched_pairs,
    COUNT(DISTINCT wholesale.market)                                      AS markets,
    ROUND(AVG(wholesale.price_per_kg), 2)                                 AS avg_wholesale_kg,
    ROUND(AVG(retail.price_per_kg), 2)                                    AS avg_retail_kg,
    ROUND(AVG(retail.price_per_kg / wholesale.price_per_kg - 1) * 100, 1) AS avg_retail_markup_pct
FROM food_clean AS wholesale
JOIN food_clean AS retail
    ON  wholesale.market_id    = retail.market_id
    AND wholesale.`date`       = retail.`date`
    AND wholesale.commodity_id = retail.commodity_id
WHERE wholesale.pricetype = 'Wholesale'
  AND retail.pricetype    = 'Retail'
  AND wholesale.commodity = 'Maize (white)';


-- Q5: Which months had the biggest jumps in the white maize retail price?
-- I used  the window function LAG() to compare each month with the previous one. 2020 onward.

WITH monthly AS (
    SELECT
        DATE_FORMAT(`date`, '%Y-%m') AS ym,
        AVG(price_per_kg)            AS avg_price,
        COUNT(DISTINCT market)       AS markets
    FROM food_clean
    WHERE commodity = 'Maize (white)'
      AND pricetype = 'Retail'
      AND yr >= 2020
    GROUP BY DATE_FORMAT(`date`, '%Y-%m')
),
changes AS (
    SELECT
        ym,
        avg_price,
        markets,
        LAG(avg_price) OVER (ORDER BY ym) AS prev_price
    FROM monthly
)
SELECT
    ym                                                AS month,
    ROUND(prev_price, 2)                              AS prev_price,
    ROUND(avg_price, 2)                               AS avg_price,
    ROUND((avg_price / prev_price - 1) * 100, 1)      AS change_pct,
    markets
FROM changes
WHERE prev_price IS NOT NULL
ORDER BY change_pct DESC
LIMIT 10;
-- ============================================================
-- India Commercial Vehicle Registrations Analysis
-- SQL Queries | Data source: VAHAN, Govt. of India
-- Table: cv_reg (pre-filtered to Commercial Vehicles only —
--        Heavy Goods Vehicle & Light Goods Vehicle)
-- ============================================================

-- Query 1: Top 10 states by total CV registrations
-- Uses a CTE + RANK() window function
WITH state_totals AS (
    SELECT state_name, SUM(registrations) AS total_registrations
    FROM cv_reg
    GROUP BY state_name
)
SELECT state_name, total_registrations,
       RANK() OVER (ORDER BY total_registrations DESC) AS state_rank
FROM state_totals
ORDER BY state_rank
LIMIT 10;


-- Query 2: Year-over-year growth by state (reliable years only: 2021-2023)
-- Uses LAG() window function partitioned by state to correctly compare
-- each state to its own prior year. 2019 and 2024 excluded due to
-- incomplete/partial year data (see README Data Quality Notes).
WITH yearly AS (
    SELECT state_name, strftime('%Y', date) AS year, SUM(registrations) AS total_registrations
    FROM cv_reg
    WHERE strftime('%Y', date) IN ('2021', '2022', '2023')
    GROUP BY state_name, year
)
SELECT state_name, year, total_registrations,
       LAG(total_registrations) OVER (PARTITION BY state_name ORDER BY year) AS prev_year,
       ROUND(
         (total_registrations - LAG(total_registrations) OVER (PARTITION BY state_name ORDER BY year)) * 100.0
         / LAG(total_registrations) OVER (PARTITION BY state_name ORDER BY year), 2
       ) AS yoy_growth_pct
FROM yearly
ORDER BY yoy_growth_pct DESC;


-- Query 3: Top 15 RTOs (district-level) by CV registrations
SELECT office_name AS rto, state_name, SUM(registrations) AS total_registrations
FROM cv_reg
GROUP BY office_name, state_name
ORDER BY total_registrations DESC
LIMIT 15;


-- Query 4: Heavy vs Light Goods Vehicle split (national share)
-- Uses window function to calculate percentage of total
SELECT type, SUM(registrations) AS total_registrations,
       ROUND(SUM(registrations) * 100.0 / SUM(SUM(registrations)) OVER (), 2) AS pct_share
FROM cv_reg
GROUP BY type
ORDER BY total_registrations DESC;


-- Query 5: National yearly trend (2020-2023, reliable years)
-- Supporting query for trend line chart / data quality notes
SELECT strftime('%Y', date) AS year, SUM(registrations) AS total_registrations
FROM cv_reg
WHERE strftime('%Y', date) IN ('2020', '2021', '2022', '2023')
GROUP BY year
ORDER BY year;
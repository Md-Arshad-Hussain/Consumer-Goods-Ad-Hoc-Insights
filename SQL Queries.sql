-- Q1. Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
-- business in the  APAC  region. 

SELECT DISTINCT market
FROM dim_customer
WHERE customer = "Atliq Exclusive" 
AND region = "APAC";

-- Q2. What is the percentage of unique product increase in 2021 vs. 2020? The 
-- final output contains these fields, 
-- unique_products_2020 
-- unique_products_2021 
-- percentage_chg 

WITH cte1 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
    FROM fact_sales_monthly
    WHERE fiscal_year = '2020'
),
cte2 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM fact_sales_monthly
    WHERE fiscal_year = '2021'
)
SELECT unique_products_2020, 
       unique_products_2021,
       ROUND((unique_products_2021 - unique_products_2020) * 100 / unique_products_2020, 2) AS percentage_chg
FROM cte1
JOIN cte2;

-- Q3. Provide a report with all the unique product counts for each  segment  and 
-- sort them in descending order of product counts. The final output contains 2 fields, 
-- segment 
-- product_count

SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- Q4. Follow-up: Which segment had the most increase in unique products in 
-- 2021 vs 2020? The final output contains these fields, 
-- segment 
-- product_count_2020 
-- product_count_2021 
-- difference 

WITH CTE1 AS (
    SELECT p.segment,
        COUNT(DISTINCT p.product_code) AS product_count_2020
    FROM dim_product p
    JOIN fact_sales_monthly s
    ON p.product_code = s.product_code
    WHERE s.fiscal_year = 2020
    GROUP BY p.segment
),
CTE2 AS (
    SELECT p.segment,
        COUNT(DISTINCT p.product_code) AS product_count_2021
    FROM dim_product p
    JOIN fact_sales_monthly s
    ON p.product_code = s.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY p.segment
)
SELECT 
      CTE1.segment,
      product_count_2020,
      product_count_2021,
	 (product_count_2021 - product_count_2020)  AS difference
FROM CTE1
JOIN CTE2
ON CTE1.segment = CTE2.segment
ORDER BY difference DESC;

-- Q5.  Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, 
-- product_code 
-- product 
-- manufacturing_cost 

SELECT p.product_code, p.product, m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m 
ON p.product_code = m.product_code
WHERE m.manufacturing_cost = (
        SELECT MAX(manufacturing_cost) 
        FROM fact_manufacturing_cost
) 
    OR
    m.manufacturing_cost = (
        SELECT MIN(manufacturing_cost) 
        FROM fact_manufacturing_cost
    );

-- Q6. Generate a report which contains the top 5 customers who received an 
-- average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
-- Indian  market. The final output contains these fields, 
-- customer_code 
-- customer 
-- average_discount_percentage 

SELECT c.customer_code, c.customer, ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage 
FROM fact_pre_invoice_deductions d
JOIN dim_customer c
ON c.customer_code = d.customer_code
WHERE fiscal_year = "2021" 
AND sub_zone = "India"
GROUP BY c.customer_code, c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq 
-- Exclusive”  for each month. This analysis helps to get an idea of low and 
-- high-performing months and take strategic decisions. 
-- The final report contains these columns: 
-- Month 
-- Year 
-- Gross sales Amount 

SELECT MONTHNAME(s.date) AS month, s.fiscal_year, CONCAT(ROUND(SUM((s.sold_quantity*g.gross_price))/1000000,2)," M") AS gross_sales
FROM fact_sales_monthly s
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN fact_gross_price g
ON s.product_code = g.product_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY  MONTHNAME(s.date), s.fiscal_year
ORDER BY fiscal_year;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final 
-- output contains these fields sorted by the total_sold_quantity, 
-- Quarter 
-- total_sold_quantity 

SELECT
    CASE 
        WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
        WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
        WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
        ELSE 'Q4'
    END AS Quarter,
    CONCAT(ROUND(SUM(sold_quantity) / 1000000, 2), ' M') AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

-- 9.  Which channel helped to bring more gross sales in the fiscal year 2021 
-- and the percentage of contribution?  The final output  contains these fields, 
-- channel 
-- gross_sales_mln 
-- percentage 

WITH CTE AS (
  SELECT 
    c.channel,
    ROUND(SUM(s.sold_quantity * g.gross_price) / 1000000, 2) AS gross_sales_mln 
  FROM dim_customer c
  JOIN fact_sales_monthly s ON c.customer_code = s.customer_code
  JOIN fact_gross_price g ON s.product_code = g.product_code
  WHERE s.fiscal_year = '2021'
  GROUP BY c.channel
  ORDER BY gross_sales_mln DESC
)
SELECT *,
  CONCAT(ROUND(gross_sales_mln * 100 / SUM(gross_sales_mln) OVER (), 2), "%") AS percentage
FROM CTE;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields, 
-- division 
-- product_code 
-- product 
-- total_sold_quantity 
-- rank_order

WITH CTE AS (
    SELECT 
        p.division, s.product_code, p.product, 
        CONCAT(ROUND(SUM(s.sold_quantity) / 1000000, 2), " M") AS total_sold_quantity,
        RANK() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order
    FROM dim_product p 
    JOIN fact_sales_monthly s 
	ON p.product_code = s.product_code
    WHERE fiscal_year = 2021
    GROUP BY 
        p.division, s.product_code, p.product
)
SELECT * FROM CTE
WHERE rank_order IN (1, 2, 3);








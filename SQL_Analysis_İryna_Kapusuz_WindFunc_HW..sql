----Task 1 
---1. We find top 5 customers per sales channel
---2. We find total sales and % contribution within each channel called KPI;

WITH sales_summary AS (
    SELECT
        ch.channel_desc,
        c.cust_first_name,
        c.cust_last_name,

--- Total sales per customer per channel from sh.sales;
        SUM(s.amount_sold) AS total_sales,

--- Total sales per channel 
        SUM(SUM(s.amount_sold)) OVER (
            PARTITION BY ch.channel_desc
        ) AS channel_total,

--- Rank customers by sales inside each channel
        DENSE_RANK() OVER (            ------we use dense rank to avoid ties
            PARTITION BY ch.channel_desc
            ORDER BY SUM(s.amount_sold) DESC
        ) AS rnk
    FROM sh.sales s
    JOIN sh.customers c ON s.cust_id = c.cust_id
    JOIN sh.channels ch ON s.channel_id = ch.channel_id
    GROUP BY
        ch.channel_desc,
        c.cust_first_name,
        c.cust_last_name
)

SELECT
    channel_desc,
    cust_first_name,
    cust_last_name,

--- Rounding total_sales with 2 decimals;
    ROUND(total_sales, 2) AS total_sales,

--- Counting sales percentage, rounding it with 4 decimals + % sign
    ROUND((total_sales / channel_total) * 100, 4)::text || '%' 
        AS kpi
FROM sales_summary
WHERE rnk <= 5
ORDER BY
    channel_desc,
    total_sales DESC;

SELECT *
FROM sh.sales;

---Task 2
---Calculate total sales for Photo products in Asia for year 2000
---We will find total sales for:
---All products in the Photo category
---Asian region
---Year 2000

SELECT
    p.prod_name AS product_name,
    ROUND(SUM(s.amount_sold), 2) AS "YEAR_SUM"
FROM sh.sales s
JOIN sh.products  p  ON p.prod_id = s.prod_id   ---finding product category
JOIN sh.customers cu ON cu.cust_id = s.cust_id   ---connecting sales to customer location
JOIN sh.countries co ON co.country_id = cu.country_id  ---finding region
JOIN sh.times     t  ON t.time_id = s.time_id   ---to filter by year
WHERE p.prod_category = 'Photo'      
  AND co.country_region = 'Asia'     
  AND t.calendar_year = 2000         
GROUP BY p.prod_name
ORDER BY "YEAR_SUM" DESC;



 ---Task 4 Sales report for Jan 2000, Feb 2000, March 2000 
--- for Europe and Americas regions.


SELECT
    t.calendar_month_desc,                     
    p.prod_category,                            

-- Total sales for Americas
-- FILTER means only rows where country_region = 'Americas' are summed and rounded

    ROUND(
        SUM(s.amount_sold) FILTER (WHERE co.country_region = 'Americas'),
        2
    ) AS "Americas Sales",

 -- Total sales for Europe
--  FILTER means only rows where country_region = 'Europe' are summed and rounded
    ROUND(
        SUM(s.amount_sold) FILTER (WHERE co.country_region = 'Europe'),
        2
    ) AS "Europe Sales"

FROM sh.sales s
JOIN sh.times t
    ON t.time_id = s.time_id                    -- Joining sales to time
JOIN sh.products p
    ON p.prod_id = s.prod_id                   -- Joıning sales to products
JOIN sh.customers cu
    ON cu.cust_id = s.cust_id                  -- Joining sales to customers
JOIN sh.countries co
    ON co.country_id = cu.country_id           -- Finding region from country

WHERE t.calendar_year = 2000                   -- Year 2000
  AND t.calendar_month_number IN (1, 2, 3)     -- January, February,March
  AND co.country_region IN ('Europe', 'Americas')

GROUP BY
    t.calendar_month_desc,
    p.prod_category

ORDER BY
    t.calendar_month_desc,
    p.prod_category;

  
---Task 3
---1.Total sales per channel per year for each customer -1998,1999,2001
---2.Rank customers inside each channel and each year separately
---3.Keep only customers who are Top 300 for that channel-year
---4.find customers who are Top-300 in all three years within the same channel
---5.For each qualifieds we sum their total_sales and perform rounding
---across the three years.
WITH yearly_channel_sales AS (           ----total channel sales
    SELECT
        s.channel_id,
        t.calendar_year AS sales_year,
        s.cust_id,
        SUM(s.amount_sold) AS total_sales
    FROM sh.sales s
    JOIN sh.times t
      ON t.time_id = s.time_id
    WHERE t.calendar_year IN (1998, 1999, 2001)
    GROUP BY s.channel_id, t.calendar_year, s.cust_id
),
ranked AS (
    SELECT
        ycs.channel_id,
        ycs.sales_year,
        ycs.cust_id,
        ycs.total_sales,
        DENSE_RANK() OVER (                ---we use dense rank to avoid tie gaps
            PARTITION BY ycs.channel_id, ycs.sales_year
            ORDER BY ycs.total_sales DESC
        ) AS rn                                  -----ranking customers
    FROM yearly_channel_sales ycs
),
top300 AS (                                     ----300 customers per channel per year
    SELECT
        channel_id,
        sales_year,
        cust_id,
        total_sales
    FROM ranked
    WHERE rn <= 300
),
qualified AS (
    SELECT
        channel_id,
        cust_id
    FROM top300
    GROUP BY channel_id, cust_id
    HAVING COUNT(DISTINCT sales_year) = 3
),
final_totals AS (
    SELECT
        tp.channel_id,
        tp.cust_id,
        SUM(tp.total_sales) AS amount_sold
    FROM top300 tp
    JOIN qualified q
      ON q.channel_id = tp.channel_id
     AND q.cust_id   = tp.cust_id
    GROUP BY tp.channel_id, tp.cust_id
)
SELECT
    ch.channel_desc,
    cu.cust_id,
    cu.cust_last_name,
    cu.cust_first_name,
    ROUND(ft.amount_sold, 2) AS amount_sold
FROM final_totals ft
JOIN sh.channels ch
  ON ch.channel_id = ft.channel_id
JOIN sh.customers cu
  ON cu.cust_id = ft.cust_id
ORDER BY
    ch.channel_desc,
    amount_sold DESC;


SELECT
        s.channel_id,                       
        t.calendar_year AS sales_year,      
        s.cust_id,                          
        SUM(s.amount_sold) AS total_sales   
    FROM sh.sales s
    JOIN sh.times t
      ON t.time_id = s.time_id              
    WHERE t.calendar_year IN (1998, 1999, 2001)
     s.channel_id,
        t.calendar_year,
        s.cust_id;
		

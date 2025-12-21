
----Task 1;

WITH base AS (
    SELECT
        co.country_region,
        t.calendar_year,
        ch.channel_desc,
        SUM(s.amount_sold) AS amount_sold
    FROM sh.sales s
    JOIN sh.times t
        ON t.time_id = s.time_id
    JOIN sh.channels ch
        ON ch.channel_id = s.channel_id
    JOIN sh.customers cu
        ON cu.cust_id = s.cust_id
    JOIN sh.countries co
        ON co.country_id = cu.country_id
    -- include 1998 so 1999 can lag to it
    WHERE t.calendar_year BETWEEN 1998 AND 2001
      AND co.country_region IN ('Americas', 'Asia', 'Europe')
    GROUP BY
        co.country_region,
        t.calendar_year,
        ch.channel_desc
),
pct AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        amount_sold
          / NULLIF(SUM(amount_sold) OVER (PARTITION BY country_region, calendar_year), 0) AS pct_by_channels
    FROM base
),
final AS (
    SELECT
        country_region,
        calendar_year,
        channel_desc,
        amount_sold,
        pct_by_channels,
        LAG(pct_by_channels) OVER (
            PARTITION BY country_region, channel_desc
            ORDER BY calendar_year
        ) AS pct_previous_period
    FROM pct
)
SELECT
    country_region,
    calendar_year,
    channel_desc,
    amount_sold AS "AMOUNT_SOLD",
    ROUND(pct_by_channels * 100.0, 2) AS "% BY CHANNELS",
    ROUND(pct_previous_period * 100.0, 2) AS "% PREVIOUS PERIOD",
    ROUND((pct_by_channels - pct_previous_period) * 100.0, 2) AS "% DIFF"
FROM final
WHERE calendar_year BETWEEN 1999 AND 2001
ORDER BY
    country_region ASC,
    calendar_year ASC,
    channel_desc ASC;

---Task 2;

WITH daily_sales AS (
  SELECT
        t.calendar_week_number,
        t.time_id::date              AS time_id,
        t.day_name,
        SUM(s.amount_sold)           AS sales
    FROM sh.times t
    JOIN sh.sales s
      ON s.time_id = t.time_id
    WHERE t.calendar_year = 1999
      AND t.calendar_week_number BETWEEN 48 AND 52   
    GROUP BY
        t.calendar_week_number, t.time_id, t.day_name
),
calc AS (
    SELECT
        calendar_week_number,
        time_id,
        day_name,
        sales,
    SUM(sales) OVER (
            PARTITION BY calendar_week_number
            ORDER BY time_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum,

        CASE
            WHEN day_name = 'Monday' THEN
                AVG(sales) OVER (
                    ORDER BY time_id
                    ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING
                )
           
            WHEN day_name = 'Friday' THEN
                AVG(sales) OVER (
                    ORDER BY time_id
                    ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING
                )
           
            ELSE
                AVG(sales) OVER (
                    ORDER BY time_id
                    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
                )
        END AS centered_3_day_avg
    FROM daily_sales
)

SELECT
    calendar_week_number,
    time_id,
    day_name,
    ROUND(sales::numeric, 2)                 AS sales,
    ROUND(cum_sum::numeric, 2)               AS cum_sum,
    ROUND(centered_3_day_avg::numeric, 2)    AS centered_3_day_avg
FROM calc
WHERE calendar_week_number IN (49, 50, 51)
ORDER BY calendar_week_number, time_id;


---Task 3;
---in this query we find a centered 3-row moving average of sales amounts;
---Rolling average based on a fixed number of physical rows
---ROWS function ensuring a fixed number of rows per calculation,
SELECT
    time_id,
    amount_sold,
    ROUND(
        AVG(amount_sold) OVER (
            ORDER BY time_id
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ),
        2
    ) AS centered_3_row_avg
FROM sh.sales
ORDER BY time_id;


---in this query we find a weekly cumulative sum of sales for the year 1999
---RANGE frame includes all rows with the same ORDER BY value
SELECT
    s.time_id,
    t.calendar_week_number,
    SUM(s.amount_sold) OVER (
        PARTITION BY t.calendar_week_number
        ORDER BY s.time_id
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS weekly_cum_sum
FROM sh.sales s
JOIN sh.times t
    ON s.time_id = t.time_id
WHERE t.calendar_year = 1999
ORDER BY t.calendar_week_number, s.time_id;

---in this query we find running sum by week using GROUPS frame
---GROUP frame makes the window move by whole weeks instead of by individual rows (days).
WITH daily_sales AS (
  SELECT
      t.calendar_year,
      t.calendar_week_number,
      t.time_id::date AS sales_date,
      SUM(s.amount_sold) AS sales
  FROM sh.sales s
  JOIN sh.times t ON t.time_id = s.time_id
  GROUP BY t.calendar_year, t.calendar_week_number, t.time_id
)
SELECT
    calendar_year,
    calendar_week_number,
    sales_date,
    sales,
    SUM(sales) OVER (
      PARTITION BY calendar_year
      ORDER BY calendar_week_number
      GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sum_by_week
FROM daily_sales
ORDER BY calendar_year, calendar_week_number, sales_date;

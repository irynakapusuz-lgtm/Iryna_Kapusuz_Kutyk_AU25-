--Task 1.1 A list of animation movies released from 2017 through 2019 with a rate > 1 
-- CTE : + improves readability, executed right before the main query,easy to extend
--         optimal for this task
--       - more verbose than SELECT
WITH animation_films AS (
SELECT f.film_id,
f.title, 
f.release_year,
f.rental_rate,
c.name AS category_name
FROM public.film AS f
INNER JOIN public.film_category AS fc
ON f.film_id = fc.film_id
INNER JOIN public.category AS c
ON c.category_id = fc.category_id
WHERE c.name ='Animation'
)
SELECT 
af.title,
af.release_year,
af.rental_rate
FROM animation_films AS af
WHERE af.release_year BETWEEN 2017 AND 2019
AND af.rental_rate > 1
ORDER BY af.title ASC;

--Subquery :

SELECT f.title,
       f.release_year,
	   f.rental_rate
FROM public.film as f
WHERE f.release_year BETWEEN 2017 AND 2019
AND f.rental_rate > 1
AND EXISTS(
SELECT 1
FROM public.film_category AS fc
INNER JOIN public.category AS c
ON c.category_id = fc.category_id
WHERE fc.film_id = f.film_id
AND c.name ='Animation'
)
ORDER BY f.title ASC;

--JOIN: + easiest and fastest to test for short uncomplicated queries
--      - less readable than CTE
SELECT DISTINCT
 f.title,
 f.release_year,
 f.rental_rate
 FROM public.film AS f
 INNER JOIN public.film_category AS fc
 ON fc.film_id = f.film_id
 INNER JOIN public.category AS c
 ON c.category_id = fc.category_id
 WHERE c.name = 'Animation'
 AND f.release_year BETWEEN 2017 and 2019
 AND f.rental_rate > 1
 ORDER BY f.title ASC;

--1.2 Calculate revenue per each store since April 2017 
-- Business logic: 1.payment-rental-inventory-store-address
--                 2.using revenue as sum of all payment amounts
--                 3. combining addresses using COALESCE
--                 4.payments only after march 2017
-- CTE: + improves readability, executed right before the main query,easy to extend
--       - more verbose than SELECT

WITH store_revenue AS (
SELECT s.store_id,
a.address,
a.address2,
SUM(p.amount) AS revenue
FROM public.payment AS p
INNER JOIN public.rental AS r
ON r.rental_id = p.rental_id
INNER JOIN public.inventory AS i
ON i.inventory_id = r.inventory_id
INNER JOIN public.store AS s
ON s.store_id = i.store_id
INNER JOIN public.address AS a 
ON a.address_id = s.address_id
WHERE p.payment_date >= DATE '2017-04-01'
GROUP BY 
s.store_id,
a.address,
a.address2)
SELECT
sr.address || COALESCE (' '|| sr.address2,'') AS address,
sr.revenue
FROM store_revenue AS sr
ORDER BY sr.revenue DESC;


 --Subquery: + aggregation is made before joining tables

 SELECT
 a.address || COALESCE (' '|| a.address2,'') AS address,
 t.revenue
 FROM public.store AS s
 INNER JOIN public. address as a 
 ON a.address_id = s.address_id
 INNER JOIN (SELECT i.store_id, SUM(p.amount) AS revenue
             FROM public.payment as p
             INNER JOIN public.rental AS r
             ON r.rental_id = p.rental_id
			 INNER JOIN public.inventory as i
			 ON i.inventory_id =r.inventory_id
			 WHERE p.payment_date >= DATE '2017-04-01'
			 GROUP BY i.store_id) as t
 ON t.store_id =s.store_id
 ORDER BY t.revenue DESC;

--JOIN: + easiest and fastest to test for short uncomplicated queries
--        optimal for such task
--      - less readable than CTE

SELECT a.address || COALESCE (' '|| a.address2,'') AS address,
       SUM(p.amount) AS revenue
FROM public.payment as p
INNER JOIN public.rental as r
ON r.rental_id = p.rental_id
INNER JOIN public.inventory as i
ON i.inventory_id = r.inventory_id
INNER JOIN public.store AS s
ON s.store_id = i.store_id
INNER JOIN public.address AS a
ON a.address_id = s.address_id
WHERE p.payment_date >= DATE '2017-04-01'
GROUP BY a.address,
         a.address2
ORDER BY SUM(p.amount) DESC


--1.3 Show top-5 actors by number of movies (released after 2015) 
-- CTE : + improves readability, executed right before the main query,easy to extend
--         optimal for this task
--       - more verbose than SELECT

WITH actor_movie_count AS (
   SELECT a.actor_id,
          a.first_name,
		  a.last_name,
		  COUNT(DISTINCT f.film_id) as number_of_movies
	FROM public.actor AS a 
	INNER JOIN public.film_actor as fa
	ON fa.actor_id = a.actor_id
	INNER JOIN public.film AS f
	ON f.film_id = fa.film_id
	WHERE f.release_year > 2015
	GROUP BY a.actor_id,
	         a.first_name,
			 a.last_name )
	SELECT amc.first_name,
	       amc.last_name,
		   amc.number_of_movies
	FROM actor_movie_count AS amc
	ORDER BY
	       amc.number_of_movies DESC,
	       amc.last_name ASC,
           amc.first_name ASC
	LIMIT 5;

	 --Subquery: + aggregation is made before joining tables
	 --            good for nested aggregations
	 
SELECT a.first_name,
       a.last_name,
	   t.number_of_movies
FROM public.actor AS a
INNER JOIN (
SELECT fa.actor_id, COUNT(DISTINCT f.film_id) AS number_of_movies
FROM public.film_actor AS fa
INNER JOIN public.film AS f
ON f.film_id = fa.film_id
WHERE f.release_year > 2015
GROUP BY fa.actor_id) as t
ON t.actor_id = a.actor_id
ORDER BY 
  t.number_of_movies DESC,
  a.last_name ASC,
  a.first_name ASC
  LIMIT 5;


--JOIN: + easiest and fastest to test for short uncomplicated queries
--        optimal for such task
--      - less readable than CTE

SELECT
a.first_name,
a.last_name,
COUNT(DISTINCT f.film_id) AS number_of_movies
FROM public.actor AS a
INNER JOIN public.film_actor as fa
ON fa.actor_id = a.actor_id
INNER JOIN public.film AS f
ON f.film_id = fa.film_id
WHERE f.release_year > 2015
GROUP BY
a.actor_id,
a.first_name,
a.last_name
ORDER BY
COUNT(DISTINCT f.film_id) DESC,
a.last_name ASC,
a.first_name ASC
LIMIT 5;



--1.4 Count distinctive films per year within each genre 
---- CTE: + improves readability, executed right before the main query,easy to extend if needed
--       - more verbose than SELECT

WITH films_by_genre AS (
 SELECT f.film_id,
        f.release_year,
		c.name AS category_name
 FROM public.film AS f
 INNER JOIN public.film_category AS fc
 ON fc.film_id = f.film_id
 INNER JOIN public.category AS c
 ON c.category_id = fc.category_id
 WHERE c.name IN ('Drama', 'Travel', 'Documentary')
)
SELECT fbg.release_year,
COUNT(DISTINCT CASE WHEN fbg.category_name = 'Drama'
THEN fbg.film_id END) AS number_of_drama_movies,
COUNT(DISTINCT CASE WHEN fbg.category_name = 'Travel'
THEN fbg.film_id END) AS number_of_travel_movies,
COUNT(DISTINCT CASE WHEN fbg.category_name = 'Documentary'
THEN fbg.film_id END) AS number_of_travel_movies
FROM films_by_genre as fbg
GROUP BY 
 fbg.release_year
ORDER BY fbg.release_year DESC;


--Subquery: + aggregation is made before joining tables 
--but unfortunately it makes an output only for few years
-- I work on fixing it

SELECT t.release_year,
COUNT(DISTINCT CASE WHEN t.category_name = 'Drama'
THEN t.film_id END) AS number_of_drama_movies,
COUNT(DISTINCT CASE WHEN t.category_name = 'Travel'
THEN t.film_id END) AS number_of_travel_movies,
COUNT(DISTINCT CASE WHEN t.category_name = 'Documntary'
THEN t.film_id END) AS number_of_travel_movies
FROM (SELECT f.film_id,
             f.release_year,
			 c.name AS category_name
	  FROM public.film AS f
	  INNER JOIN public.film_category AS fc
	  ON fc.film_id = f.film_id
	  INNER JOIN public.category as c
	  ON c.category_id = fc.film_id
	  WHERE c.name IN ('Drama','Travel','Documentary') ) as t
	  GROUP BY t.release_year
	  ORDER BY t.release_year DESC;


--JOIN: + easiest and fastest to test for short uncomplicated queries
--        optimal for such task
--      - less readable than CTE

SELECT f.release_year,
COUNT(DISTINCT CASE WHEN c.name = 'Drama'
THEN f.film_id END) AS number_of_drama_movies,
COUNT(DISTINCT CASE WHEN c.name = 'Travel'
THEN f.film_id END) AS number_of_travel_movies,
COUNT(DISTINCT CASE WHEN c.name = 'Documntary'
THEN f.film_id END) AS number_of_travel_movies
FROM public.film as f
INNER JOIN public.film_category AS fc
ON fc.film_id = f.film_id
INNER JOIN public.category AS c
ON c.category_id = fc.category_id
WHERE c.name IN ('Drama','Travel','Documentary') 
GROUP BY f.release_year
ORDER BY f.release_year DESC;




--Task 2.1 Top 3 best emoloyees in 2017 (by revenue)
--Business Logic: 1.payment date only '2017-01-01' '2018-01-01'
--                2.revenue = sum of customers payments
--                3.revenue 2017 for each staff_id
--                4. from joining payment -rental-inventory find last_store_id
-- CTE: + improves readability, executed right before the main query,easy to extend
--       - more verbose than SELECT


WITH payments_2017 AS (
SELECT p.payment_id,
       p.staff_id,
	   p.amount,
	   p.payment_date,
	   r.inventory_id
FROM public.payment AS p
INNER JOIN public.rental AS r
ON r.rental_id = p.rental_id
WHERE p.payment_date >= DATE '2017-01-01'
AND p.payment_date < DATE '2018-01-01'
),
p2017_with_store AS(
SELECT 
x.payment_id,
x.staff_id,
x.amount,
x.payment_date,
i.store_id
FROM payments_2017 AS x
INNER JOIN public.inventory as i
ON i.inventory_id = x.inventory_id
),
revenue_by_staff AS (
SELECT 
staff_id,
SUM(amount) AS revenue_2017
FROM p2017_with_store
GROUP BY staff_id
),
last_date_per_staff AS (
SELECT staff_id,
       MAX(payment_date) AS last_payment_date
FROM p2017_with_store
GROUP BY staff_id),
last_row_per_staff AS
(SELECT s.staff_id,
        MAX(payment_id) AS last_payment_id
FROM p2017_with_store AS s 
INNER JOIN last_date_per_staff as d
ON d.staff_id = s.staff_id
AND d.last_payment_date = s.payment_date
GROUP BY s.staff_id
),
last_store_per_staff AS (
SELECT 
s.staff_id,
s.store_id as last_store_id
FROM p2017_with_store AS s 
INNER JOIN last_row_per_staff as lr
ON lr.last_payment_id = s.payment_id
)
SELECT
st.first_name,
st.last_name,
lss.last_store_id,
rbs.revenue_2017
FROM public.staff AS st
INNER JOIN  revenue_by_staff AS rbs ON rbs.staff_id = st.staff_id
INNER JOIN last_store_per_staff AS lss ON lss.staff_id = st.staff_id
ORDER BY 
rbs.revenue_2017 DESC,
st.last_name ASC,
st.first_name ASC
LIMIT 3;

--Subquery: 

SELECT
s.first_name,
s.last_name,
ls.last_store_id,
r.revenue_2017
FROM public.staff AS s
INNER JOIN(
SELECT
p.staff_id,
SUM(p.amount) AS revenue_2017
FROM public.payment AS p
WHERE p.payment_date >= DATE '2017-01-01'
AND p.payment_date < DATE '2018-01-01'
GROUP BY p.staff_id
) AS r
ON r.staff_id = s.staff_id
INNER JOIN(
SELECT
base.staff_id,
inv.store_id AS last_store_id
FROM (
SELECT
p2.staff_id,
MAX(p2.payment_id) AS last_payment_id
FROM public.payment AS p2
WHERE p2.payment_date >= DATE '2017-01-01'
AND p2.payment_date < DATE '2018-01-01'
AND p2.payment_date = (
SELECT MAX(pz.payment_date)
FROM public.payment AS pz
WHERE pz.staff_id = p2.staff_id
AND p2.payment_date >= DATE '2017-01-01'
AND p2.payment_date < DATE '2018-01-01'
)
GROUP BY p2.staff_id
 ) AS base
INNER JOIN public.payment AS pl ON pl.payment_id = base.last_payment_id
INNER JOIN public.rental AS rl ON rl.rental_id = pl.staff_id
INNER JOIN public.inventory AS inv ON inv.inventory_id = rl.inventory_id
) as ls
ON ls.staff_id = s.staff_id
ORDER BY 
r.revenue_2017 DESC,
s.last_name ASC,
s.first_name ASC
LIMIT 3;

--JOIN: + optimal for such task
--      - less readable than CTE

SELECT
s.first_name,
s.last_name,
l.last_store_id,
r.revenue_2017
FROM public.staff AS s
INNER JOIN(
SELECT
p.staff_id,
SUM(p.amount) AS revenue_2017
FROM public.payment AS p
WHERE p.payment_date >= DATE '2017-01-01'
AND p.payment_date < DATE '2018-01-01'
GROUP BY p.staff_id
) AS r
ON r.staff_id = s.staff_id
INNER JOIN (
SELECT
pick.staff_id,
inv.store_id AS last_store_id
FROM 
(
SELECT p2.staff_id,
MAX(p2.payment_id) AS last_payment_id
FROM public.payment as p2
WHERE p2.payment_date >= DATE '2017-01-01'
AND p2.payment_date < DATE '2018-01-01'
AND p2.payment_date = (
SELECT MAX(pz.payment_date)
FROM public.payment as pz
WHERE pz.staff_id = p2.staff_id
AND pz.payment_date >= DATE '2017-01-01'
AND pz.payment_date < DATE '2018-01-01'
)
GROUP BY p2.staff_id
)as pick
INNER JOIN public.payment AS pl ON pl.payment_id = pick.last_payment_id
INNER JOIN public.rental AS rl ON rl.rental_id = pl.rental_id
INNER JOIN public.inventory AS inv ON inv.inventory_id = rl.inventory_id
)AS l
ON l.staff_id = s.staff_id
ORDER BY
r.revenue_2017 DESC,
s.last_name ASC,
s.first_name ASC
LIMIT 3;


--Task 2.2 The most popular movies (with the highest number of rentals ) and their target audience
-- Business logic: 1 we make joins film-inventory-rental
--                 2 every rental is associated with correct movie
--                 3 COUNT rental id as number_of_rentals
--                 4 Age group ranking using CASE
-- CTE: + improves readability, executed right before the main query,easy to extend
--       - more verbose than SELECT

WITH rentals_per_film AS (
SELECT f.film_id,
       f.title,
	   f.rating,
	   COUNT(r.rental_id) AS number_of_rentals
	   FROM public.film as f
	   INNER JOIN public.inventory AS i
	   ON i.film_id = f.film_id
	   INNER JOIN public.rental AS r
	   ON r.inventory_id = i.inventory_id
	   GROUP BY
	   f.film_id,
	   f.title,
	   f.rating
)
SELECT rpf.title,
CASE rpf.rating
WHEN 'G' then '0+'
WHEN 'PG' then '8+'
WHEN 'PG-13' then '13+'
WHEN 'R'    then '17+'
WHEN 'NC-17' then '18+'
ElSE 'N/A'
END as expected_age,
rpf.number_of_rentals
FROM rentals_per_film as rpf
ORDER BY
rpf.number_of_rentals DESC,
rpf.title ASC
LIMIT 3;

----Subquery: 

SELECT
m.title,
CASE m.rating
WHEN 'G' then '0+'
WHEN 'PG' then '8+'
WHEN 'PG-13' then '13+'
WHEN 'R'    then '17+'
WHEN 'NC-17' then '18+'
ElSE 'N/A'
END AS expected_age,
m.number_of_rentals
FROM (SELECT f.film_id,
	   f.title,
	   f.rating,
COUNT(r.rental_id) AS number_of_rentals
FROM public.film AS f
INNER JOIN public.inventory AS i
ON i.film_id = f.film_id
INNER JOIN public.rental AS r
ON r.inventory_id = i.inventory_id
GROUP BY f.film_id,
	   f.title,
	   f.rating) AS m
ORDER BY 
m.number_of_rentals DESC,
m.title ASC
LIMIT 5;

--JOIN: + easiest and fastest to test for short uncomplicated queries
--        optimal for such task
--      - less readable than CTE

SELECT
f.title,
CASE f.rating
WHEN 'G' then '0+'
WHEN 'PG' then '8+'
WHEN 'PG-13' then '13+'
WHEN 'R'    then '17+'
WHEN 'NC-17' then '18+'
ElSE 'N/A'
END AS expected_age,
COUNT(r.rental_id) AS number_of_rentals
FROM public.film as f
INNER JOIN public.inventory AS i
ON i.film_id = f.film_id
INNER JOIN public.rental AS r
ON r.inventory_id = i.inventory_id
GROUP BY
	   f.film_id,
	   f.title,
	   f.rating
ORDER BY 
COUNT(r.rental_id) DESC,
    f.title ASC
LIMIT 5;


--Task 3.1 Finding actors with long inactivity periods 
--V1: gap between the latest release_year and current year per each actor;
--Business logic:  1.collecting all films from actor
 --                2.finding each actor latest release 
 --                3.extracting YEAR from current date
 --                4.Finding inactivity years = current_year-latest_release year
--inactive years means EXTRACT(YEAR from current_date)- MAX(f.release_year)
--and also we find latest film release year per each actor

-- CTE: + improves readability, executed right before the main query,easy to extend if needed
--       - more verbose than SELECT

WITH last_release AS (
SELECT a.actor_id,
       a.first_name,
	   a.last_name,
MAX(f.release_year) AS last_release_year
FROM public.actor AS a 
INNER JOIN public.film_actor as fa
ON fa.actor_id = a.actor_id
INNER JOIN public.film AS f
ON f.film_id  = fa.film_id
GROUP BY 
a.actor_id,
a.first_name,
a.last_name
)
SELECT lr.first_name,
lr.last_name,
lr.last_release_year,
EXTRACT(YEAR FROM CURRENT_DATE)::INT-lr.last_release_year AS inactivity_years
FROM last_release as lr
ORDER BY
inactivity_years DESC,
lr.last_name,
lr.first_name


----Subquery: 
SELECT m.first_name,
m.last_name,
m.last_release_year,
EXTRACT(YEAR FROM CURRENT_DATE)::INT-m.last_release_year AS inactivity_years
FROM (
SELECT a.actor_id,
a.first_name,
a.last_name,
MAX(f.release_year) AS last_release_year
FROM public.actor AS a 

INNER JOIN public.film_actor as fa
ON fa.actor_id = a.actor_id
INNER JOIN public.film AS f
ON f.film_id  = fa.film_id
GROUP BY 
a.actor_id,
a.first_name,
a.last_name
) as m
ORDER BY
inactivity_years DESC,
m.last_name,
m.first_name

----JOIN: + easiest and fastest to test for short uncomplicated queries
--        optimal for such task

SELECT a.first_name,
	   a.last_name,
MAX(f.release_year) AS last_release_year,
EXTRACT(YEAR FROM CURRENT_DATE)::INT - MAX(f.release_year) AS inactivity_years
FROM public.actor AS a 
INNER JOIN public.film_actor as fa
ON fa.actor_id = a.actor_id
INNER JOIN public.film AS f
ON f.film_id  = fa.film_id
GROUP BY 
a.actor_id,
a.first_name,
a.last_name
ORDER BY
inactivity_years DESC,
a.last_name,
a.first_name;

--Task 3.2 
--V2: gaps between sequential films per each actor;
--Business logic:  1.collect all films from actor
--                 2.sort each actors movies by year
--                 3.compare each year with their next release year
---                (for each year we will find the next release year)
--                 4.find the largest gap per actor

---- CTE: + improves readability, executed right before the main query,easy to extend if needed
--       - more verbose than SELECT

WITH actor_years AS (
SELECT DISTINCT
a.actor_id,
a.first_name,
a.last_name,
f.release_year
FROM public.actor AS a
INNER JOIN public.film_actor AS fa
ON fa.actor_id = a.actor_id
INNER JOIN public.film as f
ON f.film_id =fa.film_id
),
year_with_next AS (
SELECT ay.actor_id,
ay.first_name,
ay.last_name,
ay.release_year AS current_year,
( SELECT MIN(f2.release_year) 
FROM public.film_actor AS fa2
INNER JOIN public.film AS f2
ON f2.film_id = fa2.film_id
WHERE fa2.actor_id = ay.actor_id
AND f2.release_year > ay.release_year) AS next_year
FROM actor_years AS ay
),
gaps AS (
SELECT ywn.actor_id,
       ywn.first_name,
       ywn.last_name,
	   ywn.current_year,
	   CASE WHEN ywn.next_year IS NOT NULL
	        THEN (ywn.next_year - ywn.current_year)
	  ELSE NUll
	  END AS gap_years
FROM year_with_next AS ywn
)
SELECT g.first_name,
       g.last_name,
	   MAX(g.gap_years) AS longest_seq_gap_years
	   FROM gaps AS g
WHERE g.gap_years IS NOT NULL
GROUP BY g.actor_id,
       g.first_name,
       g.last_name
ORDER BY longest_seq_gap_years DESC,
       g.first_name,
       g.last_name;
	   
 -------Subquery: readability is poor, not good to use 

 SELECT z.first_name,
        z.last_name,
		MAX(z.gap_years) AS longest_seq_gap_years
FROM ( SELECT ay.actor_id,
ay.first_name,
ay.last_name,
ay.release_year AS current_year,
(SELECT MIN(f2.release_year) 
FROM public.film_actor AS fa2
INNER JOIN public.film AS f2
ON f2.film_id = fa2.film_id
WHERE fa2.actor_id = ay.actor_id
AND f2.release_year > ay.release_year) AS next_year,
CASE WHEN (SELECT MIN(f2.release_year) 
FROM public.film_actor AS fa2
INNER JOIN public.film AS f2
ON f2.film_id = fa2.film_id
WHERE fa2.actor_id = ay.actor_id
AND f2.release_year > ay.release_year) IS NOT NULL
THEN (
(SELECT MIN(f2.release_year) 
FROM public.film_actor AS fa2
INNER JOIN public.film AS f2
ON f2.film_id = fa2.film_id
WHERE fa2.actor_id = ay.actor_id
AND f2.release_year > ay.release_year)-ay.release_year
)END AS gap_years
FROM (SELECT DISTINCT 
       a.actor_id,
       a.first_name,
       a.last_name,
	   f.release_year
FROM public.actor as a
INNER JOIN public.film_actor AS fa
ON fa.actor_id = a.actor_id
INNER JOIN public.film as f
ON f.film_id =fa.film_id
) AS ay
) as z 
WHERE z.gap_years IS NOT NULL
GROUP BY z.actor_id,
       z.first_name,
       z.last_name
ORDER BY longest_seq_gap_years DESC,
       z.first_name,
       z.last_name;


----JOIN: + easiest and fastest to test for short uncomplicated queries
--        optimal for such task

SELECT
    t.first_name,
    t.last_name,
    MAX(t.next_year - t.release_year) AS longest_sequential_gap_years
FROM (
    SELECT DISTINCT
        a.actor_id,
        a.first_name,
        a.last_name,
        f.release_year,
        (
            SELECT MIN(f2.release_year)
            FROM public.film_actor AS fa2
            INNER JOIN public.film AS f2
                ON f2.film_id = fa2.film_id
            WHERE fa2.actor_id = a.actor_id
              AND f2.release_year > f.release_year
        ) AS next_year
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa
        ON fa.actor_id = a.actor_id
    INNER JOIN public.film AS f
        ON f.film_id = fa.film_id
) AS t
WHERE t.next_year IS NOT NULL
GROUP BY
    t.actor_id,
    t.first_name,
    t.last_name
ORDER BY
    longest_sequential_gap_years DESC,
    t.last_name ASC,
    t.first_name ASC;

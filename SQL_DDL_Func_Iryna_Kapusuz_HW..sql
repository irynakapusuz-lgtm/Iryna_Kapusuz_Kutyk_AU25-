--Task 1. View (total sales revenue for the current quarter and year)
CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
SELECT 
c.name AS category_name,
EXTRACT (YEAR FROM CURRENT_DATE)::int      AS sales_year,
EXTRACT (QUARTER FROM CURRENT_DATE)::int   AS sales_quarter,
SUM (p.amount) AS total_sales_revenue
FROM payment p
JOIN rental r  ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f  ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE p.payment_date >= DATE_TRUNC('quarter', CURRENT_DATE)
AND p.payment_date < DATE_TRUNC ('quarter', CURRENT_DATE) + INTERVAL '3 months'
GROUP BY c.name
HAVING SUM(p.amount) > 0;

------verification_test;

SELECT *
FROM sales_revenue_by_category_qtr;

--Task 2.Query language function
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
p_ref_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
category_name     TEXT,
sales_year        INTEGER,
sales_quarter     INTEGER,
total_sales_revenue NUMERIC)

LANGUAGE plpgsql
AS $$
BEGIN 
IF p_ref_date IS NULL THEN 
 RAISE EXCEPTION 'p_ref_date cannot be NULL';
 END IF;
IF to_regclass ('public.payment') IS NULL
   OR to_regclass ('public.rental') IS NULL
   OR to_regclass ('public.inventory') IS NULL
   OR to_regclass ('public.film') IS NULL
   OR to_regclass ('public.film_category') IS NULL
   OR to_regclass ('public.category') IS NULL THEN 
   RAISE EXCEPTION 'Required tables are missing in the database';
END IF;

RETURN QUERY 
SELECT c.name AS category_name,
EXTRACT (YEAR FROM p_ref_date)::int      AS sales_year,
EXTRACT (QUARTER FROM p_ref_date)::int   AS sales_quarter,
SUM (p.amount) AS total_sales_revenue
FROM payment p
JOIN rental r  ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f  ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE EXTRACT (YEAR FROM p.payment_date) = 
      EXTRACT (YEAR FROM p_ref_date)
AND EXTRACT(QUARTER FROM p.payment_date)=
    EXTRACT(QUARTER FROM p_ref_date) 
GROUP BY c.name
HAVING SUM(p.amount) > 0;
END;
$$;

------verification_test;
SELECT *
FROM get_sales_revenue_by_category_qtr();

--- Conclusion: after 2 tasks query returns 0 rows. 
--- We dont have payments ın currrent quarter in database;


----Task 3. Function 'most_popular_films_by_countries'

CREATE OR REPLACE FUNCTION core.most_popular_films_by_countries(
    p_countries TEXT[])
RETURNS TABLE (
country_name   TEXT,
film_title     TEXT,
rating         TEXT,
language_name  TEXT,
length         INTEGER,
release_year   INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    
IF p_countries IS NULL OR array_length(p_countries, 1) IS NULL THEN
RAISE EXCEPTION 'Provide at least one country name';
END IF;
IF to_regclass('public.country')   IS NULL OR
to_regclass('public.city')      IS NULL OR
to_regclass('public.address')   IS NULL OR
to_regclass('public.customer')  IS NULL OR
to_regclass('public.rental')    IS NULL OR
to_regclass('public.inventory') IS NULL OR
to_regclass('public.film')      IS NULL OR
to_regclass('public.language')  IS NULL THEN
RAISE EXCEPTION 'Required tables are missing in the database';
END IF;
RETURN QUERY
WITH rentals_per_film AS (
SELECT
co.country       AS ctry_name,
f.title          AS film_title,
f.rating::text   AS rating,
l.name::text     AS language_name,
f.length::int    AS length,
f.release_year::int AS release_year,   
COUNT(r.rental_id) AS rental_count
FROM country co
JOIN city ci        ON co.country_id = ci.country_id
JOIN address ad     ON ci.city_id = ad.city_id
JOIN customer cu    ON ad.address_id = cu.address_id
JOIN rental r       ON cu.customer_id = r.customer_id
JOIN inventory i    ON r.inventory_id = i.inventory_id
JOIN film f         ON i.film_id = f.film_id
JOIN language l     ON f.language_id = l.language_id
WHERE co.country = ANY(p_countries)
GROUP BY
co.country, f.title, f.rating, l.name, f.length, f.release_year),
max_count AS (
SELECT
ctry_name,
MAX(rental_count) AS max_rentals
FROM rentals_per_film
GROUP BY ctry_name)
SELECT
rpf.ctry_name    AS country_name,
rpf.film_title,
rpf.rating, 
rpf.language_name,
rpf.length,
rpf.release_year   
FROM rentals_per_film rpf
JOIN max_count mc
ON rpf.ctry_name = mc.ctry_name
AND rpf.rental_count = mc.max_rentals
ORDER BY rpf.ctry_name;
END;
$$;
 
 ------verification_test;
SELECT *
FROM core.most_popular_films_by_countries(
 ARRAY['Afghanistan','Brazil','United States']
);


----Task 4.Films_in_stock_by_title('%love%’);

CREATE OR REPLACE FUNCTION films_in_stock_by_title(
    p_partial_title TEXT)
RETURNS TABLE (
row_num       INT,
film_title    TEXT,
language_name TEXT,
customer_name TEXT,
rental_date   TIMESTAMP)
LANGUAGE sql
AS $$
WITH in_stock AS (
SELECT DISTINCT
f.title AS film_title,
l.name  AS language_name
FROM film f
JOIN language l  ON f.language_id = l.language_id
JOIN inventory i ON f.film_id = i.film_id
WHERE f.title ILIKE p_partial_title
AND inventory_in_stock(i.inventory_id)
 )
SELECT
ROW_NUMBER() OVER (ORDER BY film_title) AS row_num,
film_title,
language_name,
NULL::TEXT,
NULL::TIMESTAMP
FROM in_stock
UNION ALL
SELECT
 1,
 'No films in stock matching: ' || p_partial_title,
 NULL, NULL, NULL
 WHERE NOT EXISTS (SELECT 1 FROM in_stock);
$$;

-----verification_test:
SELECT *
FROM films_in_stock_by_title('%love%');


------Task 5;

CREATE OR REPLACE FUNCTION new_movie(
p_title TEXT,
p_release_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::int,
p_language_name TEXT DEFAULT 'Klingon')
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
v_language_id INTEGER;
v_new_film_id INTEGER;
BEGIN
IF p_title IS NULL OR TRIM(p_title) = '' THEN
RAISE EXCEPTION 'Movie title cannot be empty.';
END IF;
IF to_regclass('public.film') IS NULL THEN
RAISE EXCEPTION 'Table film does not exist.';
END IF;
IF to_regclass('public.language') IS NULL THEN
RAISE EXCEPTION 'Table language does not exist.';
END IF;
SELECT language_id
INTO v_language_id
FROM language
WHERE name = p_language_name;
IF v_language_id IS NULL THEN
RAISE EXCEPTION 'Language "%" not found in language table.', p_language_name;
END IF;
IF EXISTS (
SELECT 1
FROM film
WHERE title = p_title
AND release_year = p_release_year) THEN
RAISE EXCEPTION 'Movie "%" already exists for year %.', p_title, p_release_year;
END IF;
SELECT COALESCE(MAX(film_id), 0) + 1
INTO v_new_film_id
FROM film;
INSERT INTO film (
film_id, title, release_year, language_id,
rental_duration, rental_rate, replacement_cost)
VALUES (v_new_film_id, p_title, p_release_year, v_language_id,
3, 4.99, 19.99 );
RETURN 'Movie added! ID=' || v_new_film_id || ', Title="' || p_title || '"';
END;
$$;

 ------verification_test;
SELECT * FROM language;

----as Klingon language doesnt exists we can add it 

INSERT INTO language (name) VALUES ('Klingon');
SELECT * FROM language;




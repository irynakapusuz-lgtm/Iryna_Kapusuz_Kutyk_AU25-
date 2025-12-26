---Task 2. Query language function
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(qtr TEXT)
RETURNS TABLE (
    category_name TEXT,
    total_sales_revenue NUMERIC
)
LANGUAGE sql
AS $$
    SELECT c.name AS category_name,
           SUM(p.amount) AS total_sales_revenue
    FROM payment p
    JOIN rental r       ON p.rental_id = r.rental_id
    JOIN inventory i    ON r.inventory_id = i.inventory_id
    JOIN film f         ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c       ON fc.category_id = c.category_id
    WHERE to_char(p.payment_date, 'YYYY-"Q"Q') = qtr
    GROUP BY c.name
    ORDER BY c.name;
$$;

SELECT * FROM get_sales_revenue_by_category_qtr('2005-Q2');
--Returns 0 rows. We dont have payments in currrent quarter in database;
SELECT * 
FROM get_sales_revenue_by_category_qtr('2017-Q2');
---Returns output with rows;



---3.Function 'most_popular_films_by_countries'

CREATE SCHEMA IF NOT EXISTS core;
DROP FUNCTION IF EXISTS core.most_popular_films_by_countries(text[]);

CREATE OR REPLACE FUNCTION core.most_popular_films_by_countries(p_countries text[])
RETURNS TABLE (
    country_name  TEXT,
    film_title    TEXT,
    rating        TEXT,
    language_name TEXT,
    length        INTEGER,
    release_year  INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_countries_lower TEXT[];
    v_invalid_list    TEXT;
BEGIN
    --  Require at least one country
    IF p_countries IS NULL OR array_length(p_countries, 1) IS NULL THEN
        RAISE EXCEPTION 'Provide at least one country name';
    END IF;

    --  Converting all country names to lowercase
    v_countries_lower := ARRAY(
        SELECT lower(trim(c))
        FROM unnest(p_countries) AS c
    );

    --  RAISE NOTICE for invalid countries (not existing in table)
    SELECT string_agg(in_c, ', ')
    INTO v_invalid_list
    FROM (
        SELECT DISTINCT in_c
        FROM unnest(v_countries_lower) AS in_c
        LEFT JOIN public.country co
               ON lower(co.country) = in_c
        WHERE co.country_id IS NULL
    ) s;

    IF v_invalid_list IS NOT NULL THEN
        RAISE NOTICE
            'Specified countries do not exist in the database: %',
            v_invalid_list;
    END IF;

    -- Checking for the most popular films per country
    RETURN QUERY
    WITH film_rentals AS (
        SELECT
            co.country             AS country_name,
            f.title                AS film_title,
            f.rating::text         AS rating,
            l.name::text           AS language_name,
            f.length::int          AS length,
            f.release_year::int    AS release_year,
            COUNT(r.rental_id)     AS rental_count
        FROM public.country   co
        JOIN public.city      ci ON ci.country_id  = co.country_id
        JOIN public.address   ad ON ad.city_id     = ci.city_id
        JOIN public.customer  cu ON cu.address_id  = ad.address_id
        JOIN public.rental    r  ON r.customer_id  = cu.customer_id
        JOIN public.inventory i  ON i.inventory_id = r.inventory_id
        JOIN public.film      f  ON f.film_id      = i.film_id
        JOIN public.language  l  ON l.language_id  = f.language_id
        WHERE lower(co.country) = ANY (v_countries_lower)
        GROUP BY
            co.country,
            f.title,
            f.rating,
            l.name,
            f.length,
            f.release_year
    )
    SELECT DISTINCT ON (fr.country_name)
        fr.country_name,
        fr.film_title,
        fr.rating,
        fr.language_name,
        fr.length,
        fr.release_year
    FROM film_rentals AS fr
    ORDER BY
        fr.country_name,
        fr.rental_count DESC,   
        fr.film_title;         

END;
$$;

---verification_test;

SELECT *
FROM core.most_popular_films_by_countries(
    ARRAY['Afghanistan','Brazil','United States']
);


---5. Creating function Films_in_stock_by_title('%love%')
CREATE SCHEMA IF NOT EXISTS core;

CREATE OR REPLACE FUNCTION core.films_in_stock_by_title(
    p_partial_title TEXT
)
RETURNS TABLE (
    row_num       INT,
    film_title    TEXT,
    language_name TEXT,
    customer_name TEXT,
    rental_date   TIMESTAMP
)
LANGUAGE sql
AS $$
----- finding last rental date (across all inventories) for each film
WITH last_rental AS (
   
   SELECT
        f.film_id,
        MAX(r.rental_date) AS last_rental_date
    FROM film f
    JOIN inventory i ON i.film_id = f.film_id
    JOIN rental r   ON r.inventory_id = i.inventory_id
    GROUP BY f.film_id
),
in_stock AS (
    -- films that match the title pattern and are currently in stock
    SELECT DISTINCT
        f.title AS film_title,
        l.name  AS language_name,
        cu.first_name || ' ' || cu.last_name AS customer_name,
        lr.last_rental_date AS rental_date
    FROM film f
    JOIN language l ON l.language_id = f.language_id
    JOIN inventory i ON i.film_id = f.film_id
    JOIN last_rental lr ON lr.film_id = f.film_id
    LEFT JOIN rental r ON r.inventory_id = i.inventory_id
                      AND r.rental_date = lr.last_rental_date
    LEFT JOIN customer cu ON cu.customer_id = r.customer_id
    WHERE f.title ILIKE p_partial_title  
	--I used ILIKE instead of LIKE because ILIKE performs a case insensitive match
	--but it still matches the verification query.
      AND inventory_in_stock(i.inventory_id)  
)
SELECT
    -- generating row numbers starting from 100
    (
        SELECT 99 + COUNT(*)
        FROM in_stock s2
        WHERE s2.film_title <= s1.film_title
    ) AS row_num,
    s1.film_title,
    s1.language_name,
    s1.customer_name,
    s1.rental_date
FROM in_stock s1
ORDER BY s1.film_title;
$$;

SELECT *
FROM core.films_in_stock_by_title('%love%');


-- Task 5: Creating new_movie function.
CREATE SCHEMA IF NOT EXISTS core;

-- Adding Klingon as default language 
---I fixed prevous misatke - function will always fail
---until new language is added.
INSERT INTO public.language (name)
VALUES ('Klingon');

SELECT *
FROM language;

CREATE OR REPLACE FUNCTION core.new_movie(
    p_title         TEXT,
    p_release_year  INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    p_language_name TEXT    DEFAULT 'Klingon'
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_language_id INTEGER;
    v_new_film_id INTEGER;
BEGIN
    --  Ensuring title is empty.
    IF p_title IS NULL OR trim(p_title) = '' THEN
        RAISE EXCEPTION 'Movie title cannot be empty.';
    END IF;

    -- Ensuring language exists.
    SELECT l.language_id
    INTO v_language_id
    FROM public.language AS l
    WHERE l.name = p_language_name;

    IF v_language_id IS NULL THEN
        RAISE EXCEPTION 'Language "%" does not exist in table language.', p_language_name;
    END IF;

   
    IF EXISTS (
        SELECT 1
        FROM public.film f
        WHERE f.title = p_title
          AND f.release_year = p_release_year
    ) THEN
        RAISE EXCEPTION 'Movie "%" for year % already exists.', p_title, p_release_year;
    END IF;

    -- Generating new unique film_id
    SELECT COALESCE(MAX(film_id), 0) + 1
    INTO v_new_film_id
    FROM public.film;

    -- Inserting the new movie with fixed defaults
    INSERT INTO public.film (
        film_id,
        title,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        replacement_cost
    )
    VALUES (
        v_new_film_id,
        p_title,
        p_release_year,
        v_language_id,
        3,       -- rental_duration (days)
        4.99,    -- rental_rate
        19.99    -- replacement_cost
    );

    RETURN
        'Movie added! id=' || v_new_film_id ||
        ', title="' || p_title ||
        '", year=' || p_release_year ||
        ', language="' || p_language_name || '"';
END;
$$;


--- verification check:

SELECT * FROM language;
SELECT core.new_movie('Klingon Adventure');          -- uses defaults
SELECT core.new_movie('Romantic Film', 2005, 'English'); ---shows that film already exists;



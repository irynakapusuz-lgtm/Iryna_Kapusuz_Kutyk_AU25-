---TASK 1 Adding 3 movies into public.film
BEGIN;

WITH film_src AS (
  SELECT 'Sully' AS title, 2016 AS release_year,
         'English' AS language_name, NULL::text AS original_language_name,
         'Captain Chesley “Sully” Sullenberger lands Flight 1549 on the Hudson.' AS description,
         21::smallint AS rental_duration, 19.99::numeric AS rental_rate, 96 AS length,
         24.99::numeric AS replacement_cost, 'PG-13'::mpaa_rating AS rating,
         ARRAY['Trailers','Behind the Scenes']::text[] AS special_features
  UNION ALL
  SELECT 'Home Alone', 1990, 'English', NULL::text,
         'A boy home alone defends his house from two persistent burglars.',
         7,
		 4.99, 103, 19.99, 'PG',
         ARRAY['Trailers','Deleted Scenes']
  UNION ALL
  SELECT 'The Notebook', 2004, 'English', NULL::text,
         'A 1940s romance tested by class, circumstance, and memory.',
         14, 9.99, 123, 19.99, 'PG-13',
         ARRAY['Trailers','Commentaries']
),
resolved AS (
  SELECT fs.*, l.language_id, ol.language_id AS original_language_id
  FROM film_src fs
  JOIN public.language l ON l.name = fs.language_name
  LEFT JOIN public.language ol ON ol.name = fs.original_language_name
)
INSERT INTO public.film (
  title, description, release_year,
  language_id, original_language_id,
  rental_duration, rental_rate, length,
  replacement_cost, rating, special_features, last_update
)
SELECT r.title, r.description, r.release_year,
  r.language_id, r.original_language_id,
  r.rental_duration, r.rental_rate, r.length,
  r.replacement_cost, r.rating, r.special_features, current_date
FROM resolved r
WHERE NOT EXISTS (
  SELECT 1 FROM public.film f
  WHERE f.title = r.title
   AND f.release_year = r.release_year
   AND f.language_id = r.language_id
)
RETURNING film_id, title, release_year, language_id, last_update;

COMMIT;

---Checking favorite films they are present
SELECT film_id, title, release_year, language_id,
       rental_rate, rental_duration, last_update
FROM public.film
WHERE (title, release_year) IN (
  ('Sully', 2016), ('Home Alone', 1990), ('The Notebook', 2004)
)
ORDER BY title;


---TASK 2 Adding real actors into public.actor

BEGIN;

WITH actor_src AS (
  SELECT 'Macaulay' AS first_name, 'Culkin'  AS last_name
  UNION ALL SELECT 'Joe',       'Pesci'
  UNION ALL SELECT 'Daniel',    'Stern'
  UNION ALL SELECT 'Catherine', 'O''Hara'
  UNION ALL SELECT 'Ryan',      'Gosling'
  UNION ALL SELECT 'Rachel',    'McAdams'
  UNION ALL SELECT 'Tom',       'Hanks'
  UNION ALL SELECT 'Aaron',     'Eckhart'
  UNION ALL SELECT 'Laura',     'Linney'
),
to_insert AS (
  SELECT s.*
  FROM actor_src s
  WHERE NOT EXISTS (
    SELECT 1 FROM public.actor a
    WHERE a.first_name = s.first_name
      AND a.last_name  = s.last_name
  )
)
INSERT INTO public.actor (first_name, last_name, last_update)
SELECT ti.first_name, ti.last_name, current_date
FROM to_insert ti
RETURNING actor_id, first_name, last_name, last_update;

COMMIT;


--- Checking actors if they are present:
SELECT first_name, last_name
FROM public.actor
WHERE (first_name, last_name) IN (
  ('Macaulay','Culkin'), ('Joe','Pesci'), ('Daniel','Stern'), ('Catherine','O''Hara'),
  ('Ryan','Gosling'), ('Rachel','McAdams'),
  ('Tom','Hanks'), ('Aaron','Eckhart'), ('Laura','Linney')
)
ORDER BY last_name, first_name;

-- Checking if 3 films exist and their id;
SELECT film_id, title, release_year, language_id
FROM public.film
WHERE (title, release_year) IN (('Sully',2016),('Home Alone',1990),('The Notebook',2004))
ORDER BY title;


----Checking rental_prices and weeks;
SELECT title, release_year, rental_rate, rental_duration
FROM public.film
WHERE (title, release_year) IN (('Home Alone',1990),('The Notebook',2004),('Sully',2016))
ORDER BY title;



WITH actor_src AS (
  SELECT 'Macaulay' AS first_name, 'Culkin'  AS last_name
  UNION ALL SELECT 'Joe','Pesci'
  UNION ALL SELECT 'Daniel','Stern'
  UNION ALL SELECT 'Catherine','O''Hara'
  UNION ALL SELECT 'Ryan','Gosling'
  UNION ALL SELECT 'Rachel','McAdams'
  UNION ALL SELECT 'Tom','Hanks'
  UNION ALL SELECT 'Aaron','Eckhart'
  UNION ALL SELECT 'Laura','Linney'
)
SELECT COUNT(*) AS actors_to_insert
FROM actor_src s
WHERE NOT EXISTS (
  SELECT 1 FROM public.actor a
  WHERE a.first_name = s.first_name AND a.last_name = s.last_name
);


BEGIN;

WITH films AS (
  SELECT 'Home Alone' AS title, 1990 AS release_year, 'English' AS language_name
  UNION ALL SELECT 'The Notebook', 2004, 'English'
  UNION ALL SELECT 'Sully',        2016, 'English'
),
resolved_films AS (
  SELECT f.title, f.release_year, l.language_id, pf.film_id
  FROM films f
  JOIN public.language l ON l.name = f.language_name
  JOIN public.film pf
    ON pf.title = f.title
   AND pf.release_year = f.release_year
   AND pf.language_id = l.language_id
),
cast_map AS (
  SELECT 'Home Alone'::text AS title, 1990::int AS release_year, 'Macaulay'::text AS first_name, 'Culkin'::text AS last_name
  UNION ALL SELECT 'Home Alone',1990,'Joe','Pesci'
  UNION ALL SELECT 'Home Alone',1990,'Daniel','Stern'
  UNION ALL SELECT 'Home Alone',1990,'Catherine','O''Hara'
  UNION ALL SELECT 'The Notebook',2004,'Ryan','Gosling'
  UNION ALL SELECT 'The Notebook',2004,'Rachel','McAdams'
  UNION ALL SELECT 'Sully',2016,'Tom','Hanks'
  UNION ALL SELECT 'Sully',2016,'Aaron','Eckhart'
  UNION ALL SELECT 'Sully',2016,'Laura','Linney'
),
link_rows AS (
  SELECT rf.film_id, a.actor_id
  FROM cast_map cm
  JOIN resolved_films rf
    ON rf.title = cm.title
   AND rf.release_year = cm.release_year
  JOIN public.actor a
    ON a.first_name = cm.first_name
   AND a.last_name  = cm.last_name
),
to_link AS (
  SELECT lr.*
  FROM link_rows lr
  WHERE NOT EXISTS (
    SELECT 1 FROM public.film_actor fa
    WHERE fa.film_id = lr.film_id
      AND fa.actor_id = lr.actor_id
  )
)
INSERT INTO public.film_actor (actor_id, film_id, last_update)
SELECT actor_id, film_id, current_date
FROM to_link
RETURNING actor_id, film_id, last_update;

COMMIT;

SELECT f.title, f.release_year, a.first_name, a.last_name
FROM public.film_actor fa
JOIN public.film  f ON f.film_id  = fa.film_id
JOIN public.actor a ON a.actor_id = fa.actor_id
WHERE (f.title, f.release_year) IN (('Sully',2016),('Home Alone',1990),('The Notebook',2004))
ORDER BY f.title, a.last_name, a.first_name;



---TASK 3. Add your favorite movies to store's inventory.
BEGIN;

WITH favorite_films AS (
    SELECT film_id, title
    FROM public.film
    WHERE title IN ('Home Alone', 'Sully', 'The Notebook')
),
stores AS (
    SELECT store_id
    FROM public.store
),
missing AS (
    -- All (film, store) combos that are missing in inventory.
    SELECT ff.film_id, s.store_id
    FROM favorite_films ff
    CROSS JOIN stores s
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.inventory i
        WHERE i.film_id = ff.film_id
          AND i.store_id = s.store_id
    )
)
INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT film_id, store_id, current_date
FROM missing
RETURNING *;

COMMIT;

-- inventory check
SELECT f.title, i.store_id, COUNT(*) AS copies
FROM public.inventory i
JOIN public.film f ON i.film_id = f.film_id
WHERE f.title IN ('Home Alone', 'Sully', 'The Notebook')
GROUP BY f.title, i.store_id
ORDER BY f.title, i.store_id;
 

---TASK 4. Updating one existing heavy customer into İryna Kapusuz

BEGIN;

WITH target_address AS (
    SELECT address_id
    FROM public.address a
    JOIN public.city ci    ON a.city_id = ci.city_id
    JOIN public.country co ON ci.country_id = co.country_id
    WHERE a.address = 'Tasıoncasi str, blok T4, ap 51'
      AND ci.city   = 'Istanbul'
      AND co.country = 'Türkiye'
),
qualified_customers AS (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.rental r  ON c.customer_id = r.customer_id
    JOIN public.payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
),
chosen_customer AS (
    SELECT c.customer_id
    FROM public.customer c
    JOIN target_address ta ON c.address_id = ta.address_id
    WHERE c.first_name = 'İryna'
      AND c.last_name  = 'Kapusuz'
    UNION ALL
    SELECT MIN(q.customer_id)
    FROM qualified_customers q
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.customer c2
        JOIN target_address ta2 ON c2.address_id = ta2.address_id
        WHERE c2.first_name = 'İryna'
          AND c2.last_name  = 'Kapusuz'
    )
),
upd AS (
    UPDATE public.customer cu
    SET first_name  = 'İryna',
        last_name   = 'Kapusuz',
        email       = 'iryna.kapusuz@gmail.com',
        address_id  = (SELECT address_id FROM target_address),
        last_update = current_date
    FROM chosen_customer cc
    WHERE cu.customer_id = cc.customer_id
    RETURNING cu.*
)
SELECT * FROM upd;

COMMIT;


--- checking if Iryna are present and my details exists;
SELECT a.address_id,
       a.address,
       a.district,
       a.postal_code,
       a.phone,
       ci.city,
       co.country,
       a.last_update
FROM public.address a
JOIN public.city ci    ON a.city_id = ci.city_id
JOIN public.country co ON ci.country_id = co.country_id
WHERE a.address = 'Tasıoncasi str, blok T4, ap 51'
  AND ci.city = 'Istanbul'
  AND co.country = 'Türkiye';

---checking my personal data
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       c.email,
       a.address,
       ci.city,
       co.country,
       c.last_update
FROM public.customer c
JOIN public.address a ON c.address_id = a.address_id
JOIN public.city ci   ON a.city_id = ci.city_id
JOIN public.country co ON ci.country_id = co.country_id
WHERE c.first_name = 'İryna'
  AND c.last_name  = 'Kapusuz'
  AND a.address    = 'Tasıoncasi str, blok T4, ap 51'
  AND ci.city      = 'Istanbul'
  AND co.country   = 'Türkiye';




--- TASK 6 Removing my personal customer records from all tables (except 'Customer' and 'Inventory')
BEGIN;

WITH iryna_customer AS (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.address a  ON c.address_id = a.address_id
    JOIN public.city ci    ON a.city_id    = ci.city_id
    JOIN public.country co ON ci.country_id = co.country_id
    WHERE c.first_name = 'İryna'
      AND c.last_name  = 'Kapusuz'
      AND a.address    = 'Tasıoncasi str, blok T4, ap 51'
      AND ci.city      = 'Istanbul'
      AND co.country   = 'Türkiye'
),
deleted_payments AS (
    DELETE FROM public.payment p
    WHERE EXISTS (
        SELECT 1
        FROM iryna_customer ic
        WHERE ic.customer_id = p.customer_id
    )
    RETURNING p.payment_id
),
deleted_rentals AS (
    DELETE FROM public.rental r
    WHERE EXISTS (
        SELECT 1
        FROM iryna_customer ic
        WHERE ic.customer_id = r.customer_id
    )
    RETURNING r.rental_id
)
SELECT 'payments_deleted' AS what, COUNT(*) AS cnt FROM deleted_payments
UNION ALL
SELECT 'rentals_deleted', COUNT(*) FROM deleted_rentals;

COMMIT;


-- checking taht there are no remaining rentals for me
WITH iryna_customer AS (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.address a ON c.address_id = a.address_id
    JOIN public.city ci   ON a.city_id = ci.city_id
    JOIN public.country co ON ci.country_id = co.country_id
    WHERE c.first_name = 'İryna'
      AND c.last_name  = 'Kapusuz'
      AND a.address    = 'Tasıoncasi str, blok T4, ap 51'
      AND ci.city      = 'Istanbul'
      AND co.country   = 'Türkiye'
)
SELECT COUNT(*) AS remaining_rentals_for_iryna
FROM public.rental r
WHERE EXISTS (
    SELECT 1
    FROM iryna_customer ic
    WHERE ic.customer_id = r.customer_id
);



--     Ensure no payments remain for me
SELECT COUNT(*) AS remaining_payments_for_iryna
FROM public.payment p
WHERE EXISTS (
    SELECT 1
    FROM public.customer c
    JOIN public.address a ON c.address_id = a.address_id
    JOIN public.city ci   ON a.city_id   = ci.city_id
    JOIN public.country co ON ci.country_id = co.country_id
    WHERE c.customer_id = p.customer_id
      AND c.first_name = 'İryna'
      AND c.last_name  = 'Kapusuz'
      AND a.address    = 'Tasıoncasi str, blok T4, ap 51'
      AND ci.city      = 'Istanbul'
      AND co.country   = 'Türkiye'
);



--- TASK 7. Creating rentals for favorite films
BEGIN;

WITH iryna AS (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.address a ON c.address_id = a.address_id
    WHERE c.first_name = 'İryna'
      AND c.last_name  = 'Kapusuz'
      AND a.address    = 'Tasıoncasi str, blok T4, ap 51'
),
favorite_films AS (
    SELECT film_id, title, rental_rate
    FROM public.film
    WHERE title IN ('Home Alone', 'Sully', 'The Notebook')
),
inventory_per_film AS (
  
    SELECT DISTINCT ON (ff.film_id)
           ff.film_id,
           i.inventory_id,
           i.store_id
    FROM favorite_films ff
    JOIN public.inventory i ON i.film_id = ff.film_id
    ORDER BY ff.film_id, i.inventory_id
),
staff_per_store AS (
   
    SELECT DISTINCT ON (s.store_id)
           s.store_id,
           s.staff_id
    FROM public.staff s
    ORDER BY s.store_id, s.staff_id
),
rental_plan AS (
   
    SELECT
        CURRENT_DATE - INTERVAL '10 days' AS rental_date,
        ipf.inventory_id,
        ir.customer_id,
        CURRENT_DATE - INTERVAL '5 days' AS return_date,
        sps.staff_id
    FROM inventory_per_film ipf
    JOIN staff_per_store sps ON ipf.store_id = sps.store_id
    JOIN iryna ir ON TRUE
)
INSERT INTO public.rental (
    rental_date, inventory_id, customer_id,
    return_date, staff_id, last_update
)
SELECT
    rp.rental_date,
    rp.inventory_id,
    rp.customer_id,
    rp.return_date,
    rp.staff_id,
    CURRENT_DATE
FROM rental_plan rp
WHERE NOT EXISTS (
    
    SELECT 1
    FROM public.rental r
    WHERE r.inventory_id = rp.inventory_id
      AND r.customer_id  = rp.customer_id
      AND r.return_date  = rp.return_date
)
RETURNING *;
COMMIT;

--  Insert payments for those rentals  first half of 2017.
BEGIN;

WITH iryna AS (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.address a ON c.address_id = a.address_id
    WHERE c.first_name = 'İryna'
      AND c.last_name  = 'Kapusuz'
      AND a.address    = 'Tasıoncasi str, blok T4, ap 51'
),
favorite_rentals AS (
    SELECT
        r.rental_id,
        r.customer_id,
        r.inventory_id,
        f.title,
        f.rental_rate
    FROM public.rental r
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    JOIN public.film f      ON i.film_id = f.film_id
    JOIN iryna ir           ON r.customer_id = ir.customer_id
    WHERE f.title IN ('Home Alone', 'Sully', 'The Notebook')
),
store_staff AS (
    SELECT DISTINCT ON (s.store_id)
           s.store_id,
           s.staff_id
    FROM public.staff s
    ORDER BY s.store_id, s.staff_id
),
payment_plan AS (
    
    SELECT
        fr.customer_id,
        ss.staff_id,
        fr.rental_id,
        fr.rental_rate AS amount,
        CASE
            WHEN fr.title = 'Home Alone'   THEN TIMESTAMP '2017-01-16 09:00:00'
            WHEN fr.title = 'Sully'        THEN TIMESTAMP '2017-02-21 09:00:00'
            WHEN fr.title = 'The Notebook' THEN TIMESTAMP '2017-03-26 09:00:00'
        END AS payment_date
    FROM favorite_rentals fr
    JOIN public.inventory i ON fr.inventory_id = i.inventory_id
    JOIN store_staff ss     ON i.store_id = ss.store_id
)
INSERT INTO public.payment (
    customer_id, staff_id, rental_id,
    amount, payment_date
)
SELECT
    pp.customer_id,
    pp.staff_id,
    pp.rental_id,
    pp.amount,
    pp.payment_date
FROM payment_plan pp
WHERE
    pp.payment_date BETWEEN DATE '2017-01-01' AND DATE '2017-06-30'
    AND NOT EXISTS (
        SELECT 1
        FROM public.payment p
        WHERE p.customer_id  = pp.customer_id
          AND p.rental_id    = pp.rental_id
          AND p.amount       = pp.amount
          AND p.payment_date = pp.payment_date
    )
RETURNING *;

COMMIT;



--- checking that I rented films;
SELECT
    c.first_name,
    c.last_name,
    f.title,
    r.rental_date,
    r.return_date,
    p.amount,
    p.payment_date
FROM public.customer c
JOIN public.rental r    ON c.customer_id = r.customer_id
JOIN public.payment p   ON r.rental_id = p.rental_id
JOIN public.inventory i ON r.inventory_id = i.inventory_id
JOIN public.film f      ON i.film_id = f.film_id
WHERE c.first_name = 'İryna'
  AND c.last_name  = 'Kapusuz'
  AND f.title IN ('Home Alone', 'Sully', 'The Notebook')
ORDER BY f.title, p.payment_date;
 
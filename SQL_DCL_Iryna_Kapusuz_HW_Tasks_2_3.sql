---Task 2.
---1. Creating user and group role and allowing rentaluser to connect my database
CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';
CREATE ROLE rental;
GRANT CONNECT ON DATABASE dvdrental1 TO rentaluser;
---2. Grant Select 
GRANT SELECT ON TABLE public.customer TO rentaluser;
-- 3. Adding rentaluser to group rental
RESET ROLE;
SELECT current_user, session_user;
GRANT rental TO rentaluser;
---check:
SET ROLE rentaluser;
SELECT * FROM public.customer;
RESET ROLE;

---4.Granting 'rental' group INSERT and UPDATE permissions for the 'rental' table
GRANT INSERT, UPDATE ON TABLE public.rental TO rental;
GRANT USAGE, SELECT ON SEQUENCE public.rental_rental_id_seq TO rental;
SET ROLE rentaluser;

INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES ('2025-02-10', 1, 1, '2025-02-13', 1)
RETURNING rental_id;

UPDATE public.rental
SET return_date = '2025-02-15'
WHERE rental_id = (SELECT MAX(rental_id) FROM public.rental);
RESET ROLE;
---5.Revoke Insert
REVOKE INSERT ON TABLE public.rental FROM rental;
SET ROLE rentaluser;
INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NOW(), 1);

RESET ROLE;
---shows error as per task.



---6.Create a personalized role for any customer already existing in the dvd_rental database.
---finding customer 
SELECT 
    customer_id,
    first_name,
    last_name
FROM customer c
WHERE customer_id IN (SELECT customer_id FROM rental)
  AND customer_id IN (SELECT customer_id FROM payment)
ORDER BY customer_id
LIMIT 1;

---creating role for customer
CREATE ROLE client_patricia_johnson
    LOGIN
    PASSWORD 'patricia777';
---checking:
SELECT customer_id, first_name, last_name
FROM customer
WHERE first_name = 'PATRICIA' AND last_name = 'JOHNSON';

---Task 3. 
---Implementing row-level security
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

CREATE POLICY rental_client_policy
ON rental
FOR SELECT
TO client_patricia_johnson
USING (customer_id = 2); 

CREATE POLICY payment_client_policy
ON payment
FOR SELECT
TO client_patricia_johnson
USING (customer_id = 2); 

SET ROLE client_patricia_johnson;
---checking
SELECT * FROM rental  ORDER BY rental_id;
SELECT * FROM payment ORDER BY payment_id;

RESET ROLE;
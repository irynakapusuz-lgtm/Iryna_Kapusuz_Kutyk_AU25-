DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rentaluser') THEN
    CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rental') THEN
    CREATE ROLE rental;
  END IF;
END $$;

-- Granting connect;
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
GRANT USAGE ON SCHEMA public TO rentaluser;

-- Grant SELECT on customer to rentaluser 
GRANT SELECT ON public.customer TO rentaluser;

SET ROLE rentaluser;
SELECT * FROM public.customer;
RESET ROLE;

-- Adding rentaluser to group rental
GRANT rental TO rentaluser;


---4: Grant INSERT+UPDATE to rental group, insert + update under that role
GRANT INSERT, UPDATE ON public.rental TO rental;
GRANT SELECT (rental_id) ON public.rental TO rental;
GRANT USAGE, SELECT ON SEQUENCE public.rental_rental_id_seq TO rental;

GRANT SELECT ON public.inventory TO rental;
GRANT SELECT ON public.customer  TO rental;
GRANT SELECT ON public.staff     TO rental;

SET ROLE rental;
ALTER TABLE public.rental DISABLE ROW LEVEL SECURITY;


INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT
  NOW(),
  (SELECT inventory_id FROM public.inventory ORDER BY inventory_id LIMIT 1),
  (SELECT customer_id  FROM public.customer  ORDER BY customer_id  LIMIT 1),
  NULL,
  (SELECT staff_id     FROM public.staff     ORDER BY staff_id     LIMIT 1)
RETURNING rental_id;

UPDATE public.rental
SET return_date = NOW()
WHERE rental_id = (SELECT MIN(rental_id) FROM public.rental);

RESET ROLE;


---5: Revoke INSERT from rental group and prove denied
  

REVOKE INSERT ON public.rental FROM rental;

SET ROLE rental;

-- Must fail with: ERROR: permission denied for table rental
INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT
  NOW(),
  i.inventory_id,
  c.customer_id,
  NULL,
  s.staff_id
FROM public.inventory i
CROSS JOIN public.customer c
CROSS JOIN public.staff s
LIMIT 1;

RESET ROLE;



--- 6: Create client function 
  

--- Creating a table
CREATE TABLE IF NOT EXISTS public.client_customer_map (
  role_name   text PRIMARY KEY,
  customer_id integer NOT NULL UNIQUE REFERENCES public.customer(customer_id) ON DELETE CASCADE
);

-- Function to create client role for customer (non-empty rental and payment)
CREATE OR REPLACE FUNCTION public.create_client_role(p_customer_id integer, p_password text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_first text;
  v_last  text;
  v_role  text;
BEGIN
  SELECT c.first_name, c.last_name
  INTO v_first, v_last
  FROM public.customer c
  WHERE c.customer_id = p_customer_id
    AND EXISTS (SELECT 1 FROM public.rental  r WHERE r.customer_id = c.customer_id)
    AND EXISTS (SELECT 1 FROM public.payment p WHERE p.customer_id = c.customer_id);

  IF v_first IS NULL THEN
    RAISE EXCEPTION 'Customer % not found or has empty rental/payment history', p_customer_id;
  END IF;

  v_role :=
    'client_' ||
    lower(regexp_replace(v_first, '\s+', '', 'g')) ||
    '_' ||
    lower(regexp_replace(v_last,  '\s+', '', 'g'));

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = v_role) THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', v_role, p_password);
  END IF;


  -- Save mapping 
  INSERT INTO public.client_customer_map(role_name, customer_id)
  VALUES (v_role, p_customer_id)
  ON CONFLICT (role_name) DO UPDATE
  SET customer_id = EXCLUDED.customer_id;

  EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), v_role);
  EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', v_role);
  EXECUTE format('GRANT SELECT ON public.rental TO %I', v_role);
  EXECUTE format('GRANT SELECT ON public.payment TO %I', v_role);

  RETURN v_role;
END $$;

-- Creating client role;
SELECT public.create_client_role(
  (SELECT c.customer_id
   FROM public.customer c
   WHERE EXISTS (SELECT 1 FROM public.rental  r WHERE r.customer_id = c.customer_id)
     AND EXISTS (SELECT 1 FROM public.payment p WHERE p.customer_id = c.customer_id)
   ORDER BY c.customer_id
   LIMIT 1),
  'ClientPass123!'
) AS created_client_role;


-- Helper: resolve customer_id for the current client role
---(clients do NOT need access to map table)
CREATE OR REPLACE FUNCTION public.client_customer_id()
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT m.customer_id
  FROM public.client_customer_map m
  WHERE m.role_name = current_user
$$;


---Task 3
---Row-level-security;
ALTER TABLE public.rental  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;

-- Create policies ONCE that work for ANY client_* role 
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='rental' AND policyname='rental_client_rls'
  ) THEN
    EXECUTE $p$
      CREATE POLICY rental_client_rls
      ON public.rental
      FOR SELECT
      TO PUBLIC
      USING (
        customer_id = public.client_customer_id()
      )
    $p$;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='payment' AND policyname='payment_client_rls'
  ) THEN
    EXECUTE $p$
      CREATE POLICY payment_client_rls
      ON public.payment
      FOR SELECT
      TO PUBLIC
      USING (
        customer_id = public.client_customer_id()
      )
    $p$;
  END IF;
END $$;



-- Example verification for client_mary_smith:
SET ROLE client_mary_smith;


SELECT 'rental'  AS src, COUNT(DISTINCT customer_id) AS distinct_customers_visible
FROM public.rental
UNION ALL
SELECT 'payment' AS src, COUNT(DISTINCT customer_id)
FROM public.payment;


SELECT DISTINCT customer_id FROM public.rental;
SELECT DISTINCT customer_id FROM public.payment;

RESET ROLE;


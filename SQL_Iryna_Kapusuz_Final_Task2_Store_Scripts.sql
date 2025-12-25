----Creating a database;
CREATE DATABASE retail_store;
---Task 2. Creating tables
---1. Creating schema
CREATE SCHEMA IF NOT EXISTS store;

-- 2. Customers table
CREATE TABLE IF NOT EXISTS store.Customers (
customer_id SERIAL PRIMARY KEY,
first_name VARCHAR(50),
last_name VARCHAR(50),
email VARCHAR(100),
phone VARCHAR(30),
address VARCHAR(150),
created_at DATE DEFAULT CURRENT_DATE);
SELECT *
FROM store.customers;

-- 3. Employees table


SELECT *
FROM store.employees;

-- 4. Suppliers table
CREATE TABLE IF NOT EXISTS store.Suppliers (
supplier_id SERIAL PRIMARY KEY,
supplier_name VARCHAR(100),
contact_email VARCHAR(100),
phone VARCHAR(30));

SELECT *
FROM store.suppliers;


-- 5. Products table
CREATE TABLE IF NOT EXISTS  store.Products (
product_id SERIAL PRIMARY KEY,
product_name VARCHAR(100),
brand VARCHAR(50),
category VARCHAR(50),
model VARCHAR(50),
price DECIMAL(10,2),
stock INT,
total_value DECIMAL(12,2));

SELECT *
FROM store.products;

-- 6. Orders table
CREATE TABLE IF NOT EXISTS store.Orders (
order_id SERIAL PRIMARY KEY,
customer_id INT REFERENCES store.Customers(customer_id),
employee_id INT REFERENCES store.Employees(employee_id),
order_date DATE DEFAULT CURRENT_DATE,status VARCHAR(50) DEFAULT 'Pending');

SELECT *
FROM store.orders;

-- 7. OrderItems table (junction table  between Orders & Products)
CREATE TABLE IF NOT EXISTS store.OrderItems (
    order_id INT REFERENCES store.Orders(order_id),
    product_id INT REFERENCES store.Products(product_id),
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2),
    line_total DECIMAL(12,2),  
    PRIMARY KEY (order_id, product_id)
);
SELECT *
FROM store.OrderItems;

-- 8. Product_Supplier table (junction table between Products & Suppliers)
CREATE TABLE IF NOT EXISTS store.Product_Supplier (
    product_id INT REFERENCES store.Products(product_id),
    supplier_id INT REFERENCES store.Suppliers(supplier_id),
    supply_price DECIMAL(10,2),
    PRIMARY KEY (product_id, supplier_id)
);

SELECT *
FROM store.Product_Supplier;

---Task 3. Altering tables
---Customers: email should be unique
ALTER TABLE store.customers
ADD CONSTRAINT unique_email UNIQUE (email);
---Orders: order date is after Jan 1, 2024
ALTER TABLE store.Orders
ADD CONSTRAINT chk_order_date_after_2024
CHECK (order_date > DATE '2024-01-01');

---Suppliers: email should be unique;
ALTER TABLE store.Suppliers
ADD CONSTRAINT uq_supplier_email UNIQUE (contact_email);

---Products: 
---price can not be negative
ALTER TABLE store.Products
ADD CONSTRAINT chk_price_non_negative
CHECK(price >= 0);

---Products: stock must be 0 or more
ALTER TABLE store.Products
ADD CONSTRAINT chk_stock_non_negative
CHECK (stock >= 0);

ALTER TABLE store.Products
ADD CONSTRAINT unique_product_entry UNIQUE (product_name, brand, model);


---Orders: status must be one of three values
ALTER TABLE store.Orders
ADD CONSTRAINT chk_order_status_valid
CHECK (status IN ('Pending', 'Shipped', 'Delivered'));
ALTER TABLE store.orders
ADD CONSTRAINT unique_order_combo
UNIQUE (customer_id, employee_id, order_date);

---Task 4. İnserting into tables.

INSERT INTO store.Customers (first_name, last_name, email, phone, address)
VALUES
('İryna', 'Kutyk', 'iryna777@gmail.com', '+90531345789', 'Maslak str 145/3, Istanbul, 34485'),
('Oxana', 'Sidorenko', 'oxana.sid2409@gmail.com', '+90531897645', 'Aydos str 234/5, İstanbul, 34598'),
('Pavlo', 'Zibrov', 'pavlo.zib@hotmail.com', '+90531894563', 'Levent str 45/2, İstanbul, 34984'),
('Emir', 'Aksoy', 'aksoy89@hotmail.com', '+9053289534', 'Atakent str 6/45 Izmir, 37219'),
('Murat', 'Serdar', 'murats@gmail.com', '+90534893567', 'Beykoz str 23/9, Antalya, 35632' ),
('Vasyl', 'Stus', 'stus.vas@hotmail.com', '+90532789564', 'Zorlu str 34/2, Antalya, 35670')
ON CONFLICT (email) DO NOTHING;

SELECT *
FROM store.Customers;

INSERT INTO store.Employees (first_name, last_name, email, position, hired_at)
VALUES
('Victorlya', 'Alp', 'vik.alp@gmail.com', 'Sales Manager', '2025-09-02'),
('Ivanka', 'Dovzhenko', 'iva1209@hotmail.com', 'Accountant', '2025-09-19'),
('Mert', 'Atila', 'atila555@gmail.com', 'Technician', '2025-10-03'),
('Aslan', 'Yılmaz', 'yilmaz.aslan@hotmail.com', 'Warehouse Assistant', '2025-10-14'),
('Sophia', 'Adamenko', 'sophia.adam@gmail.com', 'Marketing Analyst', '2025-11-01'),
('Alex', 'Rudenko', 'alex.rud@gmail.com', 'Customer Support', '2025-11-17')
ON CONFLICT (email) DO NOTHING;

SELECT *
FROM store.Employees;

INSERT INTO store.Suppliers (supplier_name, contact_email, phone)
VALUES
('Megahouse', 'contact@megahouse.com', '+907654328'),
('Technohub', 'sales@techno.com', '+953654180'),
('DysonTech', 'info@dysontech.com', '+907642867'),
('PowerTools', 'support@powertools.com', '+9053654698'),
('EcoPlus', 'contact@ecoplus.com', '+9053178537'),
('Epicenter', 'service@epicenter.com', '+902126798')
ON CONFLICT (contact_email) DO NOTHING;

SELECT *
FROM store.Suppliers;

INSERT INTO store.Products (product_name, brand, category, model, price, stock)
VALUES
('Blender', 'MixPro', 'Kitchen', 'MX100', 49.99, 10),
('Toaster', 'HeatMaster', 'Kitchen', 'HT200', 29.99, 15),
('Microwave', 'QuickHeat', 'Appliance', 'QH300', 89.99, 8),
('Vacuum', 'CleanSweep', 'Cleaning', 'CS400', 120.00, 5),
('Iron', 'PressIt', 'Laundry', 'PI500', 35.00, 12),
('Fan', 'BreezeX', 'Cooling', 'BX600', 45.50, 9)
ON CONFLICT (product_name, brand, model) DO NOTHING;

SELECT *
FROM store.Products;

INSERT INTO store.Orders (customer_id, employee_id, order_date, status)
VALUES
(1, 13, '2025-09-05', 'Pending'),
(2, 14, '2025-09-18', 'Shipped'),
(3, 15, '2025-10-01', 'Delivered'),
(4, 16, '2025-10-15', 'Pending'),
(5, 17, '2025-11-03', 'Shipped'),
(6, 18, '2025-11-20', 'Delivered')
ON CONFLICT ON CONSTRAINT unique_order_combo DO NOTHING;

SELECT *
FROM store.Orders;


---I have struggled here 
---so I follow like: 
-- 2 × Blender (Product 1, Price 49.99)
INSERT INTO store.OrderItems (order_id, product_id, quantity, unit_price, line_total)
VALUES ((SELECT order_id FROM store.Orders WHERE customer_id = 1 AND employee_id = 13),
1, 2, 49.99, 2 * 49.99);

-- 1 × Toaster (Product 2, Price 29.99)
INSERT INTO store.OrderItems (order_id, product_id, unit_price, line_total)
VALUES ((SELECT order_id FROM store.Orders WHERE customer_id = 2 AND employee_id = 14),
2, 29.99, 29.99);

-- 3 × Microwave (Product 3, Price 89.99)
INSERT INTO store.OrderItems (order_id, product_id, quantity, unit_price, line_total)
VALUES ((SELECT order_id FROM store.Orders WHERE customer_id = 3 AND employee_id = 15),
3, 3, 89.99, 3 * 89.99);

-- 1 × Vacuum (Product 4, Price 120.00)
INSERT INTO store.OrderItems (order_id, product_id, unit_price, line_total)
VALUES ((SELECT order_id FROM store.Orders WHERE customer_id = 4 AND employee_id = 16),
4, 120.00, 120.00);

-- 2 × Iron (Product 5, Price 35.00)
INSERT INTO store.OrderItems (order_id, product_id, quantity, unit_price, line_total)
VALUES ((SELECT order_id FROM store.Orders WHERE customer_id = 5 AND employee_id = 17),
5, 2, 35.00, 2 * 35.00);

-- 1 × Fan (Product 6, Price 45.50)
INSERT INTO store.OrderItems (order_id, product_id, unit_price, line_total)
VALUES ((SELECT order_id FROM store.Orders WHERE customer_id = 6 AND employee_id = 18),
6, 45.50, 45.50);

INSERT INTO store.Product_Supplier (product_id, supplier_id, supply_price)
VALUES 
(1, 1, 35.00),
(2, 2, 20.00),
(3, 3, 65.00),
(4, 4, 90.00),
(5, 5, 25.00),
(6, 6, 30.00)
ON CONFLICT DO NOTHING;

---Task 5. Creating functions
---Task 5.1 This function created to update only columns product_name, price, stock 
---in the Products table based on inputs and runs update command.


CREATE OR REPLACE FUNCTION update_product_column(
p_product_id INT,
p_column_name TEXT,
p_new_value TEXT)
RETURNS VOID AS
$$
DECLARE query TEXT;
BEGIN
IF p_column_name NOT IN ('product_name', 'price', 'stock') THEN
RAISE EXCEPTION 'You can only update product_name, price, or stock.';
END IF;
query := FORMAT('UPDATE store.Products SET %I = %L WHERE product_id = %L',
p_column_name, p_new_value, p_product_id );
EXECUTE query;
END;
$$ LANGUAGE plpgsql;

---verification check.
SELECT update_product_column(2, 'price', '39.99');
SELECT * FROM store.Products WHERE product_id = 2;


---Task 5.2 This function inserts new order into the Orders table
---using customers email adress instead of ID
---if customer is found it adds new row into the Orders table
CREATE OR REPLACE FUNCTION store.add_order(in_customer_email TEXT)
RETURNS VOID AS
$$
DECLARE
v_customer_id INT;
BEGIN
SELECT customer_id
INTO v_customer_id
FROM store.Customers
WHERE email = in_customer_email;
IF v_customer_id IS NULL THEN
RAISE EXCEPTION 'Customer not found with email: %', in_customer_email;
END IF;
INSERT INTO store.Orders (customer_id)
VALUES (v_customer_id);
RAISE NOTICE 'Order added for customer %', in_customer_email;
END;
$$ LANGUAGE plpgsql;

------verification check.
SELECT store.add_order('iryna777@gmail.com');
SELECT *
FROM store.Orders
WHERE customer_id = (SELECT customer_id
FROM store.Customers
WHERE email = 'iryna777@gmail.com')
ORDER BY order_date DESC;

---Task 6. Creating a view which returns sales analytics for the last quarter
--- such as customers names, orders details etc.
CREATE VIEW store.recent_quarter_analytics AS
SELECT DISTINCT
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    o.order_date,
    p.product_name,
    oi.quantity,
    oi.line_total
FROM store.orders o
JOIN store.customers c ON o.customer_id = c.customer_id
JOIN store.orderitems oi ON o.order_id = oi.order_id
JOIN store.products p ON oi.product_id = p.product_id
WHERE DATE_TRUNC('quarter', o.order_date) = (
    SELECT MAX(DATE_TRUNC('quarter', order_date)) FROM store.orders
);

SELECT *
FROM store.recent_quarter_analytics;

---Task 7.Creating a role
CREATE ROLE manager LOGIN PASSWORD 'ElectronicsStore@1209';
GRANT CONNECT ON DATABASE retail_store TO manager;
GRANT USAGE ON SCHEMA store TO manager;
GRANT SELECT ON ALL TABLES IN SCHEMA store TO manager;
ALTER DEFAULT PRIVILEGES IN SCHEMA store
GRANT SELECT ON TABLES TO manager;

SELECT * 
FROM store.Products;

DROP TABLE IF EXISTS Order_Items CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Item_Ingredients CASCADE;
DROP TABLE IF EXISTS Menu_Items CASCADE;
DROP TABLE IF EXISTS Ingredients CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS Stores CASCADE;


CREATE TABLE IF NOT EXISTS Stores (
  store_id SERIAL PRIMARY KEY,
  address VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  phone_number VARCHAR(30) UNIQUE NOT NULL,
  opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Customers (
  customer_id SERIAL PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name  VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone_number VARCHAR(30) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Ingredients (
    ingredient_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    stock_quantity NUMERIC(10, 2) NOT NULL DEFAULT 0,
    unit VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS Menu_Items (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    size VARCHAR(20),
    price NUMERIC(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS Item_Ingredients (
    item_id INTEGER REFERENCES Menu_Items(item_id) ON DELETE CASCADE,
    ingredient_id INTEGER REFERENCES Ingredients(ingredient_id) ON DELETE RESTRICT,
    quantity_required NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (item_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customers(customer_id) ON DELETE SET NULL,
    store_id INTEGER REFERENCES Stores(store_id) ON DELETE RESTRICT,
    order_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending'
);

CREATE TABLE IF NOT EXISTS Order_Items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES Orders(order_id) ON DELETE CASCADE,
    item_id INTEGER REFERENCES Menu_Items(item_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL,
    price_at_time_of_order NUMERIC(10, 2) NOT NULL
);

--Due to this error psycopg2.errors.StringDataRightTruncation: value too long for type character varying(20)
--Alter column for phone number for both store and customer to relax the schema widen the column
--Increase the phone number character from 20 to 30


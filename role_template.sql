-- ===========================================
-- roles_template.sql (SAFE TEMPLATE VERSION)
-- NOTE:
--   Replace all placeholder passwords before 
--   running this script in a real environment.
--   Commit this version to GitHub — NEVER the one 
--   containing actual passwords.
-- ===========================================


---------------------------------------------------
-- ADMIN USER (FULL PRIVILEGES - NON SUPERUSER)
---------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_user') THEN
        CREATE ROLE admin_user
            LOGIN
            PASSWORD 'CHANGE_ME_Admin!';
    END IF;
END
$$;


---------------------------------------------------
-- DATA ENGINEER (FULL DML ON PUBLIC SCHEMA)
---------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'data_engineer') THEN
        CREATE ROLE data_engineer
            LOGIN
            PASSWORD 'CHANGE_ME_DataEngineer!';
    END IF;
END
$$;


---------------------------------------------------
-- DATA ANALYST (READ-ONLY ON PRODUCTION TABLES)
---------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'data_analyst') THEN
        CREATE ROLE data_analyst
            LOGIN
            PASSWORD 'CHANGE_ME_DataAnalyst!';
    END IF;
END
$$;


---------------------------------------------------
-- DATA SCIENTIST (READ PROD + WRITE SANDBOX)
---------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'data_scientist') THEN
        CREATE ROLE data_scientist
            LOGIN
            PASSWORD 'CHANGE_ME_DataScientist!';
    END IF;
END
$$;


---------------------------------------------------
-- CUSTOMER SERVICE (MANAGE ORDERS & CUSTOMERS)
---------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'customer_service') THEN
        CREATE ROLE customer_service
            LOGIN
            PASSWORD 'CHANGE_ME_CustomerService!';
    END IF;
END
$$;


---------------------------------------------------
-- SELF SERVICE (WEB/MOBILE CUSTOMER APP USER)
---------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'self_service') THEN
        CREATE ROLE self_service
            LOGIN
            PASSWORD 'CHANGE_ME_SelfService!';
    END IF;
END
$$;

-- END OF ROLE CREATION TEMPLATE

GRANT CONNECT ON DATABASE rushmore
  TO admin_user, data_engineer, data_analyst, data_scientist, customer_service, self_service;

-- 2) Allow basic usage of the public schema (seeing objects)
GRANT USAGE ON SCHEMA public
  TO admin_user, data_engineer, data_analyst, data_scientist, customer_service, self_service;

-- ======================================================
--  ADMIN ROLE (FULL CONTROL EXCEPT SUPERUSER)     
-- ======================================================

-- Admin should have full power over everything in PUBLIC.
-- They can create tables, alter structures, drop objects, etc.
GRANT ALL PRIVILEGES ON SCHEMA public TO admin_user;

GRANT ALL PRIVILEGES
  ON ALL TABLES IN SCHEMA public
  TO admin_user;

GRANT ALL PRIVILEGES
  ON ALL SEQUENCES IN SCHEMA public
  TO admin_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON TABLES TO admin_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON SEQUENCES TO admin_user;

-- Admin can create additional schemas if needed
GRANT CREATE ON DATABASE rushmore TO admin_user;


-- ============================================================
-- DATA ENGINEER
-- Full DML on all tables (but not a superuser or schema owner)
-- ============================================================

-- Existing objects
GRANT SELECT, INSERT, UPDATE, DELETE
  ON ALL TABLES IN SCHEMA public
  TO data_engineer;

GRANT USAGE, SELECT, UPDATE
  ON ALL SEQUENCES IN SCHEMA public
  TO data_engineer;

-- Future objects (tables created later in public)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO data_engineer;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO data_engineer;

-- ============================================================
-- DATA ANALYST
-- Read-only on production tables/views, can create temp tables
-- ============================================================

GRANT TEMP ON DATABASE rushmore TO data_analyst;

GRANT SELECT
  ON ALL TABLES IN SCHEMA public
  TO data_analyst;

GRANT SELECT
  ON ALL SEQUENCES IN SCHEMA public
  TO data_analyst;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO data_analyst;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO data_analyst;

-- ============================================================
-- DATA SCIENTIST
-- Read-only on prod tables + write access in a sandbox schema
-- ============================================================

GRANT TEMP ON DATABASE rushmore TO data_scientist;

GRANT SELECT
  ON ALL TABLES IN SCHEMA public
  TO data_scientist;

GRANT SELECT
  ON ALL SEQUENCES IN SCHEMA public
  TO data_scientist;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO data_scientist;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO data_scientist;

-- Optional: dedicated sandbox for experiments
CREATE SCHEMA IF NOT EXISTS sandbox;

GRANT USAGE, CREATE ON SCHEMA sandbox TO data_scientist;

ALTER DEFAULT PRIVILEGES IN SCHEMA sandbox
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO data_scientist;

ALTER DEFAULT PRIVILEGES IN SCHEMA sandbox
  GRANT USAGE, SELECT ON SEQUENCES TO data_scientist;

-- Analysts may read from sandbox but not change it
GRANT USAGE ON SCHEMA sandbox TO data_analyst;
ALTER DEFAULT PRIVILEGES IN SCHEMA sandbox
  GRANT SELECT ON TABLES TO data_analyst;

-- ============================================================
-- CUSTOMER SERVICE PROCESSORS
-- Call center / ops staff; can manage orders & customers,
-- but cannot change schema or delete history
-- ============================================================

-- They can view catalog & stores
GRANT SELECT ON
  Stores,
  Menu_Items,
  Ingredients
TO customer_service;

-- They can view and update customers (e.g., address, phone)
GRANT SELECT, UPDATE ON
  Customers
TO customer_service;

-- They can create and update orders/line items
-- (e.g., modify status, fix quantities), but not delete history
GRANT SELECT, INSERT, UPDATE ON
  Orders,
  Order_Items
TO customer_service;

-- They need sequences for INSERTs on serial PKs
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO customer_service;

-- ============================================================
-- CUSTOMER SELF SERVICE ORDER
-- Minimal rights for a front-end app (e.g., website/mobile)
-- ============================================================

-- They can see which stores and menu items exist
GRANT SELECT ON
  Stores,
  Menu_Items,
  Ingredients
TO self_service;

-- They can create customers and read them (for simplicity;
-- row-level security would be needed to truly limit to "their own")
GRANT SELECT, INSERT ON
  Customers
TO self_service;

-- They can place orders and add line items, but not modify old ones
GRANT INSERT, SELECT ON
  Orders,
  Order_Items
TO self_service;

-- Needed for serial PKs on INSERT
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO self_service;

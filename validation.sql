-- validation.sql
-- Sanity checks and integrity validation after data population

-- 1) Row count targets (adjust expectations as needed)
SELECT 'Stores' AS table, COUNT(*) AS rows FROM Stores
UNION ALL SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL SELECT 'Ingredients', COUNT(*) FROM Ingredients
UNION ALL SELECT 'Menu_Items', COUNT(*) FROM Menu_Items
UNION ALL SELECT 'Item_Ingredients', COUNT(*) FROM Item_Ingredients
UNION ALL SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL SELECT 'Order_Items', COUNT(*) FROM Order_Items;

-- 2) Orphan checks (left-joins should find zero orphans)
-- 2a) Order_Items -> Orders
SELECT COUNT(*) AS orphan_order_items_without_order
FROM Order_Items oi
LEFT JOIN Orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL;

-- 2b) Order_Items -> Menu_Items
SELECT COUNT(*) AS orphan_order_items_without_menu_item
FROM Order_Items oi
LEFT JOIN Menu_Items mi ON mi.item_id = oi.item_id
WHERE mi.item_id IS NULL;

-- 2c) Item_Ingredients -> Menu_Items
SELECT COUNT(*) AS orphan_item_ingredients_without_item
FROM Item_Ingredients ii
LEFT JOIN Menu_Items mi ON mi.item_id = ii.item_id
WHERE mi.item_id IS NULL;

-- 2d) Item_Ingredients -> Ingredients
SELECT COUNT(*) AS orphan_item_ingredients_without_ingredient
FROM Item_Ingredients ii
LEFT JOIN Ingredients ig ON ig.ingredient_id = ii.ingredient_id
WHERE ig.ingredient_id IS NULL;

-- 2e) Orders -> Stores
SELECT COUNT(*) AS orphan_orders_without_store
FROM Orders o
LEFT JOIN Stores s ON s.store_id = o.store_id
WHERE s.store_id IS NULL;

-- 2f) Orders -> Customers (customer_id may be NULL by design; only check when not NULL)
SELECT COUNT(*) AS orphan_orders_with_bad_customer
FROM Orders o
LEFT JOIN Customers c ON c.customer_id = o.customer_id
WHERE o.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- 3) Totals reconciliation: Orders.total_amount should equal sum of its line items
SELECT o.order_id, o.total_amount,
       SUM(oi.quantity * oi.price_at_time_of_order) AS line_sum
FROM Orders o
JOIN Order_Items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
HAVING o.total_amount <> SUM(oi.quantity * oi.price_at_time_of_order)
LIMIT 50;

-- 4) Uniqueness sanity checks (should return zero rows)
SELECT email, COUNT(*) AS cnt FROM Customers GROUP BY email HAVING COUNT(*) > 1;
SELECT phone_number, COUNT(*) AS cnt FROM Customers GROUP BY phone_number HAVING COUNT(*) > 1;
SELECT name, COUNT(*) AS cnt FROM Ingredients GROUP BY name HAVING COUNT(*) > 1;
SELECT phone_number, COUNT(*) AS cnt FROM Stores GROUP BY phone_number HAVING COUNT(*) > 1;

-- 5) Basic data quality checks
-- Ensure non-negative prices and quantities
SELECT COUNT(*) AS negative_menu_item_prices FROM Menu_Items WHERE price < 0;
SELECT COUNT(*) AS negative_line_prices FROM Order_Items WHERE price_at_time_of_order < 0;
SELECT COUNT(*) AS nonpositive_line_quantities FROM Order_Items WHERE quantity <= 0;

-- Optional: status distribution (helps spot typos)
SELECT status, COUNT(*) FROM Orders GROUP BY status ORDER BY COUNT(*) DESC;

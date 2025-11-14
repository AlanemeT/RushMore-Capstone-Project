--1) Total sales revenue per store
SELECT
  s.store_id,
  s.city,
  SUM(o.total_amount) AS revenue,
  COUNT(*) AS orders_count
FROM orders o
JOIN stores s ON s.store_id = o.store_id
GROUP BY s.store_id, s.city
ORDER BY revenue DESC;

--2) Top 10 most valuable customers (by total spending)
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.email,
  SUM(o.total_amount) AS total_spent,
  COUNT(*) AS orders_count
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY total_spent DESC
LIMIT 10;

--3) Most popular menu item (by quantity sold) across all stores
SELECT
  mi.item_id,
  mi.name,
  SUM(oi.quantity) AS qty_sold,
  SUM(oi.quantity * oi.price_at_time_of_order) AS revenue
FROM order_items oi
JOIN menu_items mi ON mi.item_id = oi.item_id
GROUP BY mi.item_id, mi.name
ORDER BY qty_sold DESC
LIMIT 1; 

--4) Average order value
SELECT
  ROUND(AVG(o.total_amount)::numeric, 2) AS avg_order_value
FROM orders o;


--5) Busiest hours of the day for orders
SELECT
  EXTRACT(HOUR FROM o.order_timestamp) AS hour_of_day,
  COUNT(*) AS orders_count
FROM orders o
GROUP BY hour_of_day
ORDER BY orders_count DESC, hour_of_day;

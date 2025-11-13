-- indexes.sql
-- Secondary indexes for FK lookups and common analytics filters

BEGIN;

-- ITEM_INGREDIENTS lookups by ingredient
CREATE INDEX IF NOT EXISTS idx_item_ingredients_ingredient_id
  ON Item_Ingredients (ingredient_id);

-- ORDER_ITEMS lookups by order and by item
CREATE INDEX IF NOT EXISTS idx_order_items_order_id
  ON Order_Items (order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_item_id
  ON Order_Items (item_id);

-- ORDERS filtering by store + time (useful for revenue by store, busy hours)
CREATE INDEX IF NOT EXISTS idx_orders_store_timestamp
  ON Orders (store_id, order_timestamp);

-- MENU_ITEMS filtering/grouping by category and size
CREATE INDEX IF NOT EXISTS idx_menu_items_category_size
  ON Menu_Items (category, size);

COMMIT;

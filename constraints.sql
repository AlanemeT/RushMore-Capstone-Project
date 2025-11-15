BEGIN;

-- Non-negative money values
ALTER TABLE Menu_Items
  ADD CONSTRAINT menu_items_price_nonneg CHECK (price >= 0);

ALTER TABLE Orders
  ADD CONSTRAINT orders_total_nonneg CHECK (total_amount >= 0);

ALTER TABLE Order_Items
  ADD CONSTRAINT order_items_price_nonneg CHECK (price_at_time_of_order >= 0);

-- Positive quantities
ALTER TABLE Order_Items
  ADD CONSTRAINT order_items_qty_pos CHECK (quantity > 0);

-- Reasonable recipe quantities
ALTER TABLE Item_Ingredients
  ADD CONSTRAINT item_ing_qty_pos CHECK (quantity_required > 0);

-- Status whitelist (optional; keep only the statuses you use)
ALTER TABLE Orders
  ADD CONSTRAINT orders_status_valid CHECK (status IN ('Pending','In Progress','Delivered','Cancelled'));

-- Basic phone/e-mail sanity (optional; keep light)
-- (email already UNIQUE/NOT NULL; phone length is covered by VARCHAR(30))
COMMIT;

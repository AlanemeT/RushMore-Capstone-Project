import os
import json
import random
from datetime import datetime, timedelta
try:
    from dotenv import load_dotenv
except Exception:
    load_dotenv = lambda *args, **kwargs: None

import psycopg2
import psycopg2.extras as extras
from faker import Faker

# Optional YAML support
try:
    import yaml
except Exception:
    yaml = None

# ----------------------------
# Configuration
# ----------------------------
DEFAULT_COUNTS = {
    "stores": 4,
    "ingredients": 45,
    "menu_items": 25,
    "customers": 1200,
    "orders": 6000,
    "avg_items_per_order": 3
}

BATCH_SIZE = 1000
RNG_SEED = 42


def read_config():
    """Build a DSN from env or config file."""
    load_dotenv()  # load .env if present

    # Priority 1: DATABASE_URL
    #url = os.getenv("DATABASE_URL")
    #if url:
        #return url

    # Priority 2: discrete env vars
    host = os.getenv("DB_HOST")
    dbname = os.getenv("DB_NAME") or os.getenv("DB_DBNAME")
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")
    port = os.getenv("DB_PORT", "5432")
    sslmode = os.getenv("DB_SSLMODE", "require")

    if all([host, dbname, user, password]):
        return f"postgresql://{user}:{password}@{host}:{port}/{dbname}?sslmode={sslmode}"

    # Priority 3: config.yaml / config.yml
    for candidate in ("config.yaml", "config.yml"):
        if yaml and os.path.exists(candidate):
            with open(candidate, "r") as f:
                cfg = yaml.safe_load(f) or {}
            host = cfg.get("host")
            dbname = cfg.get("dbname")
            user = cfg.get("user")
            password = cfg.get("password")
            port = str(cfg.get("port", 5432))
            sslmode = cfg.get("sslmode", "require")
            if all([host, dbname, user, password]):
                return f"postgresql://{user}:{password}@{host}:{port}/{dbname}?sslmode={sslmode}"

    raise RuntimeError("No database configuration found. Set DATABASE_URL or DB_* env vars or config.yaml")


def chunked(iterable, size):
    it = iter(iterable)
    while True:
        batch = []
        try:
            for _ in range(size):
                batch.append(next(it))
        except StopIteration:
            if batch:
                yield batch
            break
        yield batch


def execute_values(cur, sql, rows, page_size=1000):
    extras.execute_values(cur, sql, rows, page_size=page_size)


# ----------------------------
# Data generation
# ----------------------------
def generate_stores(fake, n):
    cities = list({fake.city() for _ in range(n * 3)})[:n]
    rows = []
    for i in range(n):
        rows.append((
            fake.street_address(),
            cities[i % len(cities)],
            fake.phone_number(),
            fake.date_time_between(start_date="-3y", end_date="now")
        ))
    return rows


def generate_ingredients(fake, n):
    base_names = [
        "Mozzarella", "Cheddar", "Parmesan", "Goat Cheese", "Ricotta",
        "Pepperoni", "Salami", "Ham", "Bacon", "Chicken", "Beef",
        "Mushrooms", "Onions", "Green Peppers", "Red Peppers", "Olives",
        "Pineapple", "Sweetcorn", "Tomatoes", "Spinach", "Garlic",
        "Basil", "Oregano", "Chilli Flakes", "BBQ Sauce", "Tomato Sauce",
        "Pesto", "Pizza Dough", "Olive Oil", "Anchovies", "Tuna",
        "Jalapenos", "Artichokes", "Prosciutto", "Sausage", "Truffle Oil",
        "Blue Cheese", "Feta", "Rocket", "Sun-dried Tomatoes", "Capers",
        "Water", "Cola Syrup", "Lemonade Syrup", "Ice"
    ]
    while len(base_names) < n:
        base_names.append(Faker().unique.word().title())
    rows = []
    for i in range(n):
        rows.append((
            base_names[i],
            round(max(0, random.gauss(50, 20)), 2),
            random.choice(["kg", "g", "liters", "ml", "units"])
        ))
    return rows


def generate_menu_items(fake, n):
    categories = ["Pizza", "Side", "Drink", "Dessert"]
    rows, names = [], set()
    while len(names) < n:
        cat = random.choice(categories)
        if cat == "Pizza":
            name = f"{random.choice(['Margherita','Pepperoni','BBQ Chicken','Veggie','Hawaiian','Four Cheese'])} {random.choice(['','Deluxe','Special'])}".strip()
            size = random.choice(["Small", "Medium", "Large", "Family"])
            price = round(random.uniform(6.0, 22.0), 2)
        elif cat == "Side":
            name = random.choice(["Garlic Bread", "Wedges", "Chicken Wings", "Coleslaw"])
            size = "N/A"
            price = round(random.uniform(2.5, 8.0), 2)
        elif cat == "Drink":
            name = random.choice(["Cola", "Orange Soda", "Lemonade", "Water"])
            size = random.choice(["330ml", "500ml"])
            price = round(random.uniform(1.0, 3.5), 2)
        else:
            name = random.choice(["Brownie", "Ice Cream", "Cheesecake"])
            size = "N/A"
            price = round(random.uniform(2.0, 6.5), 2)
        candidate = f"{name} ({size})" if size not in ["N/A", ""] else name
        if candidate not in names:
            names.add(candidate)
            rows.append((name, cat, None if size == "N/A" else size, price))
    return rows


def generate_item_ingredients(num_items, num_ingredients):
    links = []
    for item_id in range(1, num_items + 1):
        k = random.randint(2, 6)
        chosen = random.sample(range(1, num_ingredients + 1), k)
        for ing_id in chosen:
            qty = round(random.uniform(0.05, 0.5), 2)
            links.append((item_id, ing_id, qty))
    return links


def generate_customers(fake, n):
    rows = []
    for _ in range(n):
        first, last = fake.first_name(), fake.last_name()
        email = f"{first}.{last}{random.randint(1, 9999)}@{fake.free_email_domain()}".lower()
        rows.append((
            first, last, email, fake.phone_number(),
            fake.date_time_between(start_date="-2y", end_date="now")
        ))
    return rows


def generate_orders(fake, n, store_ids, customer_ids):
    rows = []
    now = datetime.utcnow()
    start = now - timedelta(days=365)
    for _ in range(n):
        ts = fake.date_time_between(start_date=start, end_date=now)
        rows.append((
            random.choice(customer_ids),
            random.choice(store_ids),
            ts,
            0.00,
            random.choice(["Pending", "In Progress", "Delivered", "Cancelled"])
        ))
    return rows


def generate_order_items(num_orders, menu_catalog, avg_items_per_order=3):
    rows = []
    for order_id in range(1, num_orders + 1):
        k = max(1, int(random.gauss(avg_items_per_order, 1)))
        for _ in range(k):
            item_id, price = random.choice(menu_catalog)
            qty = random.randint(1, 4)
            rows.append((order_id, item_id, qty, price))
    return rows


# ----------------------------
# Insert pipeline
# ----------------------------
def main():
    random.seed(RNG_SEED)
    fake = Faker()
    Faker.seed(RNG_SEED)

    dsn = read_config()
    # mask password in print
    safe_dsn = dsn
    if "://" in dsn and "@" in dsn:
        try:
            scheme, rest = dsn.split("://", 1)
            creds, hostpart = rest.split("@", 1)
            if ":" in creds:
                user, _ = creds.split(":", 1)
                safe_dsn = f"{scheme}://{user}:***@{hostpart}"
        except Exception:
            pass

    print("Connecting with:", safe_dsn)
    conn = psycopg2.connect(dsn)
    conn.autocommit = False

    counts = DEFAULT_COUNTS.copy()
    print("Target row counts:", json.dumps(counts, indent=2))

    try:
        with conn.cursor() as cur:
            # STORES
            print("Inserting Stores...")
            stores = generate_stores(fake, counts["stores"])
            execute_values(cur,
                           "INSERT INTO Stores (address, city, phone_number, opened_at) VALUES %s",
                           stores, page_size=BATCH_SIZE)

            # CUSTOMERS
            print("Inserting Customers...")
            customers = generate_customers(fake, counts["customers"])
            execute_values(cur,
                           "INSERT INTO Customers (first_name, last_name, email, phone_number, created_at) VALUES %s",
                           customers, page_size=BATCH_SIZE)

            # INGREDIENTS
            print("Inserting Ingredients...")
            ingredients = generate_ingredients(fake, counts["ingredients"])
            execute_values(cur,
                           "INSERT INTO Ingredients (name, stock_quantity, unit) VALUES %s",
                           ingredients, page_size=BATCH_SIZE)

            # MENU_ITEMS
            print("Inserting Menu_Items...")
            menu_items = generate_menu_items(fake, counts["menu_items"])
            execute_values(cur,
                           "INSERT INTO Menu_Items (name, category, size, price) VALUES %s",
                           menu_items, page_size=BATCH_SIZE)

            # Determine counts/ids
            cur.execute("SELECT COUNT(*) FROM Stores")
            n_stores = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM Ingredients")
            n_ingredients = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM Menu_Items")
            n_menu = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM Customers")
            n_customers = cur.fetchone()[0]

            # ITEM_INGREDIENTS
            print("Inserting Item_Ingredients (recipes)...")
            item_ing = generate_item_ingredients(n_menu, n_ingredients)
            execute_values(cur,
                           "INSERT INTO Item_Ingredients (item_id, ingredient_id, quantity_required) VALUES %s",
                           item_ing, page_size=BATCH_SIZE)

            # ORDERS
            print("Inserting Orders...")
            store_ids = list(range(1, n_stores + 1))
            customer_ids = list(range(1, n_customers + 1))
            orders = generate_orders(fake, counts["orders"], store_ids, customer_ids)
            execute_values(cur,
                           "INSERT INTO Orders (customer_id, store_id, order_timestamp, total_amount, status) VALUES %s",
                           orders, page_size=BATCH_SIZE)

            # Build a menu catalog for price copy
            print("Preparing catalog for Order_Items...")
            cur.execute("SELECT item_id, price FROM Menu_Items")
            menu_catalog = cur.fetchall()

            # ORDER_ITEMS (snapshot price to price_at_time_of_order)
            print("Inserting Order_Items...")
            order_items = generate_order_items(counts["orders"], menu_catalog, counts["avg_items_per_order"])
            for batch in chunked(order_items, BATCH_SIZE):
                execute_values(cur,
                               "INSERT INTO Order_Items (order_id, item_id, quantity, price_at_time_of_order) VALUES %s",
                               batch, page_size=BATCH_SIZE)

            # Update Orders.total_amount to match the sum of line items
            print("Reconciling Orders.total_amount...")
            cur.execute("""
                UPDATE Orders o
                SET total_amount = x.sum_lines
                FROM (
                    SELECT order_id, SUM(quantity * price_at_time_of_order)::NUMERIC(10,2) AS sum_lines
                    FROM Order_Items
                    GROUP BY order_id
                ) x
                WHERE x.order_id = o.order_id;
            """)

            conn.commit()
            print("Done. Commit successful.")

        # Summary
        with conn.cursor() as cur:
            for table in ["Stores", "Customers", "Ingredients", "Menu_Items", "Item_Ingredients", "Orders", "Order_Items"]:
                cur.execute(f"SELECT COUNT(*) FROM {table}")
                print(f"{table}: {cur.fetchone()[0]}")

    except Exception as e:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()

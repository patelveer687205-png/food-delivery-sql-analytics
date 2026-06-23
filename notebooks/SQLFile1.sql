-- ============================================================
-- FOOD DELIVERY SQL ANALYTICS
-- File: schema/create_tables.sql
-- Run this in SSMS after creating food_delivery_db
-- ============================================================

USE food_delivery_db;

-- Drop tables if they already exist (clean slate)
IF OBJECT_ID('delivery',    'U') IS NOT NULL DROP TABLE delivery;
IF OBJECT_ID('order_items', 'U') IS NOT NULL DROP TABLE order_items;
IF OBJECT_ID('orders',      'U') IS NOT NULL DROP TABLE orders;
IF OBJECT_ID('restaurants', 'U') IS NOT NULL DROP TABLE restaurants;
IF OBJECT_ID('customers',   'U') IS NOT NULL DROP TABLE customers;

-- ── TABLE 1: customers ────────────────────────────────────────
CREATE TABLE customers (
    customer_id     INT             PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    email           VARCHAR(150)    UNIQUE NOT NULL,
    phone           VARCHAR(15)     NOT NULL,
    city            VARCHAR(50)     NOT NULL,
    signup_date     DATE            NOT NULL
);

-- ── TABLE 2: restaurants ──────────────────────────────────────
CREATE TABLE restaurants (
    restaurant_id   INT             PRIMARY KEY,
    name            VARCHAR(150)    NOT NULL,
    city            VARCHAR(50)     NOT NULL,
    cuisine_type    VARCHAR(50)     NOT NULL,
    avg_rating      DECIMAL(3,2)    NOT NULL,
    is_active       BIT             NOT NULL DEFAULT 1
);

-- ── TABLE 3: orders ───────────────────────────────────────────
CREATE TABLE orders (
    order_id        INT             PRIMARY KEY,
    customer_id     INT             NOT NULL,
    restaurant_id   INT             NOT NULL,
    order_date      DATETIME        NOT NULL,
    total_amount    DECIMAL(10,2)   NOT NULL,
    status          VARCHAR(20)     NOT NULL,   -- Delivered / Cancelled / Pending
    payment_mode    VARCHAR(20)     NOT NULL,   -- UPI / Cash / Card / Wallet
    CONSTRAINT fk_orders_customer   FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES restaurants(restaurant_id)
);

-- ── TABLE 4: order_items ──────────────────────────────────────
CREATE TABLE order_items (
    item_id         INT             PRIMARY KEY,
    order_id        INT             NOT NULL,
    dish_name       VARCHAR(100)    NOT NULL,
    quantity        INT             NOT NULL,
    unit_price      DECIMAL(8,2)    NOT NULL,
    CONSTRAINT fk_items_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);

-- ── TABLE 5: delivery ─────────────────────────────────────────
CREATE TABLE delivery (
    delivery_id         INT         PRIMARY KEY,
    order_id            INT         NOT NULL,
    rider_id            INT         NOT NULL,
    pickup_time         DATETIME    NOT NULL,
    delivered_time      DATETIME    NOT NULL,
    delivery_minutes    INT         NOT NULL,
    rating              DECIMAL(3,2),           -- Can be NULL if not rated
    CONSTRAINT fk_delivery_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);

-- ── Verify tables created ─────────────────────────────────────
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'food_delivery_db'
ORDER BY TABLE_NAME;

PRINT '✅ All 5 tables created successfully!';
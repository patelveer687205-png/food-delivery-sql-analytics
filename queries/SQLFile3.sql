-- ============================================================
-- FOOD DELIVERY SQL ANALYTICS — ALL 15 QUERIES
-- Database: food_delivery_db
-- Run each query block separately in SSMS
-- ============================================================

USE food_delivery_db;


-- ============================================================
-- EASY QUERIES (Q1–Q5)
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- Q1: Total Revenue and Orders Per City
-- Business: Which city generates the most GMV?
-- ────────────────────────────────────────────────────────────
SELECT
    c.city,
    COUNT(o.order_id)           AS total_orders,
    SUM(o.total_amount)         AS total_revenue,
    ROUND(AVG(o.total_amount),2) AS avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.city
ORDER BY total_revenue DESC;


-- ────────────────────────────────────────────────────────────
-- Q2: Top 5 Most Ordered Dishes
-- Business: Which dishes should restaurants stock more of?
-- ────────────────────────────────────────────────────────────
SELECT TOP 5
    dish_name,
    SUM(quantity)       AS total_quantity_ordered,
    COUNT(item_id)      AS total_times_ordered,
    ROUND(AVG(unit_price), 2) AS avg_price
FROM order_items
GROUP BY dish_name
ORDER BY total_quantity_ordered DESC;


-- ────────────────────────────────────────────────────────────
-- Q3: Restaurants With Low Delivery Rating (Below 3.5)
-- Business: Which restaurants need service improvement?
-- ────────────────────────────────────────────────────────────
SELECT
    r.restaurant_id,
    r.name              AS restaurant_name,
    r.city,
    r.cuisine_type,
    COUNT(d.delivery_id)        AS total_deliveries,
    ROUND(AVG(d.rating), 2)     AS avg_delivery_rating
FROM restaurants r
JOIN orders o       ON r.restaurant_id = o.restaurant_id
JOIN delivery d     ON o.order_id = d.order_id
WHERE d.rating IS NOT NULL
GROUP BY r.restaurant_id, r.name, r.city, r.cuisine_type
HAVING AVG(d.rating) < 3.5
ORDER BY avg_delivery_rating ASC;


-- ────────────────────────────────────────────────────────────
-- Q4: Monthly Order Count and Revenue Trend
-- Business: How is business growing month over month?
-- ────────────────────────────────────────────────────────────
SELECT
    DATEPART(YEAR,  order_date) AS yr,
    DATEPART(MONTH, order_date) AS mn,
    DATENAME(MONTH, order_date) AS month_name,
    COUNT(order_id)             AS total_orders,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM orders
WHERE status = 'Delivered'
GROUP BY
    DATEPART(YEAR,  order_date),
    DATEPART(MONTH, order_date),
    DATENAME(MONTH, order_date)
ORDER BY yr, mn;


-- ────────────────────────────────────────────────────────────
-- Q5: Customers Who Never Placed an Order
-- Business: Re-engagement targets for marketing campaigns
-- ────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.email,
    c.signup_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.signup_date DESC;


-- ============================================================
-- MEDIUM QUERIES (Q6–Q10)
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- Q6: Repeat Customers — Ordered More Than 3 Times in 30 Days
-- Business: Identify loyal customers for rewards program
-- ────────────────────────────────────────────────────────────
SELECT
    c.customer_id, c.name, c.city,
    COUNT(o.order_id)            AS orders_last_30_days,
    ROUND(SUM(o.total_amount),2) AS spend_last_30_days
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE
    o.status = 'Delivered'
    AND o.order_date >= DATEADD(DAY, -30, (SELECT MAX(order_date) FROM orders))
GROUP BY c.customer_id, c.name, c.city
HAVING COUNT(o.order_id) > 2
ORDER BY orders_last_30_days DESC;


-- ────────────────────────────────────────────────────────────
-- Q7: Average Delivery Time by City
-- Business: Which city has the slowest deliveries?
-- ────────────────────────────────────────────────────────────
SELECT
    c.city,
    COUNT(d.delivery_id)                AS total_deliveries,
    ROUND(AVG(d.delivery_minutes), 1)   AS avg_delivery_minutes,
    MIN(d.delivery_minutes)             AS fastest_delivery,
    MAX(d.delivery_minutes)             AS slowest_delivery
FROM delivery d
JOIN orders o    ON d.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.city
ORDER BY avg_delivery_minutes DESC;


-- ────────────────────────────────────────────────────────────
-- Q8: Revenue Contribution % by Cuisine Type
-- Business: Which cuisine drives the most revenue?
-- ────────────────────────────────────────────────────────────
SELECT
    r.cuisine_type,
    COUNT(o.order_id)               AS total_orders,
    ROUND(SUM(o.total_amount), 2)   AS total_revenue,
    ROUND(
        SUM(o.total_amount) * 100.0 /
        (SELECT SUM(total_amount) FROM orders WHERE status = 'Delivered'),
        2
    )                               AS revenue_pct
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = 'Delivered'
GROUP BY r.cuisine_type
ORDER BY total_revenue DESC;


-- ────────────────────────────────────────────────────────────
-- Q9: Orders With Above-Average Value for Each City
-- Business: High-value orders per city for premium targeting
-- ────────────────────────────────────────────────────────────
SELECT
    o.order_id,
    c.name          AS customer_name,
    c.city,
    o.total_amount,
    ROUND(city_avg.avg_amount, 2) AS city_avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN (
    SELECT
        c2.city,
        AVG(o2.total_amount) AS avg_amount
    FROM orders o2
    JOIN customers c2 ON o2.customer_id = c2.customer_id
    WHERE o2.status = 'Delivered'
    GROUP BY c2.city
) city_avg ON c.city = city_avg.city
WHERE
    o.status = 'Delivered'
    AND o.total_amount > city_avg.avg_amount
ORDER BY c.city, o.total_amount DESC;


-- ────────────────────────────────────────────────────────────
-- Q10: Peak Order Hours
-- Business: When should rider fleet be at maximum capacity?
-- ────────────────────────────────────────────────────────────
SELECT
    DATEPART(HOUR, order_date)  AS order_hour,
    COUNT(order_id)             AS total_orders,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(
        COUNT(order_id) * 100.0 /
        (SELECT COUNT(*) FROM orders WHERE status = 'Delivered'),
        2
    )                           AS pct_of_daily_orders
FROM orders
WHERE status = 'Delivered'
GROUP BY DATEPART(HOUR, order_date)
ORDER BY total_orders DESC;


-- ============================================================
-- ADVANCED QUERIES (Q11–Q15) — Window Functions + CTEs
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- Q11: Rank Restaurants by Revenue Within Each City
-- Business: Who are the top performers in each market?
-- ────────────────────────────────────────────────────────────
SELECT
    city,
    restaurant_name,
    cuisine_type,
    total_revenue,
    total_orders,
    RANK() OVER (
        PARTITION BY city
        ORDER BY total_revenue DESC
    ) AS city_rank
FROM (
    SELECT
        r.city,
        r.name          AS restaurant_name,
        r.cuisine_type,
        COUNT(o.order_id)               AS total_orders,
        ROUND(SUM(o.total_amount), 2)   AS total_revenue
    FROM restaurants r
    JOIN orders o ON r.restaurant_id = o.restaurant_id
    WHERE o.status = 'Delivered'
    GROUP BY r.restaurant_id, r.name, r.city, r.cuisine_type
) ranked
ORDER BY city, city_rank;


-- ────────────────────────────────────────────────────────────
-- Q12: Month-over-Month Revenue Growth Using LAG()
-- Business: Is the business growing or declining?
-- ────────────────────────────────────────────────────────────
WITH monthly_revenue AS (
    SELECT
        DATEPART(YEAR,  order_date) AS yr,
        DATEPART(MONTH, order_date) AS mn,
        ROUND(SUM(total_amount), 2) AS revenue
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY
        DATEPART(YEAR,  order_date),
        DATEPART(MONTH, order_date)
)
SELECT
    yr,
    mn,
    revenue,
    LAG(revenue) OVER (ORDER BY yr, mn)     AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY yr, mn))
        * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY yr, mn), 0),
        2
    )                                        AS mom_growth_pct
FROM monthly_revenue
ORDER BY yr, mn;


-- ────────────────────────────────────────────────────────────
-- Q13: Churned Customers (No Order in Last 60 Days)
-- Business: Who needs a re-activation discount?
-- ────────────────────────────────────────────────────────────
WITH last_order AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.email,
    CAST(l.last_order_date AS DATE) AS last_order_date,
    DATEDIFF(DAY, l.last_order_date, (SELECT MAX(order_date) FROM orders)) AS days_since_last_order
FROM customers c
JOIN last_order l ON c.customer_id = l.customer_id
WHERE DATEDIFF(DAY, l.last_order_date, (SELECT MAX(order_date) FROM orders)) > 60
ORDER BY days_since_last_order DESC;


-- ────────────────────────────────────────────────────────────
-- Q14: Running Total of Revenue Per City by Month
-- Business: Cumulative GMV growth tracking
-- ────────────────────────────────────────────────────────────
WITH city_monthly AS (
    SELECT
        c.city,
        DATEPART(YEAR,  o.order_date) AS yr,
        DATEPART(MONTH, o.order_date) AS mn,
        ROUND(SUM(o.total_amount), 2) AS monthly_revenue
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.status = 'Delivered'
    GROUP BY
        c.city,
        DATEPART(YEAR,  o.order_date),
        DATEPART(MONTH, o.order_date)
)
SELECT
    city,
    yr,
    mn,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        PARTITION BY city
        ORDER BY yr, mn
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM city_monthly
ORDER BY city, yr, mn;


-- ────────────────────────────────────────────────────────────
-- Q15: Customer Segmentation — Gold / Silver / Bronze
-- Business: Which customers deserve VIP treatment?
-- ────────────────────────────────────────────────────────────
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.name,
        c.city,
        COUNT(o.order_id)               AS total_orders,
        ROUND(SUM(o.total_amount), 2)   AS total_spend,
        NTILE(3) OVER (
            ORDER BY SUM(o.total_amount) DESC
        )                               AS spend_tier
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.name, c.city
)
SELECT
    customer_id,
    name,
    city,
    total_orders,
    total_spend,
    CASE spend_tier
        WHEN 1 THEN 'Gold'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Bronze'
    END AS customer_segment
FROM customer_spend
ORDER BY total_spend DESC;
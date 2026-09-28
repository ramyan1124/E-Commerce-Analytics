USE ecommerce_analytics;

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers
FROM orders;

SELECT
    ROUND(SUM(oi.quantity * p.price * (1 - oi.discount)), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id;

SELECT
    MIN(discount) AS minimum_discount,
    MAX(discount) AS maximum_discount,
    AVG(discount) AS average_discount
FROM order_items;

SELECT
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
        2
    ) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id;

SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;

SELECT
    p.category,
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;

SELECT
    p.product_name,
    p.category,
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
        2
    ) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
        2
    ) AS revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.customer_name, c.city, c.state
ORDER BY revenue DESC
LIMIT 10;
#repeat customers vs one-time customers
SELECT
    customer_type,
    COUNT(*) AS customer_count
FROM (
    SELECT
        c.customer_id,
        CASE
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS customer_type
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.customer_id
) AS customer_summary
GROUP BY customer_type
ORDER BY customer_count DESC;

-- Average Order Value
SELECT
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100))
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered';

-- State-wise Revenue
SELECT
    c.state,
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
        2
    ) AS revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY c.state
ORDER BY revenue DESC;

-- Payment Method Analysis
SELECT
    payment_method,
    COUNT(*) AS order_count
FROM orders
WHERE order_status = 'Delivered'
GROUP BY payment_method
ORDER BY order_count DESC;

-- Top 10 Customers by Revenue
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
        2
    ) AS revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY
    c.customer_id,
    c.customer_name,
    c.city,
    c.state
ORDER BY revenue DESC
LIMIT 10;

-- Monthly Revenue + Month-over-Month Growth
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        ROUND(
            SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
            2
        ) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)

SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(
        ((revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month)) * 100,
        2
    ) AS growth_percentage
FROM monthly_revenue
ORDER BY month;

-- Top 10 Products by Quantity Sold
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- Customer Order Frequency
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY total_orders DESC
LIMIT 10;

-- Customer Lifetime Revenue
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(oi.quantity * p.price * (1 - oi.discount / 100)),
        2
    ) AS lifetime_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY lifetime_revenue DESC
LIMIT 10;
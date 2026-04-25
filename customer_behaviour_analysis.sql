-- Q1: Overall KPIs
SELECT
    COUNT(DISTINCT order_id)              AS total_orders,
    ROUND(SUM(total_amount),    2)        AS total_revenue,
    ROUND(AVG(total_amount),    2)        AS avg_order_value,
    ROUND(SUM(discount_amount), 2)        AS total_discounts_given,
    COUNT(DISTINCT user_id)               AS unique_customers
FROM orders
WHERE status NOT IN ('Cancelled');

-- Q2: Top 10 customers by lifetime value
SELECT
    u.user_id,
    MIN(u.full_name)              AS full_name,
    MIN(u.city)                   AS city,
    MIN(u.loyalty_tier)           AS loyalty_tier,
    MIN(u.age)                    AS age,
    COUNT(o.order_id)             AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS lifetime_value,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM users u
JOIN orders o ON u.user_id = o.user_id
WHERE o.status NOT IN ('Cancelled')
GROUP BY u.user_id
ORDER BY lifetime_value DESC
LIMIT 10;
-- Q3: Best-selling products
SELECT 
    p.product_name,
    p.category,
    p.brand,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.total_price), 2) AS total_revenue,
    ROUND(SUM(oi.quantity) * (p.price - p.cost_price),
            2) AS total_profit
FROM
    products p
        JOIN
    order_items oi ON p.product_id = oi.product_id
        JOIN
    orders o ON oi.order_id = o.order_id
WHERE
    o.status NOT IN ('Cancelled' , 'Returned')
GROUP BY p.product_id , p.product_name , p.category , p.brand , p.price , p.cost_price
ORDER BY units_sold DESC
LIMIT 10;

-- Q4: Order status funnel
SELECT
    status,
    COUNT(*)                                              AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)   AS percentage
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- Q5: Revenue by category
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.total_price), 2) AS total_revenue,
    ROUND(AVG(p.price), 2) AS avg_product_price
FROM
    products p
        JOIN
    order_items oi ON p.product_id = oi.product_id
        JOIN
    orders o ON oi.order_id = o.order_id
WHERE
    o.status NOT IN ('Cancelled')
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Q6: Payment method preferences
SELECT
    payment_method,
    COUNT(*)                                              AS order_count,
    ROUND(SUM(total_amount), 2)                           AS total_revenue,
    ROUND(AVG(total_amount), 2)                           AS avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)   AS usage_pct
FROM orders
GROUP BY payment_method
ORDER BY order_count DESC;

-- Q7: Review sentiment analysis
SELECT 
    p.product_name,
    p.category,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    SUM(CASE
        WHEN r.rating >= 4 THEN 1
        ELSE 0
    END) AS positive_reviews,
    SUM(CASE
        WHEN r.rating <= 2 THEN 1
        ELSE 0
    END) AS negative_reviews,
    SUM(CASE
        WHEN r.is_verified = TRUE THEN 1
        ELSE 0
    END) AS verified_reviews
FROM
    products p
        LEFT JOIN
    reviews r ON p.product_id = r.product_id
GROUP BY p.product_id , p.product_name , p.category
HAVING COUNT(r.review_id) > 0
ORDER BY avg_rating DESC;

-- Q8: Return rate per product
SELECT 
    p.product_name,
    p.category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(DISTINCT rt.return_id) AS total_returns,
    ROUND(COUNT(DISTINCT rt.return_id) * 100.0 / NULLIF(COUNT(DISTINCT oi.order_id), 0),
            2) AS return_rate_pct,
    ROUND(SUM(rt.refund_amount), 2) AS total_refunded
FROM
    products p
        JOIN
    order_items oi ON p.product_id = oi.product_id
        LEFT JOIN
    returns rt ON rt.product_id = p.product_id
        AND rt.order_id = oi.order_id
GROUP BY p.product_id , p.product_name , p.category
ORDER BY return_rate_pct DESC
LIMIT 10;

-- Q9: Return reasons breakdown
SELECT
    reason,
    COUNT(*)                                              AS return_count,
    ROUND(AVG(refund_amount), 2)                          AS avg_refund,
    ROUND(SUM(refund_amount), 2)                          AS total_refunded,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)   AS pct_of_returns
FROM returns
GROUP BY reason
ORDER BY return_count DESC;

-- Q10: Loyalty tier analysis
SELECT 
    u.loyalty_tier,
    COUNT(DISTINCT u.user_id) AS customer_count,
    ROUND(AVG(u.total_spent), 2) AS avg_lifetime_value,
    ROUND(AVG(u.age), 1) AS avg_age,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM
    users u
        LEFT JOIN
    orders o ON u.user_id = o.user_id
        AND o.status NOT IN ('Cancelled')
GROUP BY u.loyalty_tier
ORDER BY avg_lifetime_value DESC;

-- Q11: Monthly revenue trend
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(total_amount), 2) AS monthly_revenue,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(SUM(discount_amount), 2) AS total_discounts
FROM
    orders
WHERE
    status NOT IN ('Cancelled')
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

-- Q12: City-wise distribution
SELECT 
    city,
    COUNT(order_id) AS total_orders,
    COUNT(DISTINCT user_id) AS unique_customers,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_order_value
FROM
    orders
WHERE
    status NOT IN ('Cancelled')
GROUP BY city
ORDER BY total_revenue DESC;

-- Q13: Repeat vs one-time buyers
SELECT 
    buyer_type,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(AVG(total_spent), 2) AS avg_spent
FROM
    (SELECT 
        u.user_id,
            COUNT(o.order_id) AS total_orders,
            SUM(o.total_amount) AS total_spent,
            CASE
                WHEN COUNT(o.order_id) > 1 THEN 'Repeat Buyer'
                ELSE 'One-Time Buyer'
            END AS buyer_type
    FROM
        users u
    LEFT JOIN orders o ON u.user_id = o.user_id
        AND o.status NOT IN ('Cancelled')
    GROUP BY u.user_id) buyer_summary
GROUP BY buyer_type;

-- Q14: Coupon usage impact
SELECT 
    CASE
        WHEN coupon_code IS NOT NULL THEN 'With Coupon'
        ELSE 'Without Coupon'
    END AS coupon_used,
    COUNT(order_id) AS order_count,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(discount_amount), 2) AS avg_discount
FROM
    orders
WHERE
    status NOT IN ('Cancelled')
GROUP BY coupon_used;

-- Q15: Full customer 360 view
SELECT 
    u.user_id,
    u.full_name,
    u.city,
    u.loyalty_tier,
    u.age,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS lifetime_value,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value,
    COUNT(DISTINCT rv.review_id) AS reviews_written,
    ROUND(AVG(rv.rating), 2) AS avg_rating_given,
    COUNT(DISTINCT rt.return_id) AS total_returns,
    CAST(MAX(o.order_date) AS DATE) AS last_order_date
FROM
    users u
        LEFT JOIN
    orders o ON u.user_id = o.user_id
        AND o.status != 'Cancelled'
        LEFT JOIN
    reviews rv ON u.user_id = rv.user_id
        LEFT JOIN
    returns rt ON u.user_id = rt.user_id
GROUP BY u.user_id , u.full_name , u.city , u.loyalty_tier , u.age
ORDER BY lifetime_value DESC;

-- Q16: Customers placing 2nd order
WITH order_ranked AS (
    SELECT
        o.order_id,
        o.user_id,
        u.full_name,
        u.email,
        u.city,
        u.loyalty_tier,
        o.order_date,
        o.total_amount,
        o.status,
        ROW_NUMBER() OVER (
            PARTITION BY o.user_id
            ORDER BY o.order_date ASC
        ) AS visit_rank
    FROM orders o
    JOIN users u ON o.user_id = u.user_id
)
SELECT
    order_id,
    user_id,
    full_name,
    email,
    city,
    loyalty_tier,
    order_date    AS second_visit_date,
    total_amount  AS second_order_value,
    status
FROM order_ranked
WHERE visit_rank = 2
ORDER BY second_visit_date ASC;

-- Q16b: Days gap between 1st and 2nd visit
WITH order_ranked AS (
    SELECT
        o.user_id,
        u.full_name,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.user_id
            ORDER BY o.order_date ASC
        ) AS visit_rank
    FROM orders o
    JOIN users u ON o.user_id = u.user_id
),
first_visit AS (
    SELECT user_id, full_name,
           CAST(order_date AS DATE) AS first_order_date
    FROM order_ranked WHERE visit_rank = 1
),
second_visit AS (
    SELECT user_id,
           CAST(order_date AS DATE) AS second_order_date
    FROM order_ranked WHERE visit_rank = 2
)
SELECT
    fv.user_id,
    fv.full_name,
    fv.first_order_date,
    sv.second_order_date,
    DATEDIFF(sv.second_order_date, fv.first_order_date) AS days_between_visits
FROM first_visit  fv
JOIN second_visit sv ON fv.user_id = sv.user_id
ORDER BY days_between_visits ASC;

-- Q17: Days taken to return after delivery
SELECT 
    rt.return_id,
    rt.order_id,
    u.full_name,
    u.city,
    p.product_name,
    p.category,
    o.delivery_date,
    CAST(rt.return_date AS DATE) AS return_requested_date,
    rt.reason AS return_reason,
    rt.status AS return_status,
    rt.refund_amount,
    DATEDIFF(rt.return_date, o.delivery_date) AS days_to_return,
    CASE
        WHEN DATEDIFF(rt.return_date, o.delivery_date) <= 3 THEN 'Immediate (0-3 days)'
        WHEN DATEDIFF(rt.return_date, o.delivery_date) <= 7 THEN 'Within Week (4-7 days)'
        WHEN DATEDIFF(rt.return_date, o.delivery_date) <= 15 THEN 'Within Fortnight (8-15 days)'
        ELSE 'Late Return (15+ days)'
    END AS return_window_bucket
FROM
    returns rt
        JOIN
    orders o ON rt.order_id = o.order_id
        JOIN
    users u ON rt.user_id = u.user_id
        JOIN
    products p ON rt.product_id = p.product_id
WHERE
    o.delivery_date IS NOT NULL
ORDER BY days_to_return ASC;
OLIST E-COMMERCE ANALYTICS PIPELINE
-- Author: Favour Nnam
-- ANALYSIS VIEWS

USE olist_analytics_v2;
-- ============================================================
-- CREATE CLEAN ANALYTICAL BASE
-- Only delivered orders for accurate analysis
-- ============================================================

CREATE OR REPLACE VIEW clean_orders AS
SELECT *
FROM orders
WHERE order_status = 'delivered';

-- ============================================================
-- KPI SUMMARY (EXECUTIVE VIEW)
-- BUSINESS QUESTION: Overall delivery performance
-- ============================================================

CREATE OR REPLACE VIEW kpi_delivery_summary AS
SELECT 
    COUNT(*) AS total_orders,

    AVG(estimated_delivery_duration) AS avg_promised_days,
    AVG(total_delivery_duration) AS avg_actual_days,
    AVG(delivery_delay) AS avg_delay_days,

    SUM(delivery_status = 'Late') AS late_orders,
    SUM(delivery_status = 'Late') / COUNT(*) * 100 AS late_rate_pct,

    SUM(delivery_status = 'On Time') AS ontime_orders,
    SUM(delivery_status = 'On Time') / COUNT(*) * 100 AS ontime_rate_pct,

    SUM(delivery_status = 'Early') AS early_orders,
    SUM(delivery_status = 'Early') / COUNT(*) * 100 AS early_rate_pct

FROM clean_orders;

-- ============================================================
-- MONTHLY ORDER TREND
-- BUSINESS QUESTION: How is demand changing over time?
-- ============================================================

CREATE OR REPLACE VIEW monthly_orders AS
SELECT 
    order_year,
    order_month,
    order_month_name,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_year, order_month, order_month_name
ORDER BY order_year, order_month;



-- ============================================================
-- DELIVERY PERFORMANCE OVER TIME
-- BUSINESS QUESTION: Is performance improving?
-- ============================================================

CREATE OR REPLACE VIEW monthly_delivery_performance AS
SELECT 
    order_year,
    order_month,
    
    COUNT(*) AS total_orders,
    AVG(total_delivery_duration) AS avg_delivery_days,
    AVG(delivery_delay) AS avg_delay_days,
    
    SUM(delivery_status = 'Late') / COUNT(*) * 100 AS late_rate_pct

FROM clean_orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;



-- ============================================================
-- BOTTLENECK ANALYSIS
-- BUSINESS QUESTION: Which stage causes delay?
-- ============================================================

CREATE OR REPLACE VIEW bottleneck_analysis AS
SELECT 
    delivery_status,
    COUNT(*) AS total_orders,
    
    AVG(approval_duration) AS avg_approval_days,
    AVG(dispatch_duration) AS avg_dispatch_days,
    AVG(shipping_duration) AS avg_shipping_days,
    AVG(total_delivery_duration) AS avg_total_days

FROM clean_orders
GROUP BY delivery_status;



-- ============================================================
-- VOLUME VS DELIVERY PERFORMANCE
-- BUSINESS QUESTION: Does order volume affect delivery time?
-- ============================================================

CREATE OR REPLACE VIEW volume_vs_delivery AS
SELECT 
    order_year,
    order_month,
    COUNT(*) AS total_orders,
    
    AVG(total_delivery_duration) AS avg_delivery_days,
    AVG(delivery_delay) AS avg_delay_days,
    
    SUM(delivery_status = 'Late') / COUNT(*) * 100 AS late_rate_pct

FROM clean_orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;



-- ============================================================
-- SELLER PERFORMANCE BASE
-- BUSINESS QUESTION: Which sellers perform poorly?
-- ============================================================

CREATE OR REPLACE VIEW seller_performance_detailed AS
SELECT 
    oi.seller_id,
    s.seller_city,
    s.seller_state,

    COUNT(*) AS total_orders,
    
    AVG(o.total_delivery_duration) AS avg_delivery_days,
    AVG(o.delivery_delay) AS avg_delay_days,
    
    SUM(o.delivery_status = 'Late') / COUNT(*) * 100 AS late_rate_pct

FROM order_items oi
JOIN clean_orders o ON oi.order_id = o.order_id
JOIN sellers s ON oi.seller_id = s.seller_id

GROUP BY oi.seller_id, s.seller_city, s.seller_state;



-- ============================================================
-- ADD VOLUME SEGMENTATION
-- ============================================================

CREATE OR REPLACE VIEW seller_performance_with_volume AS
SELECT *,
CASE 
    WHEN total_orders < 50 THEN 'Low Volume'
    WHEN total_orders BETWEEN 50 AND 200 THEN 'Medium Volume'
    ELSE 'High Volume'
END AS volume_category
FROM seller_performance_detailed;



-- ============================================================
-- POOR PERFORMERS
-- BUSINESS QUESTION: Identify problematic sellers
-- ============================================================

CREATE OR REPLACE VIEW poor_sellers AS
SELECT *
FROM seller_performance_with_volume
WHERE late_rate_pct > 30
   OR avg_delay_days > 5;



-- ============================================================
-- CUSTOMER EXPERIENCE (REVIEWS)
-- BUSINESS QUESTION: Do delays affect reviews?
-- ============================================================

CREATE OR REPLACE VIEW delivery_vs_reviews AS
SELECT 
    o.delivery_status,
    COUNT(*) AS total_orders,
    AVG(r.review_score) AS avg_review_score

FROM clean_orders o
JOIN reviews r ON o.order_id = r.order_id

GROUP BY o.delivery_status;



-- ============================================================
-- DELIVERY ESTIMATE ACCURACY
-- BUSINESS QUESTION: Are we promising correctly?
-- ============================================================

CREATE OR REPLACE VIEW delivery_accuracy AS
SELECT 
    COUNT(*) AS total_orders,
    AVG(delivery_delay) AS avg_delay,
    
    SUM(delivery_delay > 0) / COUNT(*) * 100 AS late_pct,
    SUM(delivery_delay <= 0) / COUNT(*) * 100 AS ontime_or_early_pct

FROM clean_orders;



-- ============================================================
-- LOCATION IMPACT ANALYSIS
-- BUSINESS QUESTION: Does location affect performance?
-- ============================================================

CREATE OR REPLACE VIEW location_performance AS
SELECT 
    s.seller_state,
    COUNT(*) AS total_orders,
    
    AVG(o.total_delivery_duration) AS avg_delivery_days,
    AVG(o.delivery_delay) AS avg_delay_days,
    
    SUM(o.delivery_status = 'Late') / COUNT(*) * 100 AS late_rate_pct

FROM order_items oi
JOIN clean_orders o ON oi.order_id = o.order_id
JOIN sellers s ON oi.seller_id = s.seller_id

GROUP BY s.seller_state
ORDER BY avg_delay_days DESC;



-- ============================================================
-- END OF ANALYSIS
-- ============================================================
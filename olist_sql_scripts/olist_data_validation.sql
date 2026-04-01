OLIST E-COMMERCE ANALYTICS PIPELINE
-- Author: Favour Nnam
-- Validation, and sanity check of database schema

USE olist_analytics_v2;

-- ============================================================
-- 1. ROW COUNT CHECK
-- ============================================================

SELECT COUNT(*) AS total_orders FROM orders;

-- ============================================================
-- 2. NULL CHECKS (CRITICAL FIELDS)
-- ============================================================

SELECT 
COUNT(*) - COUNT(order_id) AS null_order_id,
COUNT(*) - COUNT(order_purchase_timestamp) AS null_purchase_date
FROM orders;

-- ============================================================
-- 3. DATETIME VALIDATION
-- ============================================================

SELECT 
COUNT(order_purchase_timestamp) AS purchase_valid,
COUNT(order_approved_at) AS approved_valid,
COUNT(order_delivered_customer_date) AS delivered_valid
FROM orders;

-- ============================================================
-- 4. DUPLICATE CHECK
-- ============================================================

SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- ============================================================
-- 5. NEGATIVE DURATION CHECK
-- ============================================================

SELECT *
FROM orders
WHERE total_delivery_duration < 0;

-- ============================================================
-- 6. LOGICAL CONSISTENCY CHECK
-- ============================================================

SELECT *
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- ============================================================
-- 7. FEATURE VALIDATION
-- ============================================================

SELECT 
COUNT(*) AS total,
COUNT(order_delivered_customer_date) AS delivered,
COUNT(total_delivery_duration) AS duration_filled
FROM orders;

-- ============================================================
-- 8. UNDELIVERED ORDER CHECK
-- ============================================================

SELECT *
FROM orders
WHERE order_delivered_customer_date IS NULL
LIMIT 20;

-- ============================================================
-- 9. REFERENTIAL INTEGRITY CHECKS
-- ============================================================

-- Orders without valid customers
SELECT COUNT(*) AS missing_customers
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items without matching orders
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Payments without orders
SELECT COUNT(*) AS orphan_payments
FROM payments p
LEFT JOIN orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Reviews without orders
SELECT COUNT(*) AS orphan_reviews
FROM reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 10. VALUE RANGE CHECKS
-- ============================================================

-- Invalid price or freight
SELECT COUNT(*) AS invalid_price
FROM order_items
WHERE price <= 0 OR freight_value < 0;

-- Unrealistic delivery durations (> 100 days)
SELECT COUNT(*) AS extreme_delivery_time
FROM orders
WHERE total_delivery_duration > 100;


-- ============================================================
-- 11. BUSINESS LOGIC VALIDATION
-- ============================================================

-- Late deliveries must have positive delay
SELECT COUNT(*) AS inconsistent_late_orders
FROM orders
WHERE delivery_status = 'Late'
AND delivery_delay <= 0;

-- Early deliveries must have negative delay
SELECT COUNT(*) AS inconsistent_early_orders
FROM orders
WHERE delivery_status = 'Early'
AND delivery_delay >= 0;

-- Pending orders should not have delivery duration
SELECT COUNT(*) AS invalid_pending_orders
FROM orders
WHERE delivery_status = 'Pending'
AND total_delivery_duration IS NOT NULL;


-- ============================================================
-- 12. PERCENTAGE VALIDATION
-- ============================================================

-- Percentages should sum close to 100%
SELECT COUNT(*) AS invalid_percentage_split
FROM orders
WHERE total_delivery_duration IS NOT NULL
AND (
    approval_pct_of_total + dispatch_pct_of_total + shipping_pct_of_total NOT BETWEEN 99 AND 101
);

-- Estimated percentage validation
SELECT COUNT(*) AS invalid_estimated_percentage
FROM orders
WHERE estimated_delivery_duration IS NOT NULL
AND (
    approval_pct_of_estimated + dispatch_pct_of_estimated + shipping_pct_of_estimated NOT BETWEEN 99 AND 101
);


-- ============================================================

-- ============================================================
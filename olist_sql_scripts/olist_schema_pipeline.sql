 ============================================================
-- OLIST E-COMMERCE ANALYTICS PIPELINE
-- Author: Favour Nnam
-- Covers: Schema, Loading, Cleaning, Feature Engineering,

-- ============================================================

CREATE DATABASE IF NOT EXISTS olist_analytics_v2;
USE olist_analytics_v2;

-- ============================================================
-- 0. SAFE SETTINGS
-- ============================================================

SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. CORE TABLES 
-- ============================================================

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(50),
    customer_state VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(50),
    seller_state VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,
    product_volume_cm3 INT
);

CREATE TABLE IF NOT EXISTS category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),

    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,

    approval_duration DECIMAL(10,2),
    dispatch_duration DECIMAL(10,2),
    shipping_duration DECIMAL(10,2),
    total_delivery_duration DECIMAL(10,2),
    estimated_delivery_duration DECIMAL(10,2),
    delivery_delay DECIMAL(10,2),
    delivery_status VARCHAR(20),

    approval_pct_of_total DECIMAL(10,2),
    dispatch_pct_of_total DECIMAL(10,2),
    shipping_pct_of_total DECIMAL(10,2),

    approval_pct_of_estimated DECIMAL(10,2),
    dispatch_pct_of_estimated DECIMAL(10,2),
    shipping_pct_of_estimated DECIMAL(10,2),

    order_year INT,
    order_month INT,
    order_day_name VARCHAR(15),
    order_month_name VARCHAR(15),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id, order_id)
);

-- ============================================================
-- 2. CLEAN RELOAD (IMPORTANT)
-- ============================================================

TRUNCATE TABLE order_items;
TRUNCATE TABLE payments;
TRUNCATE TABLE reviews;
TRUNCATE TABLE orders;
TRUNCATE TABLE customers;
TRUNCATE TABLE sellers;
TRUNCATE TABLE products;
TRUNCATE TABLE category_translation;

-- ============================================================
-- 3. LOAD SIMPLE TABLES (NO DATE ISSUES)
-- ============================================================

LOAD DATA LOCAL INFILE 'C:/Users/Owner/Downloads/OLIST FILES/olist_cleaned_data/customers_cleaned.csv'
INTO TABLE customers FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/Owner/Downloads/OLIST FILES/olist_cleaned_data/sellers_cleaned.csv'
INTO TABLE sellers FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/Owner/Downloads/OLIST FILES/olist_cleaned_data/products_cleaned.csv'
INTO TABLE products FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/Owner/Downloads/OLIST FILES/olist_cleaned_data/category_transl_cleaned.csv'
INTO TABLE category_translation FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- ============================================================
-- 4. ORDERS (STAGING FOR DATETIME FIX)
-- ============================================================

CREATE TABLE orders_temp LIKE orders;

ALTER TABLE orders_temp 
MODIFY order_purchase_timestamp VARCHAR(50),
MODIFY order_approved_at VARCHAR(50),
MODIFY order_delivered_carrier_date VARCHAR(50),
MODIFY order_delivered_customer_date VARCHAR(50),
MODIFY order_estimated_delivery_date VARCHAR(50);

LOAD DATA LOCAL INFILE 'C:/Users/Owner/Downloads/OLIST FILES/olist_cleaned_data/olist_orders_cleaned.csv'
INTO TABLE orders_temp FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

INSERT INTO orders (
    order_id, customer_id, order_status,
    order_purchase_timestamp, order_approved_at,
    order_delivered_carrier_date, order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    order_id, customer_id, order_status,

    STR_TO_DATE(NULLIF(order_purchase_timestamp,''),'%m/%d/%Y %H:%i'),
    STR_TO_DATE(NULLIF(order_approved_at,''),'%m/%d/%Y %H:%i'),
    STR_TO_DATE(NULLIF(order_delivered_carrier_date,''),'%m/%d/%Y %H:%i'),
    STR_TO_DATE(NULLIF(order_delivered_customer_date,''),'%m/%d/%Y %H:%i'),
    STR_TO_DATE(NULLIF(order_estimated_delivery_date,''),'%m/%d/%Y %H:%i')

FROM orders_temp;

DROP TABLE orders_temp;

-- ============================================================
-- 5. FEATURE ENGINEERING (FULLY CALCULATED)
-- ============================================================

UPDATE orders
SET 
approval_duration = TIMESTAMPDIFF(HOUR, order_purchase_timestamp, order_approved_at)/24,
dispatch_duration = TIMESTAMPDIFF(HOUR, order_approved_at, order_delivered_carrier_date)/24,
shipping_duration = TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_delivered_customer_date)/24,

total_delivery_duration = TIMESTAMPDIFF(HOUR, order_purchase_timestamp, order_delivered_customer_date)/24,
estimated_delivery_duration = TIMESTAMPDIFF(HOUR, order_purchase_timestamp, order_estimated_delivery_date)/24,

delivery_delay = TIMESTAMPDIFF(HOUR, order_estimated_delivery_date, order_delivered_customer_date)/24,

delivery_status = CASE
    WHEN delivery_delay > 0 THEN 'Late'
    WHEN delivery_delay = 0 THEN 'On Time'
    ELSE 'Early'
END,

order_year = YEAR(order_purchase_timestamp),
order_month = MONTH(order_purchase_timestamp),
order_day_name = DAYNAME(order_purchase_timestamp),
order_month_name = MONTHNAME(order_purchase_timestamp),

approval_pct_of_total = (approval_duration / total_delivery_duration)*100,
dispatch_pct_of_total = (dispatch_duration / total_delivery_duration)*100,
shipping_pct_of_total = (shipping_duration / total_delivery_duration)*100,

approval_pct_of_estimated = (approval_duration / estimated_delivery_duration)*100,
dispatch_pct_of_estimated = (dispatch_duration / estimated_delivery_duration)*100,
shipping_pct_of_estimated = (shipping_duration / estimated_delivery_duration)*100;

-- ============================================================
-- END OF PIPELINE
-- ============================================================

SET FOREIGN_KEY_CHECKS = 1;

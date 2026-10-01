{{ config(materialized='table') }}

WITH items_agg AS (

    SELECT
        order_id,
        SUM(price) AS order_total_value,
        SUM(freight_value) AS order_total_freight,
        COUNT(*) AS order_item_count
    FROM {{ ref('silver_order_items') }}
    GROUP BY 1

),

payments_agg AS (

    SELECT
        order_id,
        SUM(payment_value) AS order_total_paid,
        COUNT(DISTINCT payment_type) AS payment_methods_count
    FROM {{ ref('silver_order_payments') }}
    GROUP BY 1

),

reviews_agg AS (

    SELECT
        order_id,
        AVG(review_score) AS avg_review_score,
        COUNT(*) AS review_count
    FROM {{ ref('silver_order_reviews') }}
    GROUP BY 1

)

SELECT
    orders.order_id,
    orders.customer_id,
    orders.order_status,
    orders.order_purchase_timestamp,
    orders.order_approved_at,
    orders.order_delivered_carrier_date,
    orders.order_delivered_customer_date,
    orders.order_estimated_delivery_date,

    TIMESTAMP_DIFF(orders.order_delivered_customer_date, orders.order_purchase_timestamp, DAY) AS delivery_time_days,
    TIMESTAMP_DIFF(orders.order_approved_at, orders.order_purchase_timestamp, DAY) AS approval_delay_days,
    orders.order_delivered_customer_date > orders.order_estimated_delivery_date AS is_delivered_late,

    items_agg.order_total_value,
    items_agg.order_total_freight,
    items_agg.order_item_count,

    payments_agg.order_total_paid,
    payments_agg.payment_methods_count,

    reviews_agg.avg_review_score,
    reviews_agg.review_count

FROM {{ ref('bronze_orders') }} AS orders
LEFT JOIN items_agg ON items_agg.order_id = orders.order_id
LEFT JOIN payments_agg ON payments_agg.order_id = orders.order_id
LEFT JOIN reviews_agg ON reviews_agg.order_id = orders.order_id

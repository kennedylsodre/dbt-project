{{ config(materialized='table') }}

WITH items_agg AS (

    SELECT
        seller_id,
        COUNT(*) AS total_items_sold,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(price) AS total_revenue
    FROM {{ ref('silver_order_items') }}
    GROUP BY 1

),

seller_orders AS (

    SELECT DISTINCT
        seller_id,
        order_id
    FROM {{ ref('silver_order_items') }}

),

orders_agg AS (

    SELECT
        seller_orders.seller_id,
        AVG(orders.avg_review_score) AS avg_review_score,
        AVG(CAST(orders.is_delivered_late AS {{ dbt.type_int() }})) AS late_delivery_rate
    FROM seller_orders
    INNER JOIN {{ ref('silver_orders') }} AS orders
        ON orders.order_id = seller_orders.order_id
    GROUP BY 1

)

SELECT
    sellers.seller_id,
    sellers.seller_city,
    sellers.seller_state,
    sellers.seller_lat,
    sellers.seller_lng,
    COALESCE(items_agg.total_items_sold, 0) AS total_items_sold,
    COALESCE(items_agg.total_orders, 0) AS total_orders,
    COALESCE(items_agg.total_revenue, 0) AS total_revenue,
    orders_agg.avg_review_score,
    orders_agg.late_delivery_rate
FROM {{ ref('silver_sellers') }} AS sellers
LEFT JOIN items_agg
    ON items_agg.seller_id = sellers.seller_id
LEFT JOIN orders_agg
    ON orders_agg.seller_id = sellers.seller_id

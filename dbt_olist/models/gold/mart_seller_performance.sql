{{ config(materialized='table') }}

WITH seller_orders AS (

    SELECT DISTINCT
        seller_id,
        order_id
    FROM {{ ref('fct_order_items') }}

),

delivery_agg AS (

    SELECT
        seller_orders.seller_id,
        AVG(orders.delivery_time_days) AS avg_delivery_time_days
    FROM seller_orders
    INNER JOIN {{ ref('fct_orders') }} AS orders
        ON orders.order_id = seller_orders.order_id
    GROUP BY 1

)

SELECT
    sellers.seller_id,
    sellers.seller_city,
    sellers.seller_state,
    sellers.total_revenue,
    sellers.total_orders,
    sellers.total_items_sold,
    SAFE_DIVIDE(sellers.total_revenue, sellers.total_orders) AS avg_ticket,
    sellers.avg_review_score,
    sellers.late_delivery_rate,
    delivery_agg.avg_delivery_time_days,
    RANK() OVER (
        PARTITION BY sellers.seller_state
        ORDER BY sellers.total_revenue DESC
    ) AS revenue_rank_in_state
FROM {{ ref('dim_sellers') }} AS sellers
LEFT JOIN delivery_agg
    ON delivery_agg.seller_id = sellers.seller_id

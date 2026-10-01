{{ config(materialized='table') }}

SELECT
    order_items.order_id,
    order_items.order_item_id,
    order_items.product_id,
    order_items.seller_id,
    order_items.shipping_limit_date,
    order_items.price,
    order_items.freight_value,
    order_items.price + order_items.freight_value AS item_total_value,
    sellers.seller_state
FROM {{ ref('bronze_order_items') }} AS order_items
LEFT JOIN {{ ref('silver_sellers') }} AS sellers
    ON sellers.seller_id = order_items.seller_id

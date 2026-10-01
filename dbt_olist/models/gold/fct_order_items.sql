{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['order_id', 'order_item_id'],
    partition_by={'field': 'order_date', 'data_type': 'date'}
) }}

SELECT
    order_items.order_id,
    order_items.order_item_id,
    order_items.product_id,
    order_items.seller_id,
    customers.customer_unique_id,
    customers.customer_state,
    DATE(orders.order_purchase_timestamp) AS order_date,
    orders.order_status,

    order_items.shipping_limit_date,
    order_items.price,
    order_items.freight_value,
    order_items.item_total_value,

    orders.is_delivered_late,
    orders.avg_review_score AS order_review_score
FROM {{ ref('silver_order_items') }} AS order_items
INNER JOIN {{ ref('silver_orders') }} AS orders
    ON orders.order_id = order_items.order_id
LEFT JOIN {{ ref('silver_customers') }} AS customers
    ON customers.customer_id = orders.customer_id

{% if is_incremental() %}
-- reprocessa os últimos 7 dias para capturar mudanças de status e reviews tardias
WHERE DATE(orders.order_purchase_timestamp) >= (
    SELECT DATE_SUB(MAX(order_date), INTERVAL 7 DAY) FROM {{ this }}
)
{% endif %}

{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['order_id', 'order_item_id'],
    partition_by={'field': 'order_date', 'data_type': 'date'}
) }}

select
    order_items.order_id,
    order_items.order_item_id,
    order_items.product_id,
    order_items.seller_id,
    customers.customer_unique_id,
    customers.customer_state,
    date(orders.order_purchase_timestamp) as order_date,
    orders.order_status,

    order_items.shipping_limit_date,
    order_items.price,
    order_items.freight_value,
    order_items.item_total_value,

    orders.is_delivered_late,
    orders.avg_review_score as order_review_score
from {{ ref('silver_order_items') }} as order_items
inner join {{ ref('silver_orders') }} as orders
    on orders.order_id = order_items.order_id
left join {{ ref('silver_customers') }} as customers
    on customers.customer_id = orders.customer_id

{% if is_incremental() %}
-- reprocessa os últimos 7 dias para capturar mudanças de status e reviews tardias
where date(orders.order_purchase_timestamp) >= (
    select date_sub(max(order_date), interval 7 day) from {{ this }}
)
{% endif %}

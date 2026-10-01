{{ config(materialized='table') }}

select
    order_items.order_id,
    order_items.order_item_id,
    order_items.product_id,
    order_items.seller_id,
    order_items.shipping_limit_date,
    order_items.price,
    order_items.freight_value,
    order_items.price + order_items.freight_value as item_total_value,
    sellers.seller_state
from {{ ref('bronze_order_items') }} as order_items
left join {{ ref('silver_sellers') }} as sellers
    on sellers.seller_id = order_items.seller_id

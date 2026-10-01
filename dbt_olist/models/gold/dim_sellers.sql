{{ config(materialized='table') }}

with items_agg as (

    select
        seller_id,
        count(*) as total_items_sold,
        count(distinct order_id) as total_orders,
        sum(price) as total_revenue
    from {{ ref('silver_order_items') }}
    group by 1

),

seller_orders as (

    select distinct
        seller_id,
        order_id
    from {{ ref('silver_order_items') }}

),

orders_agg as (

    select
        seller_orders.seller_id,
        avg(orders.avg_review_score) as avg_review_score,
        avg(cast(orders.is_delivered_late as {{ dbt.type_int() }})) as late_delivery_rate
    from seller_orders
    inner join {{ ref('silver_orders') }} as orders
        on orders.order_id = seller_orders.order_id
    group by 1

)

select
    sellers.seller_id,
    sellers.seller_city,
    sellers.seller_state,
    sellers.seller_lat,
    sellers.seller_lng,
    coalesce(items_agg.total_items_sold, 0) as total_items_sold,
    coalesce(items_agg.total_orders, 0) as total_orders,
    coalesce(items_agg.total_revenue, 0) as total_revenue,
    orders_agg.avg_review_score,
    orders_agg.late_delivery_rate
from {{ ref('silver_sellers') }} as sellers
left join items_agg
    on items_agg.seller_id = sellers.seller_id
left join orders_agg
    on orders_agg.seller_id = sellers.seller_id

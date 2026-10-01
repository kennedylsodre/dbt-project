{{ config(materialized='table') }}

with seller_orders as (

    select distinct
        seller_id,
        order_id
    from {{ ref('fct_order_items') }}

),

delivery_agg as (

    select
        seller_orders.seller_id,
        avg(orders.delivery_time_days) as avg_delivery_time_days
    from seller_orders
    inner join {{ ref('fct_orders') }} as orders
        on orders.order_id = seller_orders.order_id
    group by 1

)

select
    sellers.seller_id,
    sellers.seller_city,
    sellers.seller_state,
    sellers.total_revenue,
    sellers.total_orders,
    sellers.total_items_sold,
    safe_divide(sellers.total_revenue, sellers.total_orders) as avg_ticket,
    sellers.avg_review_score,
    sellers.late_delivery_rate,
    delivery_agg.avg_delivery_time_days,
    rank() over (
        partition by sellers.seller_state
        order by sellers.total_revenue desc
    ) as revenue_rank_in_state
from {{ ref('dim_sellers') }} as sellers
left join delivery_agg
    on delivery_agg.seller_id = sellers.seller_id

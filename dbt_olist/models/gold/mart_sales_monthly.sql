{{ config(materialized='table') }}

select
    dates.year_month,
    items.customer_state,
    products.product_category_name,
    count(distinct items.order_id) as total_orders,
    count(*) as total_items,
    sum(items.price) as total_revenue,
    sum(items.freight_value) as total_freight,
    safe_divide(sum(items.price), count(distinct items.order_id)) as avg_ticket
from {{ ref('fct_order_items') }} as items
inner join {{ ref('dim_date') }} as dates
    on dates.date_day = items.order_date
left join {{ ref('dim_products') }} as products
    on products.product_id = items.product_id
group by 1, 2, 3

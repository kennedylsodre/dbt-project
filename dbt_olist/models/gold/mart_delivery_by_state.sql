{{ config(materialized='table') }}

select
    orders.customer_state,
    dates.year_month,
    count(*) as total_delivered_orders,
    avg(orders.delivery_time_days) as avg_delivery_time_days,
    avg(orders.estimated_delivery_days) as avg_estimated_delivery_days,
    avg(cast(orders.is_delivered_late as {{ dbt.type_int() }})) as late_delivery_rate,
    avg(orders.order_total_freight) as avg_freight
from {{ ref('fct_orders') }} as orders
inner join {{ ref('dim_date') }} as dates
    on dates.date_day = orders.order_date
where orders.order_status = 'delivered'
    and orders.order_delivered_customer_date is not null
group by 1, 2

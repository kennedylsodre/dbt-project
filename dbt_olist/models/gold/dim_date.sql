with bounds as (

    select
        min(date(order_purchase_timestamp)) as min_date,
        max(date(greatest(
            order_purchase_timestamp,
            coalesce(order_delivered_customer_date, order_purchase_timestamp),
            coalesce(order_estimated_delivery_date, order_purchase_timestamp)
        ))) as max_date
    from {{ ref('silver_orders') }}

),

dates as (

    select date_day
    from bounds
    cross join unnest(generate_date_array(bounds.min_date, bounds.max_date)) as date_day

)

select
    date_day,
    extract(year from date_day) as year,
    extract(quarter from date_day) as quarter,
    extract(month from date_day) as month,
    format_date('%B', date_day) as month_name,
    format_date('%Y-%m', date_day) as year_month,
    extract(dayofweek from date_day) as day_of_week,
    format_date('%A', date_day) as day_name,
    extract(dayofweek from date_day) in (1, 7) as is_weekend
from dates

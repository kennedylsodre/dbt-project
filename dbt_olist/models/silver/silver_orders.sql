{{ config(materialized='table') }}

with items_agg as (

    select
        order_id,
        sum(price) as order_total_value,
        sum(freight_value) as order_total_freight,
        count(*) as order_item_count
    from {{ ref('bronze_order_items') }}
    group by 1

),

payments_agg as (

    select
        order_id,
        sum(payment_value) as order_total_paid,
        count(distinct payment_type) as payment_methods_count
    from {{ ref('bronze_order_payments') }}
    group by 1

),

reviews_agg as (

    select
        order_id,
        avg(review_score) as avg_review_score,
        count(*) as review_count
    from {{ ref('bronze_order_reviews') }}
    group by 1

)

select
    orders.order_id,
    orders.customer_id,
    orders.order_status,
    orders.order_purchase_timestamp,
    orders.order_approved_at,
    orders.order_delivered_carrier_date,
    orders.order_delivered_customer_date,
    orders.order_estimated_delivery_date,

    timestamp_diff(orders.order_delivered_customer_date, orders.order_purchase_timestamp, day) as delivery_time_days,
    timestamp_diff(orders.order_approved_at, orders.order_purchase_timestamp, day) as approval_delay_days,
    orders.order_delivered_customer_date > orders.order_estimated_delivery_date as is_delivered_late,

    items_agg.order_total_value,
    items_agg.order_total_freight,
    items_agg.order_item_count,

    payments_agg.order_total_paid,
    payments_agg.payment_methods_count,

    reviews_agg.avg_review_score,
    reviews_agg.review_count

from {{ ref('bronze_orders') }} as orders
left join items_agg on items_agg.order_id = orders.order_id
left join payments_agg on payments_agg.order_id = orders.order_id
left join reviews_agg on reviews_agg.order_id = orders.order_id

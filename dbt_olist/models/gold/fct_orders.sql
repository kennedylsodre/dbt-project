select
    orders.order_id,
    orders.customer_id,
    customers.customer_unique_id,
    customers.customer_state,
    date(orders.order_purchase_timestamp) as order_date,
    orders.order_status,

    orders.order_purchase_timestamp,
    orders.order_approved_at,
    orders.order_delivered_carrier_date,
    orders.order_delivered_customer_date,
    orders.order_estimated_delivery_date,

    orders.order_total_value,
    orders.order_total_freight,
    orders.order_total_paid,
    orders.order_item_count,
    orders.payment_methods_count,

    orders.delivery_time_days,
    timestamp_diff(orders.order_estimated_delivery_date, orders.order_purchase_timestamp, day) as estimated_delivery_days,
    orders.approval_delay_days,
    orders.is_delivered_late,

    orders.avg_review_score
from {{ ref('silver_orders') }} as orders
left join {{ ref('silver_customers') }} as customers
    on customers.customer_id = orders.customer_id

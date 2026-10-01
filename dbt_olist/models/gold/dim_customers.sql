with customer_orders as (

    select
        customers.customer_unique_id,
        customers.customer_city,
        customers.customer_state,
        customers.customer_lat,
        customers.customer_lng,
        orders.order_id,
        orders.order_purchase_timestamp,
        orders.order_total_paid,
        orders.avg_review_score
    from {{ ref('silver_customers') }} as customers
    inner join {{ ref('silver_orders') }} as orders
        on orders.customer_id = customers.customer_id

),

latest_address as (

    select
        customer_unique_id,
        customer_city,
        customer_state,
        customer_lat,
        customer_lng
    from customer_orders
    qualify row_number() over (
        partition by customer_unique_id
        order by order_purchase_timestamp desc
    ) = 1

),

customer_metrics as (

    select
        customer_unique_id,
        min(order_purchase_timestamp) as first_order_at,
        max(order_purchase_timestamp) as last_order_at,
        count(distinct order_id) as total_orders,
        coalesce(sum(order_total_paid), 0) as total_spent,
        avg(avg_review_score) as avg_review_score
    from customer_orders
    group by 1

)

select
    latest_address.customer_unique_id,
    latest_address.customer_city,
    latest_address.customer_state,
    latest_address.customer_lat,
    latest_address.customer_lng,
    customer_metrics.first_order_at,
    customer_metrics.last_order_at,
    customer_metrics.total_orders,
    customer_metrics.total_spent,
    customer_metrics.avg_review_score
from latest_address
inner join customer_metrics
    on customer_metrics.customer_unique_id = latest_address.customer_unique_id

{{ config(materialized='table') }}

WITH customer_orders AS (

    SELECT
        customers.customer_unique_id,
        customers.customer_city,
        customers.customer_state,
        customers.customer_lat,
        customers.customer_lng,
        orders.order_id,
        orders.order_purchase_timestamp,
        orders.order_total_paid,
        orders.avg_review_score
    FROM {{ ref('silver_customers') }} AS customers
    INNER JOIN {{ ref('silver_orders') }} AS orders
        ON orders.customer_id = customers.customer_id

),

latest_address AS (

    SELECT
        customer_unique_id,
        customer_city,
        customer_state,
        customer_lat,
        customer_lng
    FROM customer_orders
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY customer_unique_id
        ORDER BY order_purchase_timestamp DESC
    ) = 1

),

customer_metrics AS (

    SELECT
        customer_unique_id,
        MIN(order_purchase_timestamp) AS first_order_at,
        MAX(order_purchase_timestamp) AS last_order_at,
        COUNT(DISTINCT order_id) AS total_orders,
        COALESCE(SUM(order_total_paid), 0) AS total_spent,
        AVG(avg_review_score) AS avg_review_score
    FROM customer_orders
    GROUP BY 1

)

SELECT
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
FROM latest_address
INNER JOIN customer_metrics
    ON customer_metrics.customer_unique_id = latest_address.customer_unique_id

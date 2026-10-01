{{ config(materialized='table') }}

SELECT
    orders.customer_state,
    dates.year_month,
    COUNT(*) AS total_delivered_orders,
    AVG(orders.delivery_time_days) AS avg_delivery_time_days,
    AVG(orders.estimated_delivery_days) AS avg_estimated_delivery_days,
    AVG(CAST(orders.is_delivered_late AS {{ dbt.type_int() }})) AS late_delivery_rate,
    AVG(orders.order_total_freight) AS avg_freight
FROM {{ ref('fct_orders') }} AS orders
INNER JOIN {{ ref('dim_date') }} AS dates
    ON dates.date_day = orders.order_date
WHERE orders.order_status = 'delivered'
    AND orders.order_delivered_customer_date IS NOT NULL
GROUP BY 1, 2

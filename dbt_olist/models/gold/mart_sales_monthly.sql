{{ config(materialized='table') }}

SELECT
    dates.year_month,
    items.customer_state,
    products.product_category_name,
    COUNT(DISTINCT items.order_id) AS total_orders,
    COUNT(*) AS total_items,
    SUM(items.price) AS total_revenue,
    SUM(items.freight_value) AS total_freight,
    SAFE_DIVIDE(SUM(items.price), COUNT(DISTINCT items.order_id)) AS avg_ticket
FROM {{ ref('fct_order_items') }} AS items
INNER JOIN {{ ref('dim_date') }} AS dates
    ON dates.date_day = items.order_date
LEFT JOIN {{ ref('dim_products') }} AS products
    ON products.product_id = items.product_id
GROUP BY 1, 2, 3

{{ config(materialized='table') }}

WITH bounds AS (

    SELECT
        MIN(DATE(order_purchase_timestamp)) AS min_date,
        MAX(DATE(GREATEST(
            order_purchase_timestamp,
            COALESCE(order_delivered_customer_date, order_purchase_timestamp),
            COALESCE(order_estimated_delivery_date, order_purchase_timestamp)
        ))) AS max_date
    FROM {{ ref('silver_orders') }}

),

dates AS (

    SELECT date_day
    FROM bounds
    CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(bounds.min_date, bounds.max_date)) AS date_day

)

SELECT
    date_day,
    EXTRACT(YEAR FROM date_day) AS year,
    EXTRACT(QUARTER FROM date_day) AS quarter,
    EXTRACT(MONTH FROM date_day) AS month,
    FORMAT_DATE('%B', date_day) AS month_name,
    FORMAT_DATE('%Y-%m', date_day) AS year_month,
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
    FORMAT_DATE('%A', date_day) AS day_name,
    EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) AS is_weekend
FROM dates

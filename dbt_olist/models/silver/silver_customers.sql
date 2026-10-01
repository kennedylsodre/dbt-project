{{ config(materialized='table') }}

SELECT
    customers.customer_id,
    customers.customer_unique_id,
    customers.customer_zip_code_prefix,
    TRIM(LOWER(customers.customer_city)) AS customer_city,
    UPPER(customers.customer_state) AS customer_state,
    geolocation.geolocation_lat AS customer_lat,
    geolocation.geolocation_lng AS customer_lng
FROM {{ ref('bronze_customers') }} AS customers
LEFT JOIN {{ ref('silver_geolocation') }} AS geolocation
    ON geolocation.zip_code_prefix = customers.customer_zip_code_prefix

{{ config(materialized='table') }}

SELECT
    sellers.seller_id,
    sellers.seller_zip_code_prefix,
    TRIM(LOWER(sellers.seller_city)) AS seller_city,
    UPPER(sellers.seller_state) AS seller_state,
    geolocation.geolocation_lat AS seller_lat,
    geolocation.geolocation_lng AS seller_lng
FROM {{ ref('bronze_sellers') }} AS sellers
LEFT JOIN {{ ref('silver_geolocation') }} AS geolocation
    ON geolocation.zip_code_prefix = sellers.seller_zip_code_prefix

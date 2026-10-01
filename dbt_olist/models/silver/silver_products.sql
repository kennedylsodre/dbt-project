{{ config(materialized='table') }}

SELECT
    product_id,
    COALESCE(TRIM(LOWER(product_category_name)), 'not_informed') AS product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM {{ ref('bronze_products') }}


{{ config(materialized='view') }}

SELECT 
    product_id,
    product_category_name,
    CAST(product_name_lenght AS  {{ dbt.type_int() }}) product_name_lenght,
    CAST(product_description_lenght AS {{ dbt.type_int() }} ) product_description_lenght,
    CAST(product_photos_qty AS {{ dbt.type_int() }} ) product_photos_qty,
    CAST(product_weight_g AS {{ dbt.type_int() }} ) product_weight_g,
    CAST(product_length_cm AS {{ dbt.type_int() }} ) product_length_cm,
    CAST(product_height_cm AS {{ dbt.type_int() }} ) product_height_cm,
    CAST(product_width_cm AS {{ dbt.type_int() }} ) product_width_cm
FROM {{source('olist','raw_products')}}

{{ config(materialized='view') }}

SELECT 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM {{source('olist','raw_sellers')}}
{{ config(materialized='view') }}

SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    CAST(shipping_limit_date AS {{ dbt.type_timestamp() }}) shipping_limit_date,
    CAST(price AS {{dbt.type_float()}}) price,
    CAST(freight_value AS {{dbt.type_float()}}) freight_value
FROM {{source('olist','raw_order_items')}}



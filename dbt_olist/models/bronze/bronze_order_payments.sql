
{{ config(materialized='view') }}

SELECT 
    order_id,
    CAST(payment_sequential AS {{ dbt.type_int() }} ) payment_sequential,
    payment_type,
    CAST(payment_installments AS {{ dbt.type_int() }}) payment_installments ,
    CAST(payment_value AS {{dbt.type_float()}}) payment_value
FROM {{source('olist','raw_order_payments')}}
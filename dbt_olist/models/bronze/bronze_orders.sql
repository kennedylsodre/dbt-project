
{{ config(materialized='view') }}

SELECT 
    order_id,
    customer_id,
    order_status,
    CAST(order_purchase_timestamp AS {{ dbt.type_timestamp() }}) order_purchase_{{ dbt.type_timestamp() }},
    CAST(order_approved_at AS {{ dbt.type_timestamp() }}) order_approved_at,
    CAST(order_delivered_carrier_date AS {{ dbt.type_timestamp() }}) order_delivered_carrier_date,
    CAST(order_delivered_customer_date AS {{ dbt.type_timestamp() }}) order_delivered_customer_date,
    CAST(order_estimated_delivery_date AS {{ dbt.type_timestamp() }}) order_estimated_delivery_date

FROM {{source('olist','raw_orders')}}

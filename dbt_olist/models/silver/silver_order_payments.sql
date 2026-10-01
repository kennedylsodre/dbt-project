{{ config(materialized='table') }}

SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    payment_installments > 1 AS is_installment
FROM {{ ref('bronze_order_payments') }}

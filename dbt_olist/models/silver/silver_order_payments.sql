{{ config(materialized='table') }}

select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    payment_installments > 1 as is_installment
from {{ ref('bronze_order_payments') }}

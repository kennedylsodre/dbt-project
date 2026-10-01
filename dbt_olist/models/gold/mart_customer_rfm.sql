{{ config(materialized='table') }}

-- dataset é estático (termina em 2018): a recência é medida contra o último pedido do dataset, não contra hoje
with reference_date as (

    select max(date(last_order_at)) as ref_date
    from {{ ref('dim_customers') }}

),

rfm as (

    select
        customers.customer_unique_id,
        date_diff(reference_date.ref_date, date(customers.last_order_at), day) as recency_days,
        customers.total_orders as frequency,
        customers.total_spent as monetary
    from {{ ref('dim_customers') }} as customers
    cross join reference_date

),

scores as (

    select
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        ntile(5) over (order by recency_days desc) as r_score,
        -- ~97% dos clientes têm 1 pedido: ntile quebraria empates aleatoriamente, então usa escala linear (5+ pedidos = 5)
        least(frequency, 5) as f_score,
        ntile(5) over (order by monetary) as m_score
    from rfm

)

select
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    case
        when r_score >= 4 and f_score >= 2 then 'campeoes'
        when f_score >= 2 then 'fieis'
        when r_score >= 4 then 'recentes'
        when r_score <= 2 and m_score >= 4 then 'em_risco'
        when r_score <= 2 then 'perdidos'
        else 'ocasionais'
    end as rfm_segment
from scores

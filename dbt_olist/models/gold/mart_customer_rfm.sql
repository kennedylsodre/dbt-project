{{ config(materialized='table') }}

-- dataset é estático (termina em 2018): a recência é medida contra o último pedido do dataset, não contra hoje
WITH reference_date AS (

    SELECT MAX(DATE(last_order_at)) AS ref_date
    FROM {{ ref('dim_customers') }}

),

rfm AS (

    SELECT
        customers.customer_unique_id,
        DATE_DIFF(reference_date.ref_date, DATE(customers.last_order_at), DAY) AS recency_days,
        customers.total_orders AS frequency,
        customers.total_spent AS monetary
    FROM {{ ref('dim_customers') }} AS customers
    CROSS JOIN reference_date

),

scores AS (

    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        -- ~97% dos clientes têm 1 pedido: ntile quebraria empates aleatoriamente, então usa escala linear (5+ pedidos = 5)
        LEAST(frequency, 5) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm

)

SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 2 THEN 'campeoes'
        WHEN f_score >= 2 THEN 'fieis'
        WHEN r_score >= 4 THEN 'recentes'
        WHEN r_score <= 2 AND m_score >= 4 THEN 'em_risco'
        WHEN r_score <= 2 THEN 'perdidos'
        ELSE 'ocasionais'
    END AS rfm_segment
FROM scores

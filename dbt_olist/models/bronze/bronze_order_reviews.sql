{{ config(materialized='view') }}

SELECT
    review_id,
    order_id,
    CAST(review_score AS {{ dbt.type_int() }}) review_score,
    review_comment_title,
    review_comment_message,
    CAST(review_creation_date AS {{ dbt.type_timestamp() }}) review_creation_date,
    CAST(review_answer_timestamp AS {{ dbt.type_timestamp() }}) review_answer_timestamp
FROM {{ source('olist', 'raw_order_reviews') }}

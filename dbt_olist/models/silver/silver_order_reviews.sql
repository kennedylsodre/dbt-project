{{ config(materialized='table') }}

select
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
from {{ ref('bronze_order_reviews') }}
qualify row_number() over (
    partition by review_id
    order by review_answer_timestamp desc
) = 1

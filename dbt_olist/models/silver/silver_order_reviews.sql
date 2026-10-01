{{ config(materialized='table') }}

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM {{ ref('bronze_order_reviews') }}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY review_id
    ORDER BY review_answer_timestamp DESC
) = 1

SELECT order_id, order_item_id, COUNT(*)
FROM {{ ref('silver_order_items') }}
GROUP BY 1, 2
HAVING COUNT(*) > 1

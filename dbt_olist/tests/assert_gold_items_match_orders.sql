-- a soma de price dos itens deve bater com order_total_value do pedido
WITH items AS (

    SELECT
        order_id,
        SUM(price) AS items_total
    FROM {{ ref('fct_order_items') }}
    GROUP BY 1

)

SELECT
    orders.order_id,
    orders.order_total_value,
    items.items_total
FROM {{ ref('fct_orders') }} AS orders
INNER JOIN items
    ON items.order_id = orders.order_id
WHERE ABS(COALESCE(orders.order_total_value, 0) - items.items_total) > 0.01

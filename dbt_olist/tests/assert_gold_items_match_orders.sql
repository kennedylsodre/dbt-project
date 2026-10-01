-- a soma de price dos itens deve bater com order_total_value do pedido
with items as (

    select
        order_id,
        sum(price) as items_total
    from {{ ref('fct_order_items') }}
    group by 1

)

select
    orders.order_id,
    orders.order_total_value,
    items.items_total
from {{ ref('fct_orders') }} as orders
inner join items
    on items.order_id = orders.order_id
where abs(coalesce(orders.order_total_value, 0) - items.items_total) > 0.01

select order_id, order_item_id, count(*)
from {{ ref('silver_order_items') }}
group by 1, 2
having count(*) > 1

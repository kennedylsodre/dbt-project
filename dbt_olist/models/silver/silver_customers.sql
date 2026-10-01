{{ config(materialized='table') }}

select
    customers.customer_id,
    customers.customer_unique_id,
    customers.customer_zip_code_prefix,
    trim(lower(customers.customer_city)) as customer_city,
    upper(customers.customer_state) as customer_state,
    geolocation.geolocation_lat as customer_lat,
    geolocation.geolocation_lng as customer_lng
from {{ ref('bronze_customers') }} as customers
left join {{ ref('silver_geolocation') }} as geolocation
    on geolocation.zip_code_prefix = customers.customer_zip_code_prefix

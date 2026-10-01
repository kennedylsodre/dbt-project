{{ config(materialized='table') }}

select
    sellers.seller_id,
    sellers.seller_zip_code_prefix,
    trim(lower(sellers.seller_city)) as seller_city,
    upper(sellers.seller_state) as seller_state,
    geolocation.geolocation_lat as seller_lat,
    geolocation.geolocation_lng as seller_lng
from {{ ref('bronze_sellers') }} as sellers
left join {{ ref('silver_geolocation') }} as geolocation
    on geolocation.zip_code_prefix = sellers.seller_zip_code_prefix

{{ config(materialized='table') }}

with geolocation_coordinates as (

    select
        geolocation_zip_code_prefix as zip_code_prefix,
        avg(geolocation_lat) as geolocation_lat,
        avg(geolocation_lng) as geolocation_lng
    from {{ ref('bronze_geolocation') }}
    group by 1

),

geolocation_city_state as (

    select
        geolocation_zip_code_prefix as zip_code_prefix,
        geolocation_city,
        geolocation_state
    from {{ ref('bronze_geolocation') }}
    group by 1, 2, 3
    qualify row_number() over (
        partition by zip_code_prefix
        order by count(*) desc
    ) = 1

)

select
    geolocation_city_state.zip_code_prefix,
    geolocation_coordinates.geolocation_lat,
    geolocation_coordinates.geolocation_lng,
    trim(lower(geolocation_city_state.geolocation_city)) as geolocation_city,
    upper(geolocation_city_state.geolocation_state) as geolocation_state
from geolocation_city_state
inner join geolocation_coordinates
    on geolocation_coordinates.zip_code_prefix = geolocation_city_state.zip_code_prefix

{{ config(materialized='view') }}

SELECT 
    geolocation_zip_code_prefix,
    CAST(geolocation_lat AS {{dbt.type_float()}}) geolocation_lat,
    CAST(geolocation_lng AS {{dbt.type_float()}}) geolocation_lng,
    geolocation_city,
    geolocation_state
FROM {{source('olist','raw_geolocation')}}


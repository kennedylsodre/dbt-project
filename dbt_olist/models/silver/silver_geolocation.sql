{{ config(materialized='table') }}

WITH geolocation_coordinates AS (

    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        AVG(geolocation_lat) AS geolocation_lat,
        AVG(geolocation_lng) AS geolocation_lng
    FROM {{ ref('bronze_geolocation') }}
    GROUP BY 1

),

geolocation_city_state AS (

    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        geolocation_city,
        geolocation_state
    FROM {{ ref('bronze_geolocation') }}
    GROUP BY 1, 2, 3
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY zip_code_prefix
        ORDER BY COUNT(*) DESC
    ) = 1

)

SELECT
    geolocation_city_state.zip_code_prefix,
    geolocation_coordinates.geolocation_lat,
    geolocation_coordinates.geolocation_lng,
    TRIM(LOWER(geolocation_city_state.geolocation_city)) AS geolocation_city,
    UPPER(geolocation_city_state.geolocation_state) AS geolocation_state
FROM geolocation_city_state
INNER JOIN geolocation_coordinates
    ON geolocation_coordinates.zip_code_prefix = geolocation_city_state.zip_code_prefix

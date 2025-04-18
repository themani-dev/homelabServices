{{
    config(
        materialized='incremental',
        unique_key='incident_datetime',
        partition_by = {
            'field': 'incident_datetime',
            'data_type': 'timestamp'
        }
    )
}}



with core as(
        select incident_datetime from {{ ref('tbl_curated_crime') }}
        {% if is_incremental() %}
                where load_timestamp = (select max(load_timestamp) from {{ ref('tbl_curated_crime') }})
        {% endif %}
        union distinct
        select report_datetime from {{ ref('tbl_curated_crime') }}
        {% if is_incremental() %}
                where load_timestamp = (select max(load_timestamp) from {{ ref('tbl_curated_crime') }})
        {% endif %}
),
select incident_datetime as DateTime,
       EXTRACT(Year FROM incident_datetime) AS Year,
       EXTRACT(month FROM incident_datetime) AS Month,
       FORMAT_DATE('%d', DATE(incident_datetime)) AS Date,
       EXTRACT(WEEK FROM incident_datetime) AS week_number, 
       FORMAT_DATE('%A', incident_datetime) AS week_name,
       FORMAT_DATE('%B', incident_datetime) AS month_name,
from core

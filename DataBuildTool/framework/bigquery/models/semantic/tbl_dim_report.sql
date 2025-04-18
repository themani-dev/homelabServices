{{
    config(
        materialized='incremental',
        unique_key='incident_datetime'
    )
}}


select 
    report_type_code,
    report_type_description 
from {{ ref('tbl_curated_crime') }}
{% if is_incremental() %}
    where load_timestamp = (select max(load_timestamp) from {{ ref('tbl_curated_crime') }})
{% endif %}
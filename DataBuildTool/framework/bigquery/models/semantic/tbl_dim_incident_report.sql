{{
    config(
        materialized='incremental',
        tags=['incident_dim'],
        unique_key='incident_code'
    )
}}

select incident_code,
       incident_category,
       incident_subcategory,
       incident_description
from {{ ref('tbl_curated_crime') }}
{% if is_incremental() %}
    where load_timestamp = (select max(load_timestamp) from {{ ref('tbl_curated_crime') }})
{% endif %}
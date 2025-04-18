{{
    config(
        materialized='incremental',
        unique_key='incident_id',
        partition_by = {
            'field': 'load_timestamp',
            'data_type': 'timestamp'
        }
    )
}}


select
    PARSE_TIMESTAMP("%Y-%m-%dT%H:%M:%E*S",incident_datetime) as incident_datetime  ,
    PARSE_TIMESTAMP("%Y-%m-%dT%H:%M:%E*S",report_datetime) as report_datetime ,
    row_id ,
    incident_id ,
    cast(incident_number as integer) as incident_number,
    report_type_code ,
    report_type_description ,
    incident_code ,
    incident_category ,
    incident_subcategory ,
    incident_description ,
    resolution ,
    police_district ,
    filed_online ,
    cast(cad_number as integer) as cad_number,
    intersection ,
    cnn ,
    analysis_neighborhood ,
    supervisor_district ,
    supervisor_district_2012 ,
    latitude ,
    longitude ,
    point 
from {{ sources('raw','tbl_raw_crime')}}
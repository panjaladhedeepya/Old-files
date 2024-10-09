view: job_segment {
  sql_table_name: "DPA_SCHEMA"."JOB_SEGMENT_MATERIALIZED_PROD"
    ;;

  dimension: data_dict_version {
    type: string
    sql: ${TABLE}."data_dict_version" ;;
  }

  dimension: description {
    type: string
    sql: ${TABLE}."description" ;;
  }

  dimension: job_id {
    type: string
    sql: ${TABLE}."job_id" ;;
  }

  dimension: name {
    type: string
    sql: ${TABLE}."name" ;;
  }

  dimension: records {
    type: number
    sql: ${TABLE}."records" ;;
  }

  dimension: segment_name {
    type: string
    sql: ${TABLE}."segment_name" ;;
  }

  dimension: target_flg {
    type: number
    sql: ${TABLE}."target_flg" ;;
  }

  dimension: tenant_id {
    type: string
    sql: ${TABLE}."tenant_id" ;;
  }

  dimension: tenant_name {
    type: string
    sql: ${TABLE}."tenant_name" ;;
  }

  dimension: reference_version {
    type: string
    sql: ${TABLE}."reference_version" ;;
  }

  dimension_group: timestamp {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}."timestamp" ;;
  }

  measure: count {
    type: count
    drill_fields: [name, segment_name]
  }
}

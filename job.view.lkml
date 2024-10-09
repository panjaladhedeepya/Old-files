view: job {
  sql_table_name: "DPA_SCHEMA"."JOB"
    ;;
  drill_fields: [job_id]


  dimension: test {
    label: "dpa_tenant"
    sql: REPLACE({{ _user_attributes['dpa_tenant'] }},'') ;;
  }

  dimension: test2 {
    label: "dpa_tenant_auth"
    sql: REPLACE({{ _user_attributes['dpa_tenant_auth'] }},'') ;;
  }

  dimension: test3 {
    label: "dpa_tenant_fix"
    sql: CASE WHEN REPLACE({{ _user_attributes['dpa_tenant'] }},'') = 'demo'
        THEN {{ _user_attributes['dpa_tenant_auth'] }}
        ELSE 'demo' END;;
  }


  dimension: job_id {
    primary_key: yes
    type: string
    sql: ${TABLE}."job_id" ;;
  }

  dimension: data_dict_version {
    type: string
    sql: ${TABLE}."data_dict_version" ;;
  }

  dimension: description {
    type: string
    sql: ${TABLE}."description" ;;
  }

  dimension: name {
    type: string
    label: "Job Name"
    sql: ${TABLE}."name" ;;
  }

  dimension: records {
    type: number
    sql: ${TABLE}."records" ;;
  }

  dimension: tenant_id {
    type: string
    sql: ${TABLE}."tenant_id" ;;
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

  # measure: count {
  #   type: count
  #   drill_fields: [job_id, name]
  # }
}

view: layout {

  # This table has all layout elements where there is a taxonomy object filled in

  sql_table_name: "DPA_SCHEMA"."LAYOUT"
    ;;
  drill_fields: [id]

  dimension: id {
    primary_key: yes
    type: string
    sql: ${TABLE}."id" ;;
  }

  dimension: element {
    type: string
    sql: ${TABLE}."element" ;;
  }

  dimension: page {
    type: string
    sql: ${TABLE}."page" ;;
  }

  dimension: path {
    type: string
    sql: ${TABLE}."path" ;;
  }

  dimension: subpage {
    type: string
    sql: ${TABLE}."subpage" ;;
  }

  dimension: duplicate {
    type: string
    sql:  ${TABLE}."duplicate";;
  }

  dimension: taxonomy_object {
    type: string
    sql: ${TABLE}."TAXONOMY_OBJECT" ;;
  }


  # dimension: visualization {
  #   type: string
  #   sql: ${TABLE}."visualization" ;;
  # }

  # measure: count {
  #   type: count
  #   drill_fields: [id]
  # }
}

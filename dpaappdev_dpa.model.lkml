connection: "dpaappdev"

include: "/views/*.view"

datagroup: dpa_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: dpa_default_datagroup

explore: dpa_main {
  label: "DPA Main"
  # sql_always_where:
  #     (${name} = 'Reference' OR ${tenant_id} IN ({{ _user_attributes['dpa_tenant'] }}))
  # ;;
}
#       AND ({% parameter job_select_param %} = ${job_id} OR ${name} = 'Reference')

# (${name} = 'Reference' OR ${tenant_id} IN ({{ _user_attributes['dpa_tenant'] }}))

# REPLACE({{ _user_attributes['dpa_tenant'] }},'') = 'demo'

explore: job_segment {
  label: "DPA Jobs"
  sql_always_where:
      {% if _user_attributes['dpa_tenant_auth'] contains "'" %}
      ${name} = 'Reference' OR (${tenant_id} IN ({{ _user_attributes['dpa_tenant_auth'] }}) OR ${tenant_id} = 'demo')

      {% else %}

       ${name} = 'Reference' OR ${tenant_id} = 'demo'

      {% endif %}



      ;;
}

explore: layout {
  label: "DPA Layout"
}


# explore: job {
#   label: "DPA Attribute Test"
# }

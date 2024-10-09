view: dpa_main {
  sql_table_name: "DPA_SCHEMA"."DPA_MATERIALIZED_PROD"
    ;;



  parameter: target_select_param {
    label: "Target Audience"
    type: string
    default_value: "Full Audience"
    suggest_dimension: segment_name
  }
  parameter: reference_select_param {
    label: "Reference Audience"
    type: string
    default_value: "63aa652e59"
    suggest_dimension: segment_name
  }
  parameter: job_select_param {
    label: "Job ID"
    type: string
    default_value: "a4d21d078c"
    suggest_dimension: job_id
  }

#a4d21d078c -- 100K audience
#9eed74a1ae -- Boring audience


  dimension: tenant_id {
    type: string
    sql:
        ${TABLE}."tenant_id" ;;
  }

  dimension: job_id {
    type: string
    sql: ${TABLE}."job_id" ;;
  }

  dimension: data_dict_version {
    type: string
    sql: ${TABLE}."data_dict_version" ;;
  }

  dimension: name {
    type: string
    label: "Job Name"
    sql: ${TABLE}."name" ;;
  }

  dimension: segment_name {
    type: string
    sql: ${TABLE}."segment_name" ;;
  }

  dimension: element {
    type: string
    sql: ${TABLE}."element" ;;
  }

  dimension: marketing_name {
    type: string
    sql: ${TABLE}."marketing_name" ;;
  }

  dimension: product_category {
    type: string
    sql: ${TABLE}."product_category" ;;
  }

  dimension: product_name {
    type: string
    sql: ${TABLE}."product_name" ;;
  }

  dimension: num_values {
    type: string
    sql: ${TABLE}."num_values" ;;
  }

  dimension: page {
    type: string
    sql: ${TABLE}."page" ;;
  }

  dimension: subpage {
    type: string
    sql: ${TABLE}."subpage" ;;
  }

  dimension: id {
    type: string
    sql: ${TABLE}."id" ;;
  }

  dimension: visualization {
    type: string
    sql: ${TABLE}."visualization" ;;
  }



  dimension: path {
    type: string
    sql: ${TABLE}."path" ;;
  }

  dimension: value {
    type: string
    sql: ${TABLE}."value" ;;
  }

  dimension: label {
    type: string
    sql: COALESCE(${TABLE}."label", ${TABLE}."value") ;;
  }

  dimension: duplicate {
    type: string
    sql:  ${TABLE}."duplicate";;
  }

  dimension: count {
    type: number
    sql: ${TABLE}."count" ;;
  }

  dimension: pct_pop {
    type: number
    sql: ${TABLE}."pct_pop" ;;
  }

  dimension: pct_total {
    type: number
    sql: ${TABLE}."pct_total" ;;
  }

  measure: pct_pop_sum {
    type: number
    sql: SUM(${TABLE}."pct_pop") ;;
  }

  measure: pct_total_sum {
    type: number
    sql: SUM(${TABLE}."pct_total") ;;
  }

  measure: number_of_records {
    type: count
    drill_fields: [name, segment_name]
  }


  # pct_pop vs pct_total
  #

  measure: client_pct_from_param {
    label: "Client Composition"
    type: number
    value_format_name: percent_2
    sql:
      SUM(CASE WHEN ${segment_name} = {% parameter target_select_param %}
      AND ${job_id} = {% parameter job_select_param %}
      THEN IFF(${num_values} = '1', ${pct_total}, ${pct_pop} )
      -- THEN ${pct_pop} -- added this per Laurie's direction
      ELSE NULL
      END)
      ;;
  }

  measure: reference_pct_from_param {
    label: "Reference Composition"
    type: number
    value_format_name: percent_2
    sql:
      SUM(CASE WHEN ${segment_name} = {% parameter reference_select_param %}
          AND (${job_id} = {% parameter job_select_param %}  OR ${tenant_id} IS NULL)
          THEN IFF(${num_values} = '1', ${pct_total}, ${pct_pop} )

      --THEN ${pct_pop} -- added this per Laurie's direction
      ELSE NULL
      END)
      ;;
  }


  # SUM(CASE WHEN ${segment_name} = {% parameter reference_select_param %}
  #         --AND ({% parameter job_select_param %} = ${job_id} OR ${tenant_id} IS NULL)
  #         AND ${job_id} = ({% parameter target_select_param %}  OR ${tenant_id} IS NULL) -- LOOK INTO THIS - NOT SURE WHAT I DID
  #     -- THEN IFF(${num_values} = '1', ${pct_total}, ${pct_pop} )
  #     THEN ${pct_pop} -- added this per Laurie's direction
  #     ELSE NULL
  #     END)

  # IFF({% parameter reference_select_param %} = {% parameter job_select_param %}
  #           ,{% parameter reference_select_param %} = ${segment_name} AND {% parameter job_select_param %} = ${job_id} -- If null use the target job_id / segment name combo
  #           ,{% parameter reference_select_param %} = ${job_id}
  #           )

  measure: index {
    label: "Index"
    type: number
    # value_format: "0"
    value_format_name: decimal_0
    sql: ${client_pct_from_param} / NULLIF(${reference_pct_from_param},0) * 100 ;;
  }

  measure: client_count_from_param {
    label: "Client Count"
    type: number
    value_format_name: decimal_0
    sql:
      SUM(CASE WHEN ${segment_name} = {% parameter target_select_param %} AND {% parameter job_select_param %} = ${job_id}
      THEN ${count} ELSE NULL
      END)
      ;;
  }

  # SUM(CASE WHEN ${segment_name} = {% parameter target_select_param %} AND {% parameter job_select_param %} = ${job_id}
  #     THEN ${count} ELSE NULL
  #     END)

  measure: reference_count_from_param {
    label: "Reference Count"
    type: number
    value_format_name: decimal_0
    sql:
      SUM(CASE WHEN {% parameter reference_select_param %} = ${segment_name}
          AND ({% parameter job_select_param %} = ${job_id} OR ${tenant_id} IS NULL)
      THEN ${count} ELSE NULL
      END)
      ;;
  }
# SUM(CASE WHEN ${job_id} = {% parameter reference_select_param %}

# (COALESCE((CAST(IF((CAST(dd.num_values AS bigint) > 1), job_metrics.pct_pop, job_metrics.pct_total) AS double) * 100), 0) - (CAST(IF((CAST(dd.num_values AS bigint) > 1), ref.pct_pop, ref.pct_total) AS double) * 100)) variance

# COALESCE( ${client_pct_from_param}, 0 )

  measure: variance {
    sql:
      ${client_pct_from_param}
      - ${reference_pct_from_param}
    ;;
  }


  measure: client_total_from_param {
    sql:
    ${client_count_from_param} / NULLIF(${client_pct_from_param},0)
  ;;
  }

  measure: reference_total_from_param {
    sql:
      ${reference_count_from_param} / NULLIF(${reference_pct_from_param},0)
  ;;
  }

  measure: avg_p1_p2 {
    sql:  (${client_pct_from_param} + ${reference_pct_from_param}) / 2;;
  }


# (${client_count_from_param} - AVG(${client_count_from_param}) OVER (PARTITION BY ${element}))
#       / NULLIF(STDDEV(${client_count_from_param}) OVER (PARTITION BY ${element}),0)

# https://www.socscistatistics.com/tests/ztest/
  measure: zscore {
    value_format_name: decimal_2
    type: number
    sql: CASE WHEN ${index} IS NOT NULL THEN
        ${variance} / NULLIF(SQRT(ABS(${avg_p1_p2}*(1-${avg_p1_p2}))
            *((1/NULLIF(${client_total_from_param},0))
              +(1/NULLIF(${reference_total_from_param},0)))),0)
          ELSE NULL END
      ;;
  }

  # BACKUP
  # CASE WHEN ${index} IS NOT NULL THEN
  #       ${variance} / NULLIF(SQRT(${avg_p1_p2}*(1-${avg_p1_p2})
  #           *((1/NULLIF(${client_total_from_param},0))
  #             +(1/NULLIF(${reference_total_from_param},0)))),0)
  #         ELSE NULL END

  measure: zscore_test {
    value_format_name: decimal_2
    sql:
      IFF(${num_values} = '1'
        , (CASE WHEN (${variance} = 0) THEN 0
            WHEN (${variance} < 0) THEN -1
            ELSE 1
            END)
        , (${variance} - (AVG(${variance}) OVER (PARTITION BY ${element})))
            - (STDDEV_POP(${variance}) OVER (PARTITION BY ${element}))
      )
    ;;
  }

  measure: significance {
    type: string
    sql:
      IFF(ABS(${zscore}) >= 3, 'Significant', '')
    ;;
  }
#
  dimension: svg_icons {
    type: string
    sql: CASE WHEN ${path} = 'person.coreDemographics.gender' and ${value} = 'F' THEN 'person-dress'
              WHEN ${path} = 'person.coreDemographics.gender' and ${label} = 'Unknown' THEN 'person-half-dress'
              WHEN ${path} = 'person.coreDemographics.gender' THEN 'person'

              WHEN ${element} = '8626' THEN 'cake-candles'
              WHEN ${path} = 'person.coreDemographics.adultAge2Year' THEN 'cake-candles'
              WHEN ${path} = 'household.coreDemographics.maritalStatus' THEN 'ring'
              WHEN (dpa_main."path") = 'household.coreDemographics.presenceOfChildren' and dpa_main."value" = 'N' THEN 'person'
              WHEN (dpa_main."path") = 'household.coreDemographics.presenceOfChildren' and dpa_main."value" = 'Y' THEN 'children'
              WHEN ${path} = 'household.coreDemographicsIncome.estimatedIncome.narrowRanges' THEN 'hand-holding-dollar'
              WHEN ${path} = 'residency.coreDemographics.ownerRenter' THEN 'house'
              WHEN ${path} = 'household.netWorthPropensities.netWorthGold' THEN 'sack-dollar'
              WHEN ${path} = 'place.propertyMarketValue.estimatedHomeMarketValue.bands' THEN 'house-chimney'
              WHEN ${path} = 'household.creditCardsDetails.numberOfLinesOfCredit'  THEN 'credit-card'
              WHEN ${path} = 'person.polkInMarketVehicleFuelType.new.diesel.top' and ${path} = 'person.polkInMarketVehicleFuelType.new.anyAlternativeFuel.top' or ${path} = 'person.polkInMarketVehicleFuelType.used.anyAlternativeFuel.top' THEN 'gas-pump'
              WHEN ${path} = 'person.polkInMarketVehicleFuelType.new.electric.top' or ${path} = 'person.polkInMarketVehicleFuelType.new.luxury.electric.top' or ${path} = 'person.polkInMarketVehicleFuelType.new.nonLuxury.electric.top' THEN 'charging-station'
              WHEN ${path} = 'person.polkInMarketVehicleFuelType.new.hybrid.top' and ${path} = 'person.polkInMarketVehicleFuelType.new.luxury.hybrid.top' or ${path} = 'person.polkInMarketVehicleFuelType.new.nonLuxury.hybrid.top' THEN 'charging-station'
              WHEN ${path} LIKE 'person.polkInMarketVehicleFuelType%'  THEN 'gas-pump'
              WHEN (dpa_main."path") LIKE 'person.polkInMarketVehicleTransactionType.vehicleCondition.%'  THEN 'car'
              WHEN (dpa_main."path") LIKE 'person.polkFinancial.monthlyAutoPayment.%' THEN 'money-bill-1-wave'

              WHEN ${path} LIKE 'person.coreDemographics.gender' THEN 'car'
              WHEN (dpa_main."path") LIKE 'person.polkLoyaltyVehicleClass.luxury.%' and dpa_main."value" = 1 THEN 'gem'
              WHEN (dpa_main."path") LIKE 'person.polkLoyaltyVehicleClass.nonLuxury.%' and dpa_main."value" = 1 THEN 'gem'
              WHEN ${path} LIKE 'person.polkFinancial.monthlyAutoPayment.%' THEN 'money-bill'
              WHEN ${path} = 'person.polkInMarketVehicleBudget.vehicleBudgetPredictor'  THEN 'coins'
              WHEN ${path} LIKE 'person.commerceSignalsRetailGrocery.grocerySupermarkets.%' THEN 'store'
              WHEN ${path} LIKE 'person.commerceSignalsTravel.airlines.%' THEN 'plane-departure'
              WHEN ${path} LIKE 'person.commerceSignalsTelecommunication.tvInternetWireless.%' THEN 'wifi'
              WHEN ${path} LIKE 'person.commerceSignalsRestaurants.quickServiceRestaurant.%' THEN 'utensils'
              ELSE NULL
              END
           ;;
          }


  dimension: show_more_look_id {
    type: string
    sql: '341';;
  }


  dimension: personicx_segment_color {
    type: string
    sql: CASE WHEN ${value} IS NOT NULL THEN '#00416a' ELSE NULL END ;;
  }




  dimension: personicx_hover {
    type: string
    sql: 1 ;;
    html:
    <ul>
      <li> Base: {{ dpa_main.personicx_segment_base._value }} </li>
      <li> Size: {{ dpa_main.personicx_segment_size._value }} </li>
    </ul>
    ;;
  }



  dimension: personicx_segment_education {
    type:  string
    label: "Education"
    # value_format_name: decimal_0
    sql: CASE
            WHEN ${element} = 'PX011282_01' AND ${value} =  '01'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '02'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '03'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '04'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '05'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '06'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '07'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '08'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '09'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '10'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '11'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '12'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '13'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '14'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '15'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '16'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '17'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '18'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '19'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '20'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '21'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '22'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '23'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '24'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '25'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '26'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '27'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '28'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '29'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '30'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '31'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '32'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '33'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '34'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '35'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '36'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '37'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '38'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '39'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '40'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '41'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '42'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '43'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '44'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '45'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '46'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '47'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '48'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '49'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '50'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '51'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '52'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '53'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '54'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '55'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '56'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '57'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '58'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '59'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '60'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '61'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '62'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '63'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '64'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '65'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '66'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '67'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '68'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '69'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '70'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '71'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '72'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '73'  THEN 'Grad School/College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '74'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '75'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '76'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '77'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '78'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '79'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '80'  THEN 'Grad School/College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '81'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '82'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '83'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '84'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '85'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '86'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '87'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '88'  THEN 'Graduate School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '89'  THEN 'College'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '90'  THEN 'High School'
        WHEN ${element} = 'PX011282_01' AND ${value} =  '91'  THEN 'College'
        END;;
  }
  dimension: personicx_segment_pct_married {
    type:  string
    label: "% Married"
    # value_format_name: percent_2
    sql: CASE
            WHEN ${element} = 'PX011282_01' AND ${value} =  '01'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '02'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '03'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '04'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '05'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '06'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '07'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '08'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '09'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '10'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '11'  THEN '40 - 55%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '12'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '13'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '14'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '15'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '16'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '17'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '18'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '19'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '20'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '21'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '22'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '23'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '24'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '25'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '26'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '27'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '28'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '29'  THEN '70% +'
WHEN ${element} = 'PX011282_01' AND ${value} =  '30'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '31'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '32'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '33'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '34'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '35'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '36'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '37'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '38'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '39'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '40'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '41'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '42'  THEN '40 - 55%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '43'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '44'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '45'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '46'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '47'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '48'  THEN '70% +'
WHEN ${element} = 'PX011282_01' AND ${value} =  '49'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '50'  THEN '40 - 55%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '51'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '52'  THEN '40 - 55%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '53'  THEN '40 - 55%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '54'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '55'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '56'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '57'  THEN '55 - 70%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '58'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '59'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '60'  THEN '55 - 70%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '61'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '62'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '63'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '64'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '65'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '66'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '67'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '68'  THEN '55 - 70%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '69'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '70'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '71'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '72'  THEN '15 - 25%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '73'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '74'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '75'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '76'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '77'  THEN '5 - 15%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '78'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '79'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '80'  THEN '40 - 55%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '81'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '82'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '83'  THEN '70% +'
WHEN ${element} = 'PX011282_01' AND ${value} =  '84'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '85'  THEN '55 - 70%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '86'  THEN '25 - 40%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '87'  THEN '70% +'
WHEN ${element} = 'PX011282_01' AND ${value} =  '88'  THEN '40 - 55%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '89'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '90'  THEN '< 5%'
WHEN ${element} = 'PX011282_01' AND ${value} =  '91'  THEN '70% +'
        END;;
  }


  dimension: personicx_segment_avg_age {
    type:  number
    label: "Avg Age"
    value_format_name: decimal_1
    sql: CASE
         WHEN ${element} = 'PX011282_01' AND ${value} =  '01'  THEN '30.915265303'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '02'  THEN '28.600716387'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '03'  THEN '30.883949302'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '04'  THEN '30.87667171'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '05'  THEN '35.280408181'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '06'  THEN '30.026179004'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '07'  THEN '32.306748466'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '08'  THEN '31.94170566'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '09'  THEN '32.210028382'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '10'  THEN '32.578829632'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '11'  THEN '32.948953674'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '12'  THEN '31.345397543'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '13'  THEN '27.143036079'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '14'  THEN '29.190327254'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '15'  THEN '28.007938709'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '16'  THEN '28.686206897'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '17'  THEN '30.315609553'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '18'  THEN '30.422380935'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '19'  THEN '27.812504415'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '20'  THEN '41.037593584'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '21'  THEN '41.40356587'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '22'  THEN '41.320746368'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '23'  THEN '41.583466557'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '24'  THEN '41.573498621'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '25'  THEN '41.809957066'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '26'  THEN '38.135528752'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '27'  THEN '37.898769424'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '28'  THEN '41.626881282'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '29'  THEN '41.88719251'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '30'  THEN '42.006534653'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '31'  THEN '39.020092915'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '32'  THEN '42.636778257'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '33'  THEN '52.568374618'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '34'  THEN '48.326714221'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '35'  THEN '52.670871082'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '36'  THEN '54.52109295'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '37'  THEN '54.512521413'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '38'  THEN '46.763638473'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '39'  THEN '54.418892373'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '40'  THEN '54.335378067'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '41'  THEN '52.460521169'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '42'  THEN '52.868939238'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '43'  THEN '48.781766005'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '44'  THEN '51.376991714'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '45'  THEN '50.258855654'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '46'  THEN '48.348588121'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '47'  THEN '55.591359984'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '48'  THEN '50.41601246'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '49'  THEN '50.134146882'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '50'  THEN '54.891158838'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '51'  THEN '55.67708461'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '52'  THEN '54.155553277'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '53'  THEN '54.508938236'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '54'  THEN '57.430411342'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '55'  THEN '58.211526282'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '56'  THEN '55.146592396'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '57'  THEN '54.845947016'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '58'  THEN '50.837383463'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '59'  THEN '51.290574175'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '60'  THEN '53.863116553'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '61'  THEN '59.814293512'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '62'  THEN '59.897880539'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '63'  THEN '59.568056995'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '64'  THEN '58.972520627'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '65'  THEN '58.865744545'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '66'  THEN '58.666205226'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '67'  THEN '61.454095637'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '68'  THEN '61.482958783'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '69'  THEN '61.566666667'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '70'  THEN '72.949924591'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '71'  THEN '74.52851586'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '72'  THEN '75.846310973'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '73'  THEN '72.510890273'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '74'  THEN '73.807895936'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '75'  THEN '75.377204176'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '76'  THEN '74.224582198'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '77'  THEN '73.424207351'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '78'  THEN '74.079066209'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '79'  THEN '75.679508985'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '80'  THEN '73.251827113'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '81'  THEN '78.256429545'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '82'  THEN '80.197869467'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '83'  THEN '72.958051364'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '84'  THEN '75.956079215'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '85'  THEN '76.134997913'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '86'  THEN '78.88131826'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '87'  THEN '76.294951636'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '88'  THEN '77.202296178'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '89'  THEN '77.345797116'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '90'  THEN '77.077421714'
          WHEN ${element} = 'PX011282_01' AND ${value} =  '91'  THEN '77.974601215'
        END;;
  }


  # dimension: personicx_segment_avg_age {
  #   type:  number
  #   label: "Avg Age"
  #   value_format_name: decimal_1
  #   sql: CASE
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '01'  THEN '0.884038774666543'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '02'  THEN '0.881119656172456'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '03'  THEN '0.85231608514231'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '04'  THEN '0.779513305231581'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '05'  THEN '0.868191583470239'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '06'  THEN '0.705952400109425'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '07'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '08'  THEN '0.616393324615182'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '09'  THEN '0.575905222085195'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '10'  THEN '0.583619394240181'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '11'  THEN '1'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '12'  THEN '0.8726982604184'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '13'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '14'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '15'  THEN '0.0387818612922347'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '16'  THEN '0.0612665632929236'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '17'  THEN '0.0537336321811962'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '18'  THEN '0.101350494547299'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '19'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '20'  THEN '0.8921672370317'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '21'  THEN '0.861978932204916'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '22'  THEN '0.87223255911191'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '23'  THEN '0.7255541925874'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '24'  THEN '0.680402484756534'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '25'  THEN '0.857438445985526'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '26'  THEN '0.504127635912571'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '27'  THEN '0.456465970601062'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '28'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '29'  THEN '1'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '30'  THEN '0.488606309375198'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '31'  THEN '0.457212531415632'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '32'  THEN '0.284530239736051'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '33'  THEN '0.774345532900238'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '34'  THEN '0.830449873905144'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '35'  THEN '0.888607783317211'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '36'  THEN '0.794082679950037'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '37'  THEN '0.800244764753875'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '38'  THEN '0.604915995027868'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '39'  THEN '0.798347351335399'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '40'  THEN '0.694055664945985'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '41'  THEN '0.704019542810491'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '42'  THEN '0.5771828916483'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '43'  THEN '0.674264871260793'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '44'  THEN '0.635455466108241'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '45'  THEN '0.659728040213959'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '46'  THEN '0.713965564361848'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '47'  THEN '0.624574105621806'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '48'  THEN '0.985922912049987'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '49'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '50'  THEN '0.499640092439416'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '51'  THEN '0.635397266050532'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '52'  THEN '0.623164907990679'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '53'  THEN '0.590589569160998'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '54'  THEN '0.579312881005926'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '55'  THEN '0.546179945780976'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '56'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '57'  THEN '0.706046138057204'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '58'  THEN '0.470078508865627'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '59'  THEN '0.510463798458331'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '60'  THEN '0.958442149414372'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '61'  THEN '0.843510432169835'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '62'  THEN '0.734811512892441'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '63'  THEN '0.515593769192117'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '64'  THEN '0.415248054474708'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '65'  THEN '0.4616929361402'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '66'  THEN '0.483262821940177'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '67'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '68'  THEN '1'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '69'  THEN '0.531352513694652'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '70'  THEN '0.811448573576608'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '71'  THEN '0.81276645584446'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '72'  THEN '0.698259908048653'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '73'  THEN '0.375359187401154'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '74'  THEN '0.409631633840712'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '75'  THEN '0.5248063170441'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '76'  THEN '0.520540583260887'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '77'  THEN '0.178120702826585'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '78'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '79'  THEN '0.463628918174373'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '80'  THEN '0.531512801783072'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '81'  THEN '0.687335657065982'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '82'  THEN '0.846003074558032'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '83'  THEN '1'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '84'  THEN '0.543201840525223'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '85'  THEN '0.977694468623882'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '86'  THEN '0.531461523296313'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '87'  THEN '0.962966475413723'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '88'  THEN '0.589693825501686'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '89'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '90'  THEN '0'
  #       WHEN ${element} = 'PX011282_01' AND ${value} =  '91'  THEN '1'
  #       END;;
  # }







}

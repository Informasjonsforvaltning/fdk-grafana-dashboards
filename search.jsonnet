local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local barGaugePanel = g.panel.barGauge;

local statPanel = g.panel.stat;
local util = g.util;

dashboard.new('FDK Search')
+ dashboard.withTags(['search','harvesting'])
+ dashboard.time.withFrom('now-12h')
+ dashboard.time.withTo('now')
+ dashboard.withTimezone('browser')
+ dashboard.withTemplating({
   "list": [
     {
     "current": {
       "selected": false,
       "text": "staging",
       "value": "staging"
     },
     "datasource": {
       "type": "prometheus",
       "uid": "prometheus"
     },
     "definition": "label_values(search_seconds_count,kubernetes_namespace)",
     "hide": 0,
     "includeAll": false,
     "multi": false,
     "name": "namespace",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(search_seconds_count,kubernetes_namespace)",
       "refId": "PrometheusVariableQueryEditor-VariableQuery"
     },
     "refresh": 1,
     "regex": "",
     "skipUrlSync": false,
     "sort": 0,
     "type": "query"
   }]
 })
+ dashboard.withPanels([
    timeSeriesPanel.new('Successful searches')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (kubernetes_namespace, fdk_service) (rate(search_seconds_count{kubernetes_namespace="$namespace"}[5m])*300)
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{type}}
            |||)
          ])
          + timeSeriesPanel.panelOptions.withGridPos(6, 8, 0, 0)
          + timeSeriesPanel.options.legend.withShowLegend(false)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Search time in seconds')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.panelOptions.withGridPos(6, 8, 8, 0)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'promehteus',
                |||
                    sum by (fdk_service, kubernetes_namespace) (rate(search_seconds_sum{kubernetes_namespace="$namespace"}[5m])/rate(search_seconds_count{kubernetes_namespace="$namespace"}[5m]))
                |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{type}}
            |||)
          ])
        + {
              fieldConfig+: {
                defaults+: {
                  links: [
                    {
                      targetBlank: true,
                      title: 'View in Log Explorer',
                      url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                    }
                  ]
               }
            }
          },

    timeSeriesPanel.new('Failed searches')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (fdk_service, kubernetes_namespace) (rate(search_error{kubernetes_namespace="$namespace"}[5m])*300)
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{type}}
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 8, 16, 0)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Successful suggestions')
      + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
      + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
      + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
      + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
      + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
      + timeSeriesPanel.queryOptions.withInterval('2m')
      + timeSeriesPanel.queryOptions.withTargets([
          prometheusQuery.new(
            'prometheus',
            |||
              sum by (kubernetes_namespace, fdk_service) (rate(search_suggestion_seconds_count{kubernetes_namespace="$namespace"}[5m])*300)
            |||
          )
          + prometheusQuery.withIntervalFactor(2)
          + prometheusQuery.withLegendFormat(|||
            {{type}}
          |||)
        ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 8, 0, 6)
        + timeSeriesPanel.options.legend.withShowLegend(false)
      + {
        fieldConfig+: {
          defaults+: {
            links: [
              {
                targetBlank: true,
                title: 'View in Log Explorer',
                url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
              }
            ]
         }
      }
    },

    timeSeriesPanel.new('Suggestion time in seconds')
          + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
          + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
          + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
          + timeSeriesPanel.panelOptions.withGridPos(6, 8, 8, 6)
          + timeSeriesPanel.options.legend.withShowLegend(false)
          + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
          + timeSeriesPanel.queryOptions.withInterval('2m')
          + timeSeriesPanel.queryOptions.withTargets([
              prometheusQuery.new(
                'promehteus',
                  |||
                      sum by (fdk_service, kubernetes_namespace) (rate(search_suggestion_seconds_sum{kubernetes_namespace="$namespace"}[5m])/rate(search_suggestion_seconds_count{kubernetes_namespace="$namespace"}[5m]))
                  |||
              )
              + prometheusQuery.withIntervalFactor(2)
              + prometheusQuery.withLegendFormat(|||
                {{type}}
              |||)
            ])
          + {
                fieldConfig+: {
                  defaults+: {
                    links: [
                      {
                        targetBlank: true,
                        title: 'View in Log Explorer',
                        url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                      }
                    ]
                 }
              }
            },

      timeSeriesPanel.new('Failed suggestions')
          + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
          + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
          + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
          + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
          + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
          + timeSeriesPanel.queryOptions.withInterval('2m')
          + timeSeriesPanel.queryOptions.withTargets([
              prometheusQuery.new(
                'prometheus',
                |||
                  sum by (fdk_service, kubernetes_namespace) (rate(search_suggestion_error{kubernetes_namespace="$namespace"}[5m])*300)
                |||
              )
              + prometheusQuery.withIntervalFactor(2)
              + prometheusQuery.withLegendFormat(|||
                {{type}}
              |||)
            ])
          + timeSeriesPanel.panelOptions.withGridPos(6, 8, 16, 6)
          + timeSeriesPanel.options.legend.withShowLegend(false)
          + {
            fieldConfig+: {
              defaults+: {
                links: [
                  {
                    targetBlank: true,
                    title: 'View in Log Explorer',
                    url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                  }
                ]
             }
          }
        },

        timeSeriesPanel.new('Successful indexes')
                 + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
                 + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
                 + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
                 + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
                 + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
                 + timeSeriesPanel.queryOptions.withInterval('2m')
                 + timeSeriesPanel.queryOptions.withTargets([
                     prometheusQuery.new(
                       'prometheus',
                       |||
                         sum by (kubernetes_namespace, fdk_service) (rate(search_index_seconds_count{kubernetes_namespace="$namespace"}[5m])*300)
                       |||
                     )
                     + prometheusQuery.withIntervalFactor(2)
                     + prometheusQuery.withLegendFormat(|||
                       {{type}}
                     |||)
                   ])
                   + timeSeriesPanel.panelOptions.withGridPos(6, 8, 0, 12)
                   + timeSeriesPanel.options.legend.withShowLegend(false)
                 + {
                   fieldConfig+: {
                     defaults+: {
                       links: [
                         {
                           targetBlank: true,
                           title: 'View in Log Explorer',
                           url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                         }
                       ]
                    }
                 }
               },

         timeSeriesPanel.new('Index time in seconds')
             + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
             + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
             + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
             + timeSeriesPanel.panelOptions.withGridPos(6, 8, 8, 12)
             + timeSeriesPanel.options.legend.withShowLegend(false)
             + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
             + timeSeriesPanel.queryOptions.withInterval('2m')
             + timeSeriesPanel.queryOptions.withTargets([
                 prometheusQuery.new(
                   'promehteus',
                     |||
                         sum by (fdk_service, kubernetes_namespace) (rate(search_index_seconds_sum{kubernetes_namespace="$namespace"}[5m])/rate(search_index_seconds_count{kubernetes_namespace="$namespace"}[5m]))
                     |||
                 )
                 + prometheusQuery.withIntervalFactor(2)
                 + prometheusQuery.withLegendFormat(|||
                   {{type}}
                 |||)
               ])
             + {
                   fieldConfig+: {
                     defaults+: {
                       links: [
                         {
                           targetBlank: true,
                           title: 'View in Log Explorer',
                           url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                         }
                       ]
                    }
                 }
               },

         timeSeriesPanel.new('Failed indexes')
             + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
             + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
             + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
             + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
             + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
             + timeSeriesPanel.queryOptions.withInterval('2m')
             + timeSeriesPanel.queryOptions.withTargets([
                 prometheusQuery.new(
                   'prometheus',
                   |||
                     sum by (fdk_service, kubernetes_namespace) (rate(search_index_error{kubernetes_namespace="$namespace"}[5m])*300)
                   |||
                 )
                 + prometheusQuery.withIntervalFactor(2)
                 + prometheusQuery.withLegendFormat(|||
                   {{type}}
                 |||)
               ])
             + timeSeriesPanel.panelOptions.withGridPos(6, 8, 16, 12)
             + timeSeriesPanel.options.legend.withShowLegend(false)
             + {
               fieldConfig+: {
                 defaults+: {
                   links: [
                     {
                       targetBlank: true,
                       title: 'View in Log Explorer',
                       url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                     }
                   ]
                }
             }
           },

           timeSeriesPanel.new('Successful deletes')
                + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
                + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
                + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
                + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
                + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
                + timeSeriesPanel.queryOptions.withInterval('2m')
                + timeSeriesPanel.queryOptions.withTargets([
                    prometheusQuery.new(
                      'prometheus',
                      |||
                        sum by (kubernetes_namespace, fdk_service) (rate(search_delete_seconds_count{kubernetes_namespace="$namespace"}[5m])*300)
                      |||
                    )
                    + prometheusQuery.withIntervalFactor(2)
                    + prometheusQuery.withLegendFormat(|||
                      {{type}}
                    |||)
                  ])
                  + timeSeriesPanel.panelOptions.withGridPos(6, 8, 0, 18)
                  + timeSeriesPanel.options.legend.withShowLegend(false)
                + {
                  fieldConfig+: {
                    defaults+: {
                      links: [
                        {
                          targetBlank: true,
                          title: 'View in Log Explorer',
                          url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                        }
                      ]
                   }
                }
              },

           timeSeriesPanel.new('Delete time in seconds')
                + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
                + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
                + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
                + timeSeriesPanel.panelOptions.withGridPos(6, 8, 8, 18)
                + timeSeriesPanel.options.legend.withShowLegend(false)
                + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
                + timeSeriesPanel.queryOptions.withInterval('2m')
                + timeSeriesPanel.queryOptions.withTargets([
                    prometheusQuery.new(
                      'promehteus',
                        |||
                            sum by (fdk_service, kubernetes_namespace) (rate(search_delete_seconds_sum{kubernetes_namespace="$namespace"}[5m])/rate(search_delete_seconds_count{kubernetes_namespace="$namespace"}[5m]))
                        |||
                    )
                    + prometheusQuery.withIntervalFactor(2)
                    + prometheusQuery.withLegendFormat(|||
                      {{type}}
                    |||)
                  ])
                + {
                      fieldConfig+: {
                        defaults+: {
                          links: [
                            {
                              targetBlank: true,
                              title: 'View in Log Explorer',
                              url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                            }
                          ]
                       }
                    }
                  },

            timeSeriesPanel.new('Failed deletes')
                + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
                + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
                + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
                + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
                + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
                + timeSeriesPanel.queryOptions.withInterval('2m')
                + timeSeriesPanel.queryOptions.withTargets([
                    prometheusQuery.new(
                      'prometheus',
                      |||
                        sum by (fdk_service, kubernetes_namespace) (rate(search_delete_error{kubernetes_namespace="$namespace"}[5m])*300)
                      |||
                    )
                    + prometheusQuery.withIntervalFactor(2)
                    + prometheusQuery.withLegendFormat(|||
                      {{type}}
                    |||)
                  ])
                + timeSeriesPanel.panelOptions.withGridPos(6, 8, 16, 18)
                + timeSeriesPanel.options.legend.withShowLegend(false)
                + {
                  fieldConfig+: {
                    defaults+: {
                      links: [
                        {
                          targetBlank: true,
                          title: 'View in Log Explorer',
                          url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                        }
                      ]
                   }
                }
              },
])

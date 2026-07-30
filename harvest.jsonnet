local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local barGaugePanel = g.panel.barGauge;

local statPanel = g.panel.stat;
local util = g.util;

dashboard.new('FDK Harvesting')
+ dashboard.withTags(['harvesting'])
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
     "definition": "label_values(harvest_count_total,kubernetes_namespace)",
     "hide": 0,
     "includeAll": false,
     "multi": false,
     "name": "namespace",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(harvest_count_total,kubernetes_namespace)",
       "refId": "PrometheusVariableQueryEditor-VariableQuery"
     },
     "refresh": 1,
     "regex": "",
     "skipUrlSync": false,
     "sort": 0,
     "type": "query"
   },
   {
     "allValue": ".*",
     "current": {
       "selected": false,
       "text": "All",
       "value": "$__all"
     },
     "datasource": {
       "type": "prometheus",
       "uid": "prometheus"
     },
     "definition": "label_values(harvest_count_total,type)",
     "hide": 0,
     "includeAll": true,
     "multi": false,
     "name": "type",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(harvest_count_total,type)",
       "refId": "PrometheusVariableQueryEditor-VariableQuery"
     },
     "refresh": 1,
     "regex": "",
     "skipUrlSync": false,
     "sort": 0,
     "type": "query"
   },
   {
     "allValue": ".*",
     "current": {
       "selected": true,
       "text": "All",
       "value": "$__all"
     },
     "datasource": {
       "type": "prometheus",
       "uid": "prometheus"
     },
     "definition": "label_values(harvest_count_total{kubernetes_namespace=\"$namespace\", type=~\"$type\"},datasource_id)",
     "hide": 0,
     "includeAll": true,
     "multi": false,
     "name": "datasource",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(harvest_count_total{kubernetes_namespace=\"$namespace\", type=~\"$type\"}, datasource_id)",
       "refId": "PrometheusVariableQueryEditor-VariableQuery"
     },
     "refresh": 1,
     "regex": "",
     "skipUrlSync": false,
     "sort": 2,
     "type": "query"
   }]
 })
+ dashboard.withPanels([
    timeSeriesPanel.new('Successful harvests')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (datasource_id, datasource_url, type, force_update, kubernetes_namespace, fdk_service) (floor(rate(harvest_count_total{kubernetes_namespace="$namespace", status="success", datasource_id=~"${datasource}", type=~"$type"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{datasource_url}} (type:{{type}}, id:{{datasource_id}}, force:{{force_update}})
            |||)
          ])
          + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 0)
          + timeSeriesPanel.options.legend.withShowLegend(false)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                },
                {
                  targetBlank: false,
                  title: 'Select datasource',
                  url: 'https://grafana.fellesdatakatalog.digdir.no/d/${__dashboard.uid}/fdk-harvesting?orgId=1&${namespace:queryparam}&var-datasource=${__field.labels.datasource_id}'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Failed harvests')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (datasource_id, datasource_url, type, force_update, fdk_service, kubernetes_namespace) (floor(rate(harvest_count_total{kubernetes_namespace="$namespace", status="error", datasource_id=~"${datasource}", type=~"$type"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{datasource_url}} (type:{{type}}, id:{{datasource_id}}, force:{{force_update}})
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 12, 12, 0)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                },
                {
                  targetBlank: false,
                  title: 'Select datasource',
                  url: 'https://grafana.fellesdatakatalog.digdir.no/d/${__dashboard.uid}/fdk-harvesting?orgId=1&${namespace:queryparam}&var-datasource=${__field.labels.datasource_id}'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Changed resources')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (datasource_id, datasource_url, type, force_update, fdk_service, kubernetes_namespace) (floor(rate(harvest_changed_resources_count_total{kubernetes_namespace="$namespace", datasource_id=~"${datasource}", type=~"$type"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{datasource_url}} (type:{{type}}, id:{{datasource_id}}, force:{{force_update}})
            |||)
          ])
          + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 6)
          + timeSeriesPanel.options.legend.withShowLegend(false)
            + {
              fieldConfig+: {
                defaults+: {
                  links: [
                    {
                      targetBlank: true,
                      title: 'View in Log Explorer',
                      url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                    },
                    {
                      targetBlank: false,
                      title: 'Select datasource',
                      url: 'https://grafana.fellesdatakatalog.digdir.no/d/${__dashboard.uid}/fdk-harvesting?orgId=1&${namespace:queryparam}&var-datasource=${__field.labels.datasource_id}'
                    }
                  ]
               }
            }
          },

    timeSeriesPanel.new('Removed resources')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (datasource_id, datasource_url, type, force_update, fdk_service, kubernetes_namespace) (floor(rate(harvest_removed_resources_count_total{kubernetes_namespace="$namespace", datasource_id=~"${datasource}", type=~"$type"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{datasource_url}} (type:{{type}}, id:{{datasource_id}}, force:{{force_update}})
            |||)
          ])
          + timeSeriesPanel.panelOptions.withGridPos(6, 12, 12, 6)
          + timeSeriesPanel.options.legend.withShowLegend(false)
        + {
              fieldConfig+: {
                defaults+: {
                  links: [
                    {
                      targetBlank: true,
                      title: 'View in Log Explorer',
                      url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                    },
                    {
                      targetBlank: false,
                      title: 'Select datasource',
                      url: 'https://grafana.fellesdatakatalog.digdir.no/d/${__dashboard.uid}/fdk-harvesting?orgId=1&${namespace:queryparam}&var-datasource=${__field.labels.datasource_id}'
                    }
                  ]
               }
            }
          },

    timeSeriesPanel.new('Harvest time in seconds')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.panelOptions.withGridPos(8, 24, 0, 12)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
                |||
                    sum by (datasource_id, datasource_url, type, force_update, fdk_service, kubernetes_namespace) (rate(harvest_time_seconds_sum{kubernetes_namespace="$namespace", datasource_id=~"${datasource}", type=~"$type"}[5m])/rate(harvest_time_seconds_count{kubernetes_namespace="$namespace", datasource_id=~"${datasource}", type=~"$type"}[5m]))
                |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{datasource_url}} (type:{{type}}, id:{{datasource_id}}, force:{{force_update}})
            |||)
          ])
        + {
              fieldConfig+: {
                defaults+: {
                  links: [
                    {
                      targetBlank: true,
                      title: 'View in Log Explorer',
                      url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                    },
                    {
                      targetBlank: false,
                      title: 'Select datasource',
                      url: 'https://grafana.fellesdatakatalog.digdir.no/d/${__dashboard.uid}/fdk-harvesting?orgId=1&${namespace:queryparam}&var-datasource=${__field.labels.datasource_id}'
                    }
                  ]
               }
            }
          },

    timeSeriesPanel.new('Harvest errors by category')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (category, type, kubernetes_namespace, fdk_service) (floor(rate(harvest_error_count_total{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{category}} (type:{{type}})
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 20)
        + timeSeriesPanel.options.legend.withShowLegend(true)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    statPanel.new('Circuit breaker open')
        + statPanel.panelOptions.withGridPos(6, 6, 12, 20)
        + statPanel.options.withGraphMode('none')
        + statPanel.options.withColorMode('background')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.options.reduceOptions.withValues(false)
        + statPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + statPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                max(resilience4j_circuitbreaker_state{kubernetes_namespace="$namespace", name="harvest-cb", state="open"})
              |||
            )
            + prometheusQuery.withLegendFormat('open')
          ])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([
            statPanel.standardOptions.threshold.step.withColor('green')
            + statPanel.standardOptions.threshold.step.withValue(null),
            statPanel.standardOptions.threshold.step.withColor('red')
            + statPanel.standardOptions.threshold.step.withValue(1),
          ])
        + statPanel.standardOptions.withMappings([
            {
              type: 'value',
              options: {
                '0': { text: 'Closed', color: 'green', index: 0 },
                '1': { text: 'Open', color: 'red', index: 1 },
              },
            },
          ]),

    statPanel.new('Kafka listener paused')
        + statPanel.panelOptions.withGridPos(6, 6, 18, 20)
        + statPanel.options.withGraphMode('none')
        + statPanel.options.withColorMode('background')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.options.reduceOptions.withValues(false)
        + statPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + statPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                max(kafka_listener_paused{kubernetes_namespace="$namespace", listener="harvest"})
              |||
            )
            + prometheusQuery.withLegendFormat('paused')
          ])
        + statPanel.standardOptions.thresholds.withMode('absolute')
        + statPanel.standardOptions.thresholds.withSteps([
            statPanel.standardOptions.threshold.step.withColor('green')
            + statPanel.standardOptions.threshold.step.withValue(null),
            statPanel.standardOptions.threshold.step.withColor('orange')
            + statPanel.standardOptions.threshold.step.withValue(1),
          ])
        + statPanel.standardOptions.withMappings([
            {
              type: 'value',
              options: {
                '0': { text: 'Running', color: 'green', index: 0 },
                '1': { text: 'Paused', color: 'orange', index: 1 },
              },
            },
          ]),

    timeSeriesPanel.new('Kafka event processing')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (phase, result, kubernetes_namespace, fdk_service) (floor(rate(harvest_event_processing_total{kubernetes_namespace="$namespace"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{phase}}:{{result}}
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 26)
        + timeSeriesPanel.options.legend.withShowLegend(true)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Resource event publish')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (status, reason, kind, type, kubernetes_namespace, fdk_service) (floor(rate(resource_event_publish_total{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{kind}}:{{status}}/{{reason}} (type:{{type}})
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 12, 12, 26)
        + timeSeriesPanel.options.legend.withShowLegend(true)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Circuit breaker not permitted calls')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("bars")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (name, kubernetes_namespace, fdk_service) (floor(rate(resilience4j_circuitbreaker_not_permitted_calls_total{kubernetes_namespace="$namespace", name="harvest-cb"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{name}}
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 32)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Circuit breaker failure rate')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
        + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle("line")
        + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                max by (name, kubernetes_namespace, fdk_service) (resilience4j_circuitbreaker_failure_rate{kubernetes_namespace="$namespace", name="harvest-cb"})
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{name}}
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 12, 12, 32)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.standardOptions.withUnit('percent')
        + {
          fieldConfig+: {
            defaults+: {
              max: 100,
              min: 0,
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22fdk-harvester%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },
])

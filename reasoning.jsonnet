local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local barGaugePanel = g.panel.barGauge;

local statPanel = g.panel.stat;
local util = g.util;

dashboard.new('FDK Reasoning')
+ dashboard.withTags(['reasoning','harvesting'])
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
     "definition": "label_values(processed_messages,kubernetes_namespace)",
     "hide": 0,
     "includeAll": false,
     "multi": false,
     "name": "namespace",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(reasoning_seconds_sum,kubernetes_namespace)",
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
     "definition": "label_values(reasoning_seconds_sum,type)",
     "hide": 0,
     "includeAll": true,
     "multi": false,
     "name": "type",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(reasoning_seconds_sum,type)",
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
    timeSeriesPanel.new('Successful reasonings')
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
                sum by (type, kubernetes_namespace, fdk_service) (rate(reasoning_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300)
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{type}}
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
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Failed reasonings')
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
                sum by (type, fdk_service, kubernetes_namespace) (rate(reasoning_error{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300)
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{type}}
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
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Reasoning time in seconds')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.panelOptions.withGridPos(8, 24, 0, 12)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'promehteus',
                |||
                    sum by (type, fdk_service, kubernetes_namespace) (rate(reasoning_seconds_sum{kubernetes_namespace="$namespace", type=~"$type"}[5m])/rate(reasoning_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m]))
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
    
    timeSeriesPanel.new('Reasoning deduction time in seconds')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.panelOptions.withGridPos(8, 24, 0, 24)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'promehteus',
                |||
                    sum by (type, fdk_service, kubernetes_namespace) (rate(reasoning_deduction_seconds_sum{kubernetes_namespace="$namespace", type=~"$type"}[5m])/rate(reasoning_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m]))
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
    timeSeriesPanel.new('Reasoning organization time in seconds')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.panelOptions.withGridPos(8, 24, 0, 36)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'promehteus',
                |||
                    sum by (type, fdk_service, kubernetes_namespace) (rate(reasoning_organization_seconds_sum{kubernetes_namespace="$namespace", type=~"$type"}[5m])/rate(reasoning_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m]))
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
    
    timeSeriesPanel.new('Reasoning reference-data time in seconds')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.panelOptions.withGridPos(8, 24, 0, 48)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'promehteus',
                |||
                    sum by (type, fdk_service, kubernetes_namespace) (rate(reasoning_reference_data_seconds_sum{kubernetes_namespace="$namespace", type=~"$type"}[5m])/rate(reasoning_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m]))
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

])

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
     "definition": "label_values(processed_messages,kubernetes_namespace)",
     "hide": 0,
     "includeAll": false,
     "multi": false,
     "name": "namespace",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(processed_messages,kubernetes_namespace)",
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
     "definition": "label_values({kubernetes_namespace=\"$namespace\", type=~\"$type\"},datasource_id)",
     "hide": 0,
     "includeAll": true,
     "multi": false,
     "name": "datasource",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values({kubernetes_namespace=\"$namespace\", type=~\"$type\"}, datasource_id)",
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
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
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
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
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
                      url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
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
                      url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
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
                      url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
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
])

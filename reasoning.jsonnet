local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local barGaugePanel = g.panel.barGauge;

local statPanel = g.panel.stat;
local util = g.util;

dashboard.new('FDK Reasoning')
+ dashboard.withTags(['reasoning'])
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
     "definition": "label_values(reasoning_count_total,type)",
     "hide": 0,
     "includeAll": true,
     "multi": false,
     "name": "type",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(reasoning_count_total,type)",
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
    timeSeriesPanel.new('Successful reasoning jobs')
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
                sum by (type, kubernetes_namespace) (floor(rate(reasoning_count_total{kubernetes_namespace="$namespace", status="reasoning_success", datasource_id=~"${datasource}", type=~"$type"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              (type:{{type}}, id:{{datasource_id}})
            |||)
          ])
          + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 0)
          + timeSeriesPanel.options.legend.withShowLegend(false),

    timeSeriesPanel.new('Failed reasoning jobs')
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
                sum by (type, kubernetes_namespace) (floor(rate(reasoning_count_total{kubernetes_namespace="$namespace", status="reasoning_error", datasource_id=~"${datasource}", type=~"$type"}[5m])*300))
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              (type:{{type}}, id:{{datasource_id}})
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 12, 12, 0)
        + timeSeriesPanel.options.legend.withShowLegend(false),

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
                    sum by (type, kubernetes_namespace) (rate(reasoning_time_seconds_sum{kubernetes_namespace="$namespace", type=~"$type"}[5m])/rate(reasoning_time_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m]))
                |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              (type:{{type}}, id:{{datasource_id}})
            |||)
          ])
])

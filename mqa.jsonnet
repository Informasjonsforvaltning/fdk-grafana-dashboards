local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local gaugePanel = g.panel.gauge;

local statPanel = g.panel.stat;
local util = g.util;

dashboard.new('FDK Metadata Quality')
+ dashboard.withTags(['mqa'])
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
     }
   ]
 })
+ dashboard.withPanels([
  statPanel.new('DATASET HARVEST')
   + statPanel.panelOptions.withGridPos(5, 4, 0, 1)
   + statPanel.options.withGraphMode('none')
   + statPanel.options.reduceOptions.withCalcs(['delta'])
   + statPanel.options.reduceOptions.withValues(false)
   + statPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum by (fdk_service) ({__name__="processed_messages", fdk_service='fdk-mqa-assmentator',status="success", kubernetes_namespace="$namespace"})
      |||
    )])
  + statPanel.standardOptions.thresholds.withMode('absolute')
  + statPanel.standardOptions.thresholds.withSteps([
  statPanel.standardOptions.threshold.step.withColor('green')
  + statPanel.standardOptions.threshold.step.withValue(0)
  ]),

  statPanel.new('ASSESSMENT CREATION')
   + statPanel.panelOptions.withGridPos(5, 4, 4, 1)
   + statPanel.options.withGraphMode('none')
   + statPanel.options.reduceOptions.withCalcs(['delta'])
   + statPanel.options.reduceOptions.withValues(false)
   + statPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum by (fdk_service) ({__name__="produced_messages", fdk_service='fdk-mqa-assmentator',status="success", kubernetes_namespace="$namespace"})
      |||
    )])
  + statPanel.standardOptions.thresholds.withMode('absolute')
    + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green')
    + statPanel.standardOptions.threshold.step.withValue(0)
    ]),

  statPanel.new('URL CHECK')
   + statPanel.panelOptions.withGridPos(5, 4, 8, 1)
   + statPanel.options.withGraphMode('none')
   + statPanel.options.reduceOptions.withCalcs(['delta'])
   + statPanel.options.reduceOptions.withValues(false)
   + statPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum by (fdk_service) ({__name__="processed_messages", fdk_service='fdk-mqa-url-checker',status="success", kubernetes_namespace="$namespace"})
      |||
    )])
  + statPanel.standardOptions.thresholds.withMode('absolute')
    + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green')
    + statPanel.standardOptions.threshold.step.withValue(0)
    ]),

  statPanel.new('PROPERTIES CHECK')
   + statPanel.panelOptions.withGridPos(5, 4, 12, 1)
   + statPanel.options.withGraphMode('none')
   + statPanel.options.reduceOptions.withCalcs(['delta'])
   + statPanel.options.reduceOptions.withValues(false)
   + statPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum by (fdk_service) ({__name__="processed_messages", fdk_service='fdk-mqa-property-checker',status="success", kubernetes_namespace="$namespace"})
      |||
    )])
  + statPanel.standardOptions.thresholds.withMode('absolute')
    + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green')
    + statPanel.standardOptions.threshold.step.withValue(0)
    ]),

  statPanel.new('DCAT VALIDATION')
   + statPanel.panelOptions.withGridPos(5, 4, 16, 1)
   + statPanel.options.withGraphMode('none')
   + statPanel.options.reduceOptions.withCalcs(['delta'])
   + statPanel.options.reduceOptions.withValues(false)
   + statPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum by (fdk_service) ({__name__="processed_messages_total", fdk_service='fdk-mqa-dcat-validator',status="success", kubernetes_namespace="$namespace"})
      |||
    )])
  + statPanel.standardOptions.thresholds.withMode('absolute')
    + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green')
    + statPanel.standardOptions.threshold.step.withValue(0)
    ]),

  statPanel.new('SCORING')
   + statPanel.panelOptions.withGridPos(5, 4, 20, 1)
   + statPanel.options.withGraphMode('none')
   + statPanel.options.reduceOptions.withCalcs(['delta'])
   + statPanel.options.reduceOptions.withValues(false)
   + statPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum by (fdk_service) ({__name__="processed_messages", fdk_service='fdk-mqa-scoring-service',status="success", kubernetes_namespace="$namespace"})
      |||
    )])
   + statPanel.standardOptions.thresholds.withMode('absolute')
   + statPanel.standardOptions.thresholds.withSteps([
     statPanel.standardOptions.threshold.step.withColor('green')
   + statPanel.standardOptions.threshold.step.withValue(0)]),

  timeSeriesPanel.new('Messages successfully processed')
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
  + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
  + timeSeriesPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum(rate({__name__=~"^processed_messages(_total)?$", status="success", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m])*600) by (fdk_service)
      |||
    )
    + prometheusQuery.withIntervalFactor(2)
    + prometheusQuery.withLegendFormat(|||
      {{fdk_service}}
    |||)
  ])
  + timeSeriesPanel.panelOptions.withGridPos(8, 12, 0, 6),

  timeSeriesPanel.new('Messages skipped')
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
  + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
  + timeSeriesPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum(rate({__name__=~"^processed_messages(_total)?$", status="skipped", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m])*600) by (fdk_service)
      |||
    )
    + prometheusQuery.withIntervalFactor(2)
    + prometheusQuery.withLegendFormat(|||
      {{fdk_service}}
    |||)
  ])
  + timeSeriesPanel.panelOptions.withGridPos(8, 12, 12, 6),

  timeSeriesPanel.new('Messages processing errors')
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
  + timeSeriesPanel.fieldConfig.defaults.custom.thresholdsStyle.withMode('line+area')
  + timeSeriesPanel.standardOptions.thresholds.withMode('absolute')
  + timeSeriesPanel.standardOptions.thresholds.withSteps([
    timeSeriesPanel.standardOptions.threshold.step.withColor('green')
    + timeSeriesPanel.standardOptions.threshold.step.withValue(0),
    timeSeriesPanel.standardOptions.threshold.step.withColor('dark-red')
    + timeSeriesPanel.standardOptions.threshold.step.withValue(1)
  ])
  + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
  + timeSeriesPanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        sum(rate({__name__=~"^processed_messages(_total)?$", status="error", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m])*600) by (fdk_service)
      |||
    )
    + prometheusQuery.withIntervalFactor(2)
    + prometheusQuery.withLegendFormat(|||
      {{fdk_service}}
    |||)
  ])
  + timeSeriesPanel.panelOptions.withGridPos(8, 12, 0, 14),

  timeSeriesPanel.new('Messages produced')
    + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
    + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
    + timeSeriesPanel.queryOptions.withTargets([
        prometheusQuery.new(
          'prometheus',
          |||
            sum(rate({__name__=~"^produced_messages(_total)?$", status="success", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m])*600) by (fdk_service)
          |||
        )
        + prometheusQuery.withIntervalFactor(2)
        + prometheusQuery.withLegendFormat(|||
          {{fdk_service}}
        |||)
      ])
      + timeSeriesPanel.panelOptions.withGridPos(8, 12, 12, 14),

  gaugePanel.new('Average processing time')
  + gaugePanel.standardOptions.thresholds.withMode('absolute')
  + gaugePanel.standardOptions.thresholds.withSteps([
    gaugePanel.standardOptions.threshold.step.withColor('green')
    + gaugePanel.standardOptions.threshold.step.withValue(0)
  ])
  + gaugePanel.queryOptions.withDatasource('prometheus', 'prometheus')
  + gaugePanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        avg({__name__=~"^processing_time(_seconds)?_sum$", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"} / {__name__=~"^processing_time(_seconds)?_count$", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}) by (fdk_service)
      |||
    )
    + prometheusQuery.withIntervalFactor(2)
    + prometheusQuery.withLegendFormat(|||
      {{fdk_service}}
    |||)
  ])
  + gaugePanel.panelOptions.withGridPos(8, 24, 0, 22)
])

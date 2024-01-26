local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local statPanel = g.panel.stat;
local util = g.util;

dashboard.new('MQA')
+ dashboard.withTags(['mqa'])
+ dashboard.time.withFrom('now-12h')
+ dashboard.time.withTo('now')
+ g.dashboard.withVariables([
  dashboard.variable.custom.new('namespace', values = ['prod', 'staging', 'demo'])
  + dashboard.variable.custom.generalOptions.withLabel('Environment')
  + dashboard.variable.custom.generalOptions.withName('namespace')
  + dashboard.variable.custom.selectionOptions.withIncludeAll(false)
])
+ dashboard.withPanels(
  util.grid.makeGrid([
    g.panel.row.new('Metadata Quality Flow')
    + g.panel.row.withPanels([
      statPanel.new('DATASET HARVEST')
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
      + statPanel.panelOptions.withGridPos(6, 4, 0, 0),

      statPanel.new('ASSESSMENT CREATION')
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
      + statPanel.panelOptions.withGridPos(6, 4, 0, 0),

      statPanel.new('URL CHECK')
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
      + statPanel.panelOptions.withGridPos(6, 5, 4, 0),

      statPanel.new('PROPERTIES CHECK')
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
      + statPanel.panelOptions.withGridPos(6, 5, 9, 0),

      statPanel.new('DCAT VALIDATION')
       + statPanel.options.withGraphMode('none')
       + statPanel.options.reduceOptions.withCalcs(['delta'])
       + statPanel.options.reduceOptions.withValues(false)       
       + statPanel.queryOptions.withTargets([
        prometheusQuery.new(
          'prometheus',
          |||
            sum by (fdk_service) ({__name__="processed_messages", fdk_service='fdk-mqa-dcat-validator',status="success", kubernetes_namespace="$namespace"})
          |||
        )])
      + statPanel.panelOptions.withGridPos(6, 5, 14, 0),

      statPanel.new('SCORING')
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
      + statPanel.panelOptions.withGridPos(6, 5, 19, 0)
      ]),
    g.panel.row.new('Messages and processing time')
    + g.panel.row.withPanels([
      timeSeriesPanel.new('Messages Successfully Processed per Second')      
      + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
      + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
      + timeSeriesPanel.queryOptions.withTargets([
        prometheusQuery.new(
          'prometheus',
          |||
            sum(rate(processed_messages{status="success", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m])*600) by (fdk_service)
          |||
        )
        + prometheusQuery.withIntervalFactor(2)
        + prometheusQuery.withLegendFormat(|||
          {{fdk_service}}
        |||)
      ])
      + timeSeriesPanel.panelOptions.withGridPos(10, 24, 0, 0),

      timeSeriesPanel.new('Messages Skipped per Second')      
      + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
      + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
      + timeSeriesPanel.queryOptions.withTargets([
        prometheusQuery.new(
          'prometheus',
          |||
            sum(rate(processed_messages{status="skipped", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m])*600) by (fdk_service)
          |||
        )
        + prometheusQuery.withIntervalFactor(2)
        + prometheusQuery.withLegendFormat(|||
          {{fdk_service}}
        |||)
      ])
      + timeSeriesPanel.panelOptions.withGridPos(10, 24, 0, 0),

      timeSeriesPanel.new('Messages Processing Errors per Second')
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
            sum(rate(processed_messages{status="error", fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m])*600) by (fdk_service)
          |||
        )
        + prometheusQuery.withIntervalFactor(2)
        + prometheusQuery.withLegendFormat(|||
          {{fdk_service}}
        |||)
      ])
      + timeSeriesPanel.panelOptions.withGridPos(8, 24, 0, 1),

      timeSeriesPanel.new('Average processing time')    
      + timeSeriesPanel.standardOptions.thresholds.withMode('absolute') 
      + timeSeriesPanel.standardOptions.thresholds.withSteps([
        timeSeriesPanel.standardOptions.threshold.step.withColor('green')
        + timeSeriesPanel.standardOptions.threshold.step.withValue(0),
        timeSeriesPanel.standardOptions.threshold.step.withColor('dark-red')
        + timeSeriesPanel.standardOptions.threshold.step.withValue(1)
      ])
      + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls(true)
      + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(2)
      + timeSeriesPanel.fieldConfig.defaults.custom.thresholdsStyle.withMode('line+area')
      + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
      + timeSeriesPanel.queryOptions.withTargets([
        prometheusQuery.new(
          'prometheus',
          |||
            sum(rate(processing_time_sum{fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m]) / rate(processing_time_count{fdk_service=~"fdk-mqa-.*", kubernetes_namespace="$namespace"}[10m])) by (fdk_service)
          |||
        )
        + prometheusQuery.withIntervalFactor(2)
        + prometheusQuery.withLegendFormat(|||
          {{fdk_service}}
        |||)
      ])
      + timeSeriesPanel.panelOptions.withGridPos(8, 24, 0, 2)
    ])
  ])
)

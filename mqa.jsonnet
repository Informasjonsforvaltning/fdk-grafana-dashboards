local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local table_panel = import 'grafonnet-7.0/panel/table.libsonnet';
local timeseries_panel = import 'github.com/rhowe/grafonnet-lib/grafonnet/timeseries_panel.libsonnet';
local prometheus = grafana.prometheus;
local template = grafana.template;

dashboard.new(
  'MQA',
  tags=['mqa'],
  time_from='now-2h',
)
.addPanel(
  timeseries_panel.new(
    'Messages Successfully Processed per Second',
    lineWidth=2,
  )
  .addTarget(
    prometheus.target(
      'sum(rate(processed_messages{status="success"}[3m])*180) by (fdk_service, kubernetes_namespace)',
      datasource='prometheus',
      interval='2s',
      legendFormat='{{fdk_service}} ({{kubernetes_namespace}})',
    )
  ), gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 10,
  }
)
.addPanel(
  timeseries_panel.new(
    'Messages Processing Errors per Second',
    lineWidth=2,
    min=0,
  )
  .addThreshold(
    'green',
    value=0,
  )
  .addThreshold(
    'dark-red',
    value=1,
  )
  .addTarget(
    prometheus.target(
      'sum(rate(processed_messages{status="error"}[3m])*180) by (fdk_service, kubernetes_namespace)',
      datasource='prometheus',
      interval='2s',
      legendFormat='{{fdk_service}} ({{kubernetes_namespace}})',
    )
  ) + {
    fieldConfig+: {
      defaults+: {
        custom+: {
          lineWidth: 2,
          thresholdsStyle: {
            mode: 'line+area',
          },
        },
      },
    },
  }, gridPos={
    x: 0,
    y: 1,
    w: 24,
    h: 8,
  }
)
.addPanel(
  timeseries_panel.new(
    'Average processing time',
    lineWidth=2,
    min=0,
    max=15,
  )
  .addThreshold(
    'green',
    value=0,
  )
  .addThreshold(
    'dark-red',
    value=5,
  )
  .addTarget(
    prometheus.target(
      'sum(rate(processing_time_sum{}[30s]) / rate(processing_time_count{}[30s])) by (fdk_service, kubernetes_namespace)',
      datasource='prometheus',
      interval='2s',
      legendFormat='{{fdk_service}} ({{kubernetes_namespace}})',
    )
  ) + {
    fieldConfig+: {
      defaults+: {
        custom+: {
          lineWidth: 2,
          thresholdsStyle: {
            mode: 'line+area',
          },
        },
      },
    },
  }, gridPos={
    x: 0,
    y: 2,
    w: 24,
    h: 8,
  }
)

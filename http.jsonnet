local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local timeseries_panel = import 'grafonnet/timeseries_panel.libsonnet';
local prometheus = grafana.prometheus;

// Logarithmic currently not working, so using std.mergePatch to modify type field.
local log_override = {
  fieldConfig: {
    defaults: {
      custom: {
        scaleDistribution: {
          type: 'log',
        },
      },
    },
  },
};

dashboard.new(
  'HTTP',
  tags=['http'],
  time_from='now-2h',
)
.addPanel(
  std.mergePatch(timeseries_panel.new(
    'Response Times',
    graphStyle='points',
    axisLogBase=2,
  ).addTarget(
    prometheus.target(
      'sum(increase(nginx_ingress_controller_response_duration_seconds_sum{status!~"1.."}[30s])) by (service) / sum(increase(nginx_ingress_controller_response_duration_seconds_count{status!~"1.."}[30s])) by (service)',
      datasource='prometheus',
      intervalFactor=1,
      interval='30s',
      legendFormat='{{service}}',
    )
  ), log_override), gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 8,
  }
)
.addPanel(
  std.mergePatch(timeseries_panel.new(
    'Status 200 Requests',
    graphStyle='points',
    axisLogBase=2,
  ).addTarget(
    prometheus.target(
      'sum(increase(nginx_ingress_controller_requests{status="200"}[30s])) by (service)',
      datasource='prometheus',
      intervalFactor=1,
      interval='30s',
      legendFormat='{{service}}',
    )
  ), log_override), gridPos={
    x: 0,
    y: 1,
    w: 24,
    h: 8,
  }
)
.addPanel(
  std.mergePatch(timeseries_panel.new(
    title='Status 5xx Requests',
    graphStyle='points',
    max=16,
    axisLogBase=2,
  ).addTarget(
    prometheus.target(
      'increase(nginx_ingress_controller_requests{status=~"5.."}[30s])',
      datasource='prometheus',
      intervalFactor=1,
      interval='10s',
      legendFormat='{{service}} - {{status}}',
    )
  ), log_override), gridPos={
    x: 0,
    y: 2,
    w: 24,
    h: 8,
  }
)

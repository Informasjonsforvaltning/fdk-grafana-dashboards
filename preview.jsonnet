local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;

local logLink = {
  targetBlank: true,
  title: 'View in Log Explorer',
  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod',
};

local errorLogLink = {
  targetBlank: true,
  title: 'View in Log Explorer',
  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod',
};

local withLogLinks(panel, links) =
  panel + {
    fieldConfig+: {
      defaults+: {
        links: links,
      },
    },
  };

local ratePanel(title, expr, legend, gridPos, links) =
  withLogLinks(
    timeSeriesPanel.new(title)
    + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
    + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
    + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
    + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
    + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
    + timeSeriesPanel.queryOptions.withInterval('2m')
    + timeSeriesPanel.queryOptions.withTargets([
      prometheusQuery.new('prometheus', expr)
      + prometheusQuery.withIntervalFactor(2)
      + prometheusQuery.withLegendFormat(legend)
    ])
    + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
    + timeSeriesPanel.options.legend.withShowLegend(true),
    links
  );

local durationPanel(title, expr, legend, gridPos, links) =
  withLogLinks(
    timeSeriesPanel.new(title)
    + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
    + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
    + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
    + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
    + timeSeriesPanel.queryOptions.withInterval('2m')
    + timeSeriesPanel.queryOptions.withTargets([
      prometheusQuery.new('prometheus', expr)
      + prometheusQuery.withIntervalFactor(2)
      + prometheusQuery.withLegendFormat(legend)
    ])
    + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
    + timeSeriesPanel.options.legend.withShowLegend(true)
    + timeSeriesPanel.standardOptions.withUnit('s'),
    links
  );

dashboard.new('FDK Dataset Preview')
+ dashboard.withTags(['preview'])
+ dashboard.time.withFrom('now-12h')
+ dashboard.time.withTo('now')
+ dashboard.withTimezone('browser')
+ dashboard.withTemplating({
  list: [
    {
      current: {
        selected: false,
        text: 'staging',
        value: 'staging',
      },
      datasource: {
        type: 'prometheus',
        uid: 'prometheus',
      },
      definition: 'label_values(preview_request_count_total,kubernetes_namespace)',
      hide: 0,
      includeAll: false,
      multi: false,
      name: 'namespace',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(preview_request_count_total,kubernetes_namespace)',
        refId: 'PrometheusVariableQueryEditor-VariableQuery',
      },
      refresh: 1,
      regex: '',
      skipUrlSync: false,
      sort: 0,
      type: 'query',
    },
    {
      allValue: '.*',
      current: {
        selected: false,
        text: 'All',
        value: '$__all',
      },
      datasource: {
        type: 'prometheus',
        uid: 'prometheus',
      },
      definition: 'label_values(preview_count_total{kubernetes_namespace="$namespace"},format)',
      hide: 0,
      includeAll: true,
      multi: false,
      name: 'format',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(preview_count_total{kubernetes_namespace="$namespace"},format)',
        refId: 'PrometheusVariableQueryEditor-VariableQuery',
      },
      refresh: 1,
      regex: '',
      skipUrlSync: false,
      sort: 0,
      type: 'query',
    },
  ],
})
+ dashboard.withPanels([
  ratePanel(
    'Successful preview requests',
    |||
      sum by (kubernetes_namespace, fdk_service) (
        rate(preview_request_count_total{kubernetes_namespace="$namespace", status="success"}[5m]) * 300
      )
    |||,
    'success',
    { h: 6, w: 12, x: 0, y: 0 },
    [logLink]
  ),

  ratePanel(
    'Failed preview requests',
    |||
      sum by (error_type, kubernetes_namespace, fdk_service) (
        rate(preview_request_count_total{kubernetes_namespace="$namespace", status="error"}[5m]) * 300
      )
    |||,
    '{{error_type}}',
    { h: 6, w: 12, x: 12, y: 0 },
    [errorLogLink]
  ),

  ratePanel(
    'Successful previews by format',
    |||
      sum by (format, kubernetes_namespace, fdk_service) (
        rate(preview_count_total{kubernetes_namespace="$namespace", status="success", format=~"$format"}[5m]) * 300
      )
    |||,
    '{{format}}',
    { h: 6, w: 12, x: 0, y: 6 },
    [logLink]
  ),

  ratePanel(
    'Failed previews by error type',
    |||
      sum by (error_type, kubernetes_namespace, fdk_service) (
        rate(preview_count_total{kubernetes_namespace="$namespace", status="error"}[5m]) * 300
      )
    |||,
    '{{error_type}}',
    { h: 6, w: 12, x: 12, y: 6 },
    [errorLogLink]
  ),

  durationPanel(
    'Preview duration',
    |||
      sum by (format, kubernetes_namespace, fdk_service) (
        rate(preview_duration_seconds_sum{kubernetes_namespace="$namespace", format=~"$format"}[5m])
        /
        rate(preview_duration_seconds_count{kubernetes_namespace="$namespace", format=~"$format"}[5m])
      )
    |||,
    '{{format}}',
    { h: 6, w: 12, x: 0, y: 12 },
    [logLink]
  ),

  durationPanel(
    'Download duration',
    |||
      sum by (status_code, kubernetes_namespace, fdk_service) (
        rate(preview_download_duration_seconds_sum{kubernetes_namespace="$namespace"}[5m])
        /
        rate(preview_download_duration_seconds_count{kubernetes_namespace="$namespace"}[5m])
      )
    |||,
    '{{status_code}}',
    { h: 6, w: 12, x: 12, y: 12 },
    [logLink]
  ),

  ratePanel(
    'Successful downloads',
    |||
      sum by (status_code, kubernetes_namespace, fdk_service) (
        rate(preview_download_count_total{kubernetes_namespace="$namespace", status="success"}[5m]) * 300
      )
    |||,
    '{{status_code}}',
    { h: 6, w: 12, x: 0, y: 18 },
    [logLink]
  ),

  ratePanel(
    'Failed downloads',
    |||
      sum by (status_code, kubernetes_namespace, fdk_service) (
        rate(preview_download_count_total{kubernetes_namespace="$namespace", status="error"}[5m]) * 300
      )
    |||,
    '{{status_code}}',
    { h: 6, w: 12, x: 12, y: 18 },
    [errorLogLink]
  ),

  withLogLinks(
    timeSeriesPanel.new('Download bytes')
    + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
    + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
    + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
    + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
    + timeSeriesPanel.queryOptions.withInterval('2m')
    + timeSeriesPanel.queryOptions.withTargets([
      prometheusQuery.new(
        'prometheus',
        |||
          sum by (kubernetes_namespace, fdk_service) (
            rate(preview_download_bytes_total{kubernetes_namespace="$namespace"}[5m])
          )
        |||
      )
      + prometheusQuery.withIntervalFactor(2)
      + prometheusQuery.withLegendFormat('bytes/s')
    ])
    + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 24)
    + timeSeriesPanel.options.legend.withShowLegend(true)
    + timeSeriesPanel.standardOptions.withUnit('Bps'),
    [logLink]
  ),

  withLogLinks(
    timeSeriesPanel.new('Average preview file size')
    + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
    + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
    + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
    + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
    + timeSeriesPanel.queryOptions.withInterval('2m')
    + timeSeriesPanel.queryOptions.withTargets([
      prometheusQuery.new(
        'prometheus',
        |||
          sum by (kubernetes_namespace, fdk_service) (
            rate(preview_file_size_bytes_sum{kubernetes_namespace="$namespace"}[5m])
            /
            rate(preview_file_size_bytes_count{kubernetes_namespace="$namespace"}[5m])
          )
        |||
      )
      + prometheusQuery.withIntervalFactor(2)
      + prometheusQuery.withLegendFormat('avg size')
    ])
    + timeSeriesPanel.panelOptions.withGridPos(6, 12, 12, 24)
    + timeSeriesPanel.options.legend.withShowLegend(true)
    + timeSeriesPanel.standardOptions.withUnit('bytes'),
    [logLink]
  ),

  withLogLinks(
    timeSeriesPanel.new('HTTP requests')
    + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
    + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
    + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
    + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
    + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
    + timeSeriesPanel.queryOptions.withInterval('2m')
    + timeSeriesPanel.queryOptions.withTargets([
      prometheusQuery.new(
        'prometheus',
        |||
          sum by (uri, status, method, kubernetes_namespace, fdk_service) (
            rate(http_server_requests_seconds_count{
              kubernetes_namespace="$namespace",
              application="fdk-dataset-preview-service",
              uri!~"/actuator.*"
            }[5m]) * 300
          )
        |||
      )
      + prometheusQuery.withIntervalFactor(2)
      + prometheusQuery.withLegendFormat('{{method}} {{uri}} {{status}}')
    ])
    + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 30)
    + timeSeriesPanel.options.legend.withShowLegend(true),
    [logLink]
  ),

  durationPanel(
    'HTTP request duration',
    |||
      sum by (uri, method, kubernetes_namespace, fdk_service) (
        rate(http_server_requests_seconds_sum{
          kubernetes_namespace="$namespace",
          application="fdk-dataset-preview-service",
          uri!~"/actuator.*"
        }[5m])
        /
        rate(http_server_requests_seconds_count{
          kubernetes_namespace="$namespace",
          application="fdk-dataset-preview-service",
          uri!~"/actuator.*"
        }[5m])
      )
    |||,
    '{{method}} {{uri}}',
    { h: 6, w: 12, x: 12, y: 30 },
    [logLink]
  ),
])

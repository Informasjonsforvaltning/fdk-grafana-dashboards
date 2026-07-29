local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local tablePanel = g.panel.table;

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

// Preview traffic is sparse: rate()/increase() often stay empty when Prometheus
// never observes a counter delta between two scrapes. Graph cumulative counter
// values instead so single events still appear as steps.
local counterPanel(title, expr, legend, gridPos, links) =
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

local avgPanel(title, expr, legend, gridPos, links, unit='s') =
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
    + timeSeriesPanel.standardOptions.withUnit(unit),
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
      definition: 'label_values(preview_count_total{kubernetes_namespace="$namespace", format!="none"},format)',
      hide: 0,
      includeAll: true,
      multi: false,
      name: 'format',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(preview_count_total{kubernetes_namespace="$namespace", format!="none"},format)',
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
  counterPanel(
    'Successful preview requests',
    |||
      sum by (kubernetes_namespace, fdk_service) (
        preview_request_count_total{kubernetes_namespace="$namespace", method="POST", status="success"}
      )
    |||,
    'success',
    { h: 6, w: 12, x: 0, y: 0 },
    [logLink]
  ),

  counterPanel(
    'Failed preview requests',
    |||
      sum by (error_type, kubernetes_namespace, fdk_service) (
        preview_request_count_total{kubernetes_namespace="$namespace", method="POST", status="error"}
      )
    |||,
    '{{error_type}}',
    { h: 6, w: 12, x: 12, y: 0 },
    [errorLogLink]
  ),

  counterPanel(
    'Successful previews by format',
    |||
      sum by (format, kubernetes_namespace, fdk_service) (
        preview_count_total{kubernetes_namespace="$namespace", status="success", format=~"$format"}
      )
    |||,
    '{{format}}',
    { h: 6, w: 12, x: 0, y: 6 },
    [logLink]
  ),

  counterPanel(
    'Failed previews by error type',
    |||
      sum by (error_type, kubernetes_namespace, fdk_service) (
        preview_count_total{kubernetes_namespace="$namespace", status="error"}
      )
    |||,
    '{{error_type}}',
    { h: 6, w: 12, x: 12, y: 6 },
    [errorLogLink]
  ),

  avgPanel(
    'Preview duration',
    |||
      sum by (format, kubernetes_namespace, fdk_service) (
        preview_duration_seconds_sum{kubernetes_namespace="$namespace", format=~"$format"}
      )
      /
      sum by (format, kubernetes_namespace, fdk_service) (
        preview_duration_seconds_count{kubernetes_namespace="$namespace", format=~"$format"}
      )
    |||,
    '{{format}}',
    { h: 6, w: 12, x: 0, y: 12 },
    [logLink]
  ),

  avgPanel(
    'Download duration',
    |||
      sum by (status_code, kubernetes_namespace, fdk_service) (
        preview_download_duration_seconds_sum{kubernetes_namespace="$namespace"}
      )
      /
      sum by (status_code, kubernetes_namespace, fdk_service) (
        preview_download_duration_seconds_count{kubernetes_namespace="$namespace"}
      )
    |||,
    '{{status_code}}',
    { h: 6, w: 12, x: 12, y: 12 },
    [logLink]
  ),

  counterPanel(
    'Successful downloads',
    |||
      sum by (status_code, kubernetes_namespace, fdk_service) (
        preview_download_count_total{kubernetes_namespace="$namespace", status="success"}
      )
    |||,
    '{{status_code}}',
    { h: 6, w: 12, x: 0, y: 18 },
    [logLink]
  ),

  counterPanel(
    'Failed downloads',
    |||
      sum by (status_code, kubernetes_namespace, fdk_service) (
        preview_download_count_total{kubernetes_namespace="$namespace", status="error"}
      )
    |||,
    '{{status_code}}',
    { h: 6, w: 12, x: 12, y: 18 },
    [errorLogLink]
  ),

  avgPanel(
    'Download bytes',
    |||
      sum by (kubernetes_namespace, fdk_service) (
        preview_download_bytes_total{kubernetes_namespace="$namespace"}
      )
    |||,
    'bytes',
    { h: 6, w: 12, x: 0, y: 24 },
    [logLink],
    'bytes'
  ),

  avgPanel(
    'Average preview file size',
    |||
      sum by (kubernetes_namespace, fdk_service) (
        preview_file_size_bytes_sum{kubernetes_namespace="$namespace"}
      )
      /
      sum by (kubernetes_namespace, fdk_service) (
        preview_file_size_bytes_count{kubernetes_namespace="$namespace"}
      )
    |||,
    'avg size',
    { h: 6, w: 12, x: 12, y: 24 },
    [logLink],
    'bytes'
  ),

  counterPanel(
    'HTTP requests',
    |||
      sum by (status, method, kubernetes_namespace, fdk_service) (
        http_server_requests_seconds_count{
          kubernetes_namespace="$namespace",
          application="fdk-dataset-preview-service",
          uri="/preview"
        }
      )
    |||,
    '{{method}} {{status}}',
    { h: 6, w: 12, x: 0, y: 30 },
    [logLink]
  ),

  avgPanel(
    'HTTP request duration',
    |||
      sum by (method, kubernetes_namespace, fdk_service) (
        http_server_requests_seconds_sum{
          kubernetes_namespace="$namespace",
          application="fdk-dataset-preview-service",
          uri="/preview"
        }
      )
      /
      sum by (method, kubernetes_namespace, fdk_service) (
        http_server_requests_seconds_count{
          kubernetes_namespace="$namespace",
          application="fdk-dataset-preview-service",
          uri="/preview"
        }
      )
    |||,
    '{{method}}',
    { h: 6, w: 12, x: 12, y: 30 },
    [logLink]
  ),

  tablePanel.new('Top failing resource URLs')
  + tablePanel.queryOptions.withDatasource('prometheus', 'prometheus')
  + tablePanel.queryOptions.withTargets([
    prometheusQuery.new(
      'prometheus',
      |||
        topk(10,
          sum by (resource_url, error_type) (
            preview_count_total{kubernetes_namespace="$namespace", status="error"}
          )
        )
      |||
    )
    + prometheusQuery.withFormat('table')
    + prometheusQuery.withInstant()
    + prometheusQuery.withRange(false)
  ])
  + tablePanel.queryOptions.withTransformations([
    {
      id: 'organize',
      options: {
        excludeByName: {
          Time: true,
          __name__: true,
        },
        renameByName: {
          resource_url: 'Resource URL',
          error_type: 'Error type',
          'Value #A': 'Failures',
          Value: 'Failures',
        },
        indexByName: {
          resource_url: 0,
          error_type: 1,
          'Value #A': 2,
          Value: 2,
        },
      },
    },
  ])
  + tablePanel.options.withSortBy([
    tablePanel.options.sortBy.withDisplayName('Failures')
    + tablePanel.options.sortBy.withDesc(),
  ])
  + tablePanel.panelOptions.withGridPos(8, 24, 0, 36),
])

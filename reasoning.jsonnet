local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local statPanel = g.panel.stat;

local prometheus = 'prometheus';
local ns = 'kubernetes_namespace="$namespace"';
local cbName = 'reasoning-cb';
local listenerId = 'reasoning';
local fdkService = 'fdk-reasoning-service';

local logExplorerUrl =
  'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22'
  + fdkService
  + '%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod';

local logExplorerErrorUrl =
  'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22'
  + fdkService
  + '%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod';

local withLogLink(panel, errorLogs=false) =
  panel
  + {
    fieldConfig+: {
      defaults+: {
        links: [
          {
            targetBlank: true,
            title: 'View in Log Explorer',
            url: if errorLogs then logExplorerErrorUrl else logExplorerUrl,
          },
        ],
      },
    },
  };

local stackedBarPanel(title, gridPos, targets) =
  timeSeriesPanel.new(title)
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
  + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle('bars')
  + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
  + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
  + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
  + timeSeriesPanel.queryOptions.withDatasource(prometheus, prometheus)
  + timeSeriesPanel.queryOptions.withInterval('2m')
  + timeSeriesPanel.queryOptions.withTargets(targets)
  + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
  + timeSeriesPanel.options.legend.withShowLegend(true);

local stackedLinePanel(title, gridPos, targets) =
  timeSeriesPanel.new(title)
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
  + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
  + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
  + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
  + timeSeriesPanel.queryOptions.withDatasource(prometheus, prometheus)
  + timeSeriesPanel.queryOptions.withInterval('2m')
  + timeSeriesPanel.queryOptions.withTargets(targets)
  + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
  + timeSeriesPanel.options.legend.withShowLegend(false);

local linePanel(title, gridPos, targets, unit='short') =
  timeSeriesPanel.new(title)
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
  + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle('line')
  + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(10)
  + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
  + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'none', group: 'A' })
  + timeSeriesPanel.standardOptions.withUnit(unit)
  + timeSeriesPanel.queryOptions.withDatasource(prometheus, prometheus)
  + timeSeriesPanel.queryOptions.withInterval('2m')
  + timeSeriesPanel.queryOptions.withTargets(targets)
  + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y);

local rateQuery(expr, legend) =
  prometheusQuery.new(
    prometheus,
    |||
      %s
    ||| % expr,
  )
  + prometheusQuery.withIntervalFactor(2)
  + prometheusQuery.withLegendFormat(legend);

local tableLegend(panel, calcs=['sum']) =
  panel
  + timeSeriesPanel.options.legend.withCalcs(calcs)
  + timeSeriesPanel.options.legend.withDisplayMode('table')
  + timeSeriesPanel.options.legend.withPlacement('bottom')
  + timeSeriesPanel.options.legend.withShowLegend(true);

dashboard.new('FDK Reasoning')
+ dashboard.withTags(['reasoning', 'harvesting'])
+ dashboard.withRefresh('30s')
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
      definition: 'label_values(reasoning_seconds_sum,kubernetes_namespace)',
      hide: 0,
      includeAll: false,
      multi: false,
      name: 'namespace',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(reasoning_seconds_sum,kubernetes_namespace)',
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
      definition: 'label_values(reasoning_seconds_sum,type)',
      hide: 0,
      includeAll: true,
      multi: false,
      name: 'type',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(reasoning_seconds_sum,type)',
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

  // --- Reasoning outcomes ---
  withLogLink(
    tableLegend(
      stackedLinePanel(
        'Successful reasonings',
        { h: 6, w: 12, x: 0, y: 0 },
        [
          rateQuery(
            'sum by (type, kubernetes_namespace, fdk_service) (reasoning_seconds_count{' + ns + ', type=~"$type"})',
            '{{type}}',
          ),
        ],
      )
      + timeSeriesPanel.queryOptions.withInterval('5m'),
      ['lastNotNull'],
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Failed reasonings',
        { h: 6, w: 12, x: 12, y: 0 },
        [
          prometheusQuery.new(
            prometheus,
            'sum by (type, fdk_service, kubernetes_namespace) (increase(reasoning_event_processing_total{' + ns + ', type=~"$type", result="nacked"}[$__interval])) or vector(0)',
          )
          + prometheusQuery.withLegendFormat('{{type}}'),
        ],
      )
      + timeSeriesPanel.queryOptions.withInterval('5m'),
    ),
    true,
  ),

  // --- Reasoning timing ---
  // reasoning_*_seconds are Prometheus summaries (no _bucket), and reasoning is
  // bursty, so a 5m rate collapses to 0/0 while idle. Use the average
  // (sum/count) so the typical duration is always visible.
  withLogLink(
    linePanel(
      'Reasoning time in seconds',
      { h: 8, w: 24, x: 0, y: 6 },
      [
        rateQuery(
          'sum by (type, fdk_service, kubernetes_namespace) (reasoning_seconds_sum{' + ns + ', type=~"$type"}) / sum by (type, fdk_service, kubernetes_namespace) (reasoning_seconds_count{' + ns + ', type=~"$type"})',
          '{{type}}',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    linePanel(
      'Reasoning deduction time in seconds',
      { h: 8, w: 24, x: 0, y: 14 },
      [
        rateQuery(
          'sum by (type, fdk_service, kubernetes_namespace) (reasoning_deduction_seconds_sum{' + ns + ', type=~"$type"}) / sum by (type, fdk_service, kubernetes_namespace) (reasoning_seconds_count{' + ns + ', type=~"$type"})',
          '{{type}}',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    linePanel(
      'Reasoning organization time in seconds',
      { h: 8, w: 24, x: 0, y: 22 },
      [
        rateQuery(
          'sum by (type, fdk_service, kubernetes_namespace) (reasoning_organization_seconds_sum{' + ns + ', type=~"$type"}) / sum by (type, fdk_service, kubernetes_namespace) (reasoning_seconds_count{' + ns + ', type=~"$type"})',
          '{{type}}',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    linePanel(
      'Reasoning reference-data time in seconds',
      { h: 8, w: 24, x: 0, y: 30 },
      [
        rateQuery(
          'sum by (type, fdk_service, kubernetes_namespace) (reasoning_reference_data_seconds_sum{' + ns + ', type=~"$type"}) / sum by (type, fdk_service, kubernetes_namespace) (reasoning_seconds_count{' + ns + ', type=~"$type"})',
          '{{type}}',
        ),
      ],
      's',
    ),
  ),

  // --- Kafka and circuit breaker ---
  statPanel.new('Circuit breaker open')
  + statPanel.panelOptions.withGridPos(6, 6, 0, 38)
  + statPanel.options.withGraphMode('none')
  + statPanel.options.withColorMode('background')
  + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + statPanel.options.reduceOptions.withValues(false)
  + statPanel.queryOptions.withDatasource(prometheus, prometheus)
  + statPanel.queryOptions.withTargets([
    rateQuery(
      'max(resilience4j_circuitbreaker_state{' + ns + ', name="' + cbName + '", state="open"})',
      'open',
    ),
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
  + statPanel.panelOptions.withGridPos(6, 6, 6, 38)
  + statPanel.options.withGraphMode('none')
  + statPanel.options.withColorMode('background')
  + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + statPanel.options.reduceOptions.withValues(false)
  + statPanel.queryOptions.withDatasource(prometheus, prometheus)
  + statPanel.queryOptions.withTargets([
    rateQuery(
      'max(kafka_listener_paused{' + ns + ', listener="' + listenerId + '"})',
      'paused',
    ),
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

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Kafka event processing',
        { h: 6, w: 12, x: 0, y: 44 },
        [
          rateQuery(
            'sum by (result) (floor(rate(spring_kafka_listener_seconds_count{' + ns + ', name=~"' + listenerId + '.*"}[5m])*300))',
            'listener:{{result}}',
          ),
        ],
      ),
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Event publish',
        { h: 6, w: 12, x: 12, y: 44 },
        [
          rateQuery(
            'sum by (result) (floor(rate(spring_kafka_template_seconds_count{' + ns + '}[5m])*300))',
            'publish:{{result}}',
          ),
        ],
      ),
    ),
  ),

  withLogLink(
    stackedBarPanel(
      'Circuit breaker not permitted calls',
      { h: 6, w: 12, x: 0, y: 50 },
      [
        rateQuery(
          'sum by (name) (floor(rate(resilience4j_circuitbreaker_not_permitted_calls_total{' + ns + ', name="' + cbName + '"}[5m])*300))',
          '{{name}}',
        ),
      ],
    )
    + timeSeriesPanel.options.legend.withShowLegend(false),
  ),

  withLogLink(
    linePanel(
      'Circuit breaker failure rate',
      { h: 6, w: 12, x: 12, y: 50 },
      [
        rateQuery(
          'max by (name) (resilience4j_circuitbreaker_failure_rate{' + ns + ', name="' + cbName + '"})',
          '{{name}}',
        ),
      ],
      'percent',
    )
    + timeSeriesPanel.options.legend.withShowLegend(false)
    + {
      fieldConfig+: {
        defaults+: {
          max: 100,
          min: 0,
        },
      },
    },
  ),

  // --- Reference data ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Reference data refresh rate',
        { h: 8, w: 12, x: 0, y: 56 },
        [
          rateQuery(
            'sum by (source, status) (floor(rate(reference_data_refresh_total{' + ns + '}[5m])*300))',
            '{{source}}:{{status}}',
          ),
        ],
      ),
      ['lastNotNull', 'sum'],
    ),
    true,
  ),

  // reference_data_refresh_time_seconds is a summary (no _bucket), so
  // histogram_quantile is impossible. Show the average (sum/count) per source.
  withLogLink(
    linePanel(
      'Reference data refresh time (avg)',
      { h: 8, w: 12, x: 12, y: 56 },
      [
        rateQuery(
          'sum by (source) (reference_data_refresh_time_seconds_sum{' + ns + ', status="success"}) / sum by (source) (reference_data_refresh_time_seconds_count{' + ns + ', status="success"})',
          '{{source}}',
        ),
      ],
      's',
    )
    + timeSeriesPanel.options.legend.withCalcs(['mean', 'max'])
    + timeSeriesPanel.options.legend.withDisplayMode('table')
    + timeSeriesPanel.options.legend.withPlacement('bottom')
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

])

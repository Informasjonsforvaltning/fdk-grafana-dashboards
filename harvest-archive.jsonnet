local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local statPanel = g.panel.stat;

local prometheus = 'prometheus';
local fdkService = 'fdk-harvest-archive';
local ns = 'kubernetes_namespace="$namespace"';
local svc = ns + ', fdk_service="' + fdkService + '"';
local cbNameRegex = 'concept-archive-cb|dataservice-archive-cb|dataset-archive-cb|event-archive-cb|informationmodel-archive-cb|service-archive-cb';
local listenerRegex = 'concept-archive|dataservice-archive|dataset-archive|event-archive|informationmodel-archive|service-archive';

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

local rateQuery(expr, legend) =
  prometheusQuery.new(
    prometheus,
    |||
      %s
    ||| % expr,
  )
  + prometheusQuery.withIntervalFactor(2)
  + prometheusQuery.withLegendFormat(legend);

local query(expr, legend, refId='A') =
  prometheusQuery.new(prometheus, expr)
  + prometheusQuery.withLegendFormat(legend)
  + prometheusQuery.withRefId(refId);

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

local tableLegend(panel, calcs=['sum']) =
  panel
  + timeSeriesPanel.options.legend.withCalcs(calcs)
  + timeSeriesPanel.options.legend.withDisplayMode('table')
  + timeSeriesPanel.options.legend.withPlacement('bottom')
  + timeSeriesPanel.options.legend.withShowLegend(true);

local statusStat(title, gridPos, expr, legend, mappings, warnColor='red') =
  statPanel.new(title)
  + statPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
  + statPanel.options.withGraphMode('none')
  + statPanel.options.withColorMode('background')
  + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + statPanel.options.reduceOptions.withValues(false)
  + statPanel.queryOptions.withDatasource(prometheus, prometheus)
  + statPanel.queryOptions.withTargets([
    rateQuery(expr, legend),
  ])
  + statPanel.standardOptions.thresholds.withMode('absolute')
  + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green')
    + statPanel.standardOptions.threshold.step.withValue(null),
    statPanel.standardOptions.threshold.step.withColor(warnColor)
    + statPanel.standardOptions.threshold.step.withValue(1),
  ])
  + statPanel.standardOptions.withMappings(mappings);

local overviewStat(title, gridPos, targets, unit='short') =
  statPanel.new(title)
  + statPanel.options.withColorMode('value')
  + statPanel.options.withGraphMode('area')
  + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + statPanel.options.reduceOptions.withValues(false)
  + statPanel.standardOptions.color.withMode('thresholds')
  + statPanel.standardOptions.withUnit(unit)
  + statPanel.standardOptions.thresholds.withMode('absolute')
  + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green'),
  ])
  + statPanel.queryOptions.withDatasource(prometheus, prometheus)
  + statPanel.queryOptions.withTargets(targets)
  + statPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y);

dashboard.new('FDK Harvest Archive')
+ dashboard.withUid('fdk-harvest-archive-dashboard')
+ dashboard.withTags(['harvest', 'fdk', 'harvest-archive'])
+ dashboard.withRefresh('30s')
+ dashboard.time.withFrom('now-6h')
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
      definition: 'label_values(harvest_archive_event_processing_total,kubernetes_namespace)',
      hide: 0,
      includeAll: false,
      multi: false,
      name: 'namespace',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(harvest_archive_event_processing_total,kubernetes_namespace)',
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
        selected: true,
        text: 'All',
        value: '$__all',
      },
      datasource: {
        type: 'prometheus',
        uid: 'prometheus',
      },
      definition: 'label_values(harvest_archive_event_processing_total{' + ns + '},type)',
      hide: 0,
      includeAll: true,
      multi: false,
      name: 'type',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(harvest_archive_event_processing_total{' + ns + '}, type)',
        refId: 'PrometheusVariableQueryEditor-VariableQuery',
      },
      refresh: 1,
      regex: '',
      skipUrlSync: false,
      sort: 1,
      type: 'query',
    },
  ],
})
+ dashboard.withPanels([
  // --- Ops status ---
  statusStat(
    'Circuit breaker open',
    { h: 6, w: 6, x: 0, y: 0 },
    'max(resilience4j_circuitbreaker_state{' + svc + ', name=~"' + cbNameRegex + '", state="open"})',
    'open',
    [
      {
        type: 'value',
        options: {
          '0': { text: 'Closed', color: 'green', index: 0 },
          '1': { text: 'Open', color: 'red', index: 1 },
        },
      },
    ],
  ),

  statusStat(
    'Kafka listener paused',
    { h: 6, w: 6, x: 6, y: 0 },
    'max(kafka_listener_paused{' + svc + ', listener=~"' + listenerRegex + '"})',
    'paused',
    [
      {
        type: 'value',
        options: {
          '0': { text: 'Running', color: 'green', index: 0 },
          '1': { text: 'Paused', color: 'orange', index: 1 },
        },
      },
    ],
    'orange',
  ),

  overviewStat(
    'Unzipped files on disk (last scan)',
    { h: 6, w: 6, x: 12, y: 0 },
    [
      query(
        'sum(harvest_archive_dir_files{' + ns + ', type=~"$type"})',
        'files',
      ),
    ],
  ),

  overviewStat(
    'Unzipped bytes on disk (last scan)',
    { h: 6, w: 6, x: 18, y: 0 },
    [
      query(
        'sum(harvest_archive_dir_bytes{' + ns + ', type=~"$type"})',
        'bytes',
      ),
    ],
    'bytes',
  ),

  // --- Event processing ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Event processing',
        { h: 8, w: 12, x: 0, y: 6 },
        [
          rateQuery(
            'sum by (type, result, reason) (floor(rate(harvest_archive_event_processing_total{' + ns + ', type=~"$type"}[5m])*300))',
            '{{type}} / {{result}} / {{reason}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Files saved',
        { h: 8, w: 12, x: 12, y: 6 },
        [
          rateQuery(
            'sum by (type, event_type, status) (floor(rate(harvest_archive_files_saved_total{' + ns + ', type=~"$type"}[5m])*300))',
            '{{type}} / {{event_type}} / {{status}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Save errors',
        { h: 8, w: 12, x: 0, y: 14 },
        [
          rateQuery(
            'sum by (type, event_type) (floor(rate(harvest_archive_files_saved_total{' + ns + ', type=~"$type", status="error"}[5m])*300))',
            '{{type}} / {{event_type}}',
          ),
        ],
      ),
    ),
    true,
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Event processing failures',
        { h: 8, w: 12, x: 12, y: 14 },
        [
          rateQuery(
            'sum by (type, result, reason) (floor(rate(harvest_archive_event_processing_total{' + ns + ', type=~"$type", result="nacked"}[5m])*300))',
            '{{type}} / {{result}} / {{reason}}',
          ),
        ],
      ),
    ),
    true,
  ),

  // --- Kafka and performance ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Kafka listener processing',
        { h: 8, w: 12, x: 0, y: 22 },
        [
          rateQuery(
            'sum by (name, result) (floor(rate(spring_kafka_listener_seconds_count{' + svc + ', name=~"' + listenerRegex + '.*", result="success"}[5m])*300))',
            '{{name}} / {{result}}',
          ),
          rateQuery(
            'sum by (name, exception) (floor(rate(spring_kafka_listener_seconds_count{' + svc + ', name=~"' + listenerRegex + '.*", exception!="none"}[5m])*300))',
            '{{name}} / {{exception}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    linePanel(
      'Save time (avg)',
      { h: 8, w: 12, x: 12, y: 22 },
      [
        rateQuery(
          |||
            sum by (type) (rate(harvest_archive_save_time_seconds_sum{%s, type=~"$type"}[5m]))
            /
            sum by (type) (rate(harvest_archive_save_time_seconds_count{%s, type=~"$type"}[5m]))
          ||| % [ns, ns],
          '{{type}}',
        ),
      ],
      's',
    )
    + timeSeriesPanel.options.legend.withCalcs(['mean', 'max'])
    + timeSeriesPanel.options.legend.withDisplayMode('table')
    + timeSeriesPanel.options.legend.withPlacement('bottom')
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Zip operations',
        { h: 8, w: 12, x: 0, y: 30 },
        [
          rateQuery(
            'sum by (type, status) (floor(rate(harvest_archive_zip_total{' + ns + ', type=~"$type"}[5m])*300))',
            '{{type}} / {{status}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    linePanel(
      'Zip time (avg)',
      { h: 8, w: 12, x: 12, y: 30 },
      [
        rateQuery(
          |||
            sum by (type, status) (rate(harvest_archive_zip_time_seconds_sum{%s, type=~"$type"}[5m]))
            /
            sum by (type, status) (rate(harvest_archive_zip_time_seconds_count{%s, type=~"$type"}[5m]))
          ||| % [ns, ns],
          '{{type}} / {{status}}',
        ),
      ],
      's',
    )
    + timeSeriesPanel.options.legend.withCalcs(['mean', 'max'])
    + timeSeriesPanel.options.legend.withDisplayMode('table')
    + timeSeriesPanel.options.legend.withPlacement('bottom')
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

  // --- Archive storage ---
  linePanel(
    'Unzipped files by type (last scan)',
    { h: 8, w: 12, x: 0, y: 38 },
    [
      query(
        'sum by (type) (harvest_archive_dir_files{' + ns + ', type=~"$type"})',
        '{{type}}',
      ),
    ],
  )
  + timeSeriesPanel.options.legend.withShowLegend(true),

  linePanel(
    'Unzipped bytes by type (last scan)',
    { h: 8, w: 12, x: 12, y: 38 },
    [
      query(
        'sum by (type) (harvest_archive_dir_bytes{' + ns + ', type=~"$type"})',
        '{{type}}',
      ),
    ],
    'bytes',
  )
  + timeSeriesPanel.options.legend.withShowLegend(true),

  withLogLink(
    linePanel(
      'Saved file size (avg)',
      { h: 8, w: 12, x: 0, y: 46 },
      [
        rateQuery(
          |||
            sum by (type) (harvest_archive_file_bytes_sum{%s, type=~"$type"})
            /
            sum by (type) (harvest_archive_file_bytes_count{%s, type=~"$type"} > 0)
          ||| % [ns, ns],
          '{{type}}',
        ),
      ],
      'bytes',
    )
    + timeSeriesPanel.options.legend.withCalcs(['mean', 'max'])
    + timeSeriesPanel.options.legend.withDisplayMode('table')
    + timeSeriesPanel.options.legend.withPlacement('bottom')
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Skipped events',
        { h: 8, w: 12, x: 12, y: 46 },
        [
          rateQuery(
            'sum by (type, reason) (floor(rate(harvest_archive_event_processing_total{' + ns + ', type=~"$type", result="skipped"}[5m])*300))',
            '{{type}} / {{reason}}',
          ),
        ],
      ),
    ),
  ),

  // --- Circuit breaker ---
  withLogLink(
    stackedBarPanel(
      'Circuit breaker not permitted calls',
      { h: 8, w: 12, x: 0, y: 54 },
      [
        rateQuery(
          'sum by (name) (floor(rate(resilience4j_circuitbreaker_not_permitted_calls_total{' + svc + ', name=~"' + cbNameRegex + '"}[5m])*300))',
          '{{name}}',
        ),
      ],
    )
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

  withLogLink(
    linePanel(
      'Circuit breaker failure rate',
      { h: 8, w: 12, x: 12, y: 54 },
      [
        rateQuery(
          'max by (name) (resilience4j_circuitbreaker_failure_rate{' + svc + ', name=~"' + cbNameRegex + '"})',
          '{{name}}',
        ),
      ],
      'percent',
    )
    + timeSeriesPanel.options.legend.withShowLegend(true)
    + {
      fieldConfig+: {
        defaults+: {
          max: 100,
          min: 0,
        },
      },
    },
  ),
])

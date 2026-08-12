local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local barGaugePanel = g.panel.barGauge;
local tablePanel = g.panel.table;
local statPanel = g.panel.stat;

local prometheus = 'prometheus';
local fdkService = 'reference-data';
local ns = 'kubernetes_namespace="$namespace"';
local svc = ns + ', fdk_service="' + fdkService + '"';
local harvest = svc + ', module=~"$module"';

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

local counterQuery(expr, legend) =
  prometheusQuery.new(
    prometheus,
    |||
      %s
    ||| % expr,
  )
  + prometheusQuery.withIntervalFactor(2)
  + prometheusQuery.withLegendFormat(legend);

local harvestCountInRange(expr) =
  'sum(' + expr + ') or vector(0)';

local query(expr, legend, refId='A') =
  prometheusQuery.new(prometheus, expr)
  + prometheusQuery.withLegendFormat(legend)
  + prometheusQuery.withRefId(refId);

local instantTableQuery(expr, refId) =
  prometheusQuery.new(prometheus, expr)
  + prometheusQuery.withFormat('table')
  + prometheusQuery.withInstant()
  + prometheusQuery.withRange(false)
  + prometheusQuery.withRefId(refId);

local stackedBarPanel(title, gridPos, targets, interval='2m') =
  timeSeriesPanel.new(title)
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
  + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle('bars')
  + timeSeriesPanel.fieldConfig.defaults.custom.withFillOpacity(100)
  + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
  + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
  + timeSeriesPanel.queryOptions.withDatasource(prometheus, prometheus)
  + timeSeriesPanel.queryOptions.withInterval(interval)
  + timeSeriesPanel.queryOptions.withTargets(targets)
  + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
  + timeSeriesPanel.options.legend.withShowLegend(true);

local cumulativeHarvestPanel(title, gridPos, targets) =
  timeSeriesPanel.new(title)
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
  + timeSeriesPanel.fieldConfig.defaults.custom.withDrawStyle('line')
  + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
  + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
  + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
  + timeSeriesPanel.queryOptions.withDatasource(prometheus, prometheus)
  + timeSeriesPanel.queryOptions.withInterval('5m')
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
  + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
  + timeSeriesPanel.options.legend.withShowLegend(true);

local tableLegend(panel, calcs=['sum']) =
  panel
  + timeSeriesPanel.options.legend.withCalcs(calcs)
  + timeSeriesPanel.options.legend.withDisplayMode('table')
  + timeSeriesPanel.options.legend.withPlacement('bottom')
  + timeSeriesPanel.options.legend.withShowLegend(true);

local overviewStat(title, gridPos, targets, unit='short') =
  statPanel.new(title)
  + statPanel.options.withColorMode('value')
  + statPanel.options.withGraphMode('none')
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

dashboard.new('FDK Reference Data')
+ dashboard.withTags(['fdk', 'reference-data', 'harvesting', 'prometheus'])
+ dashboard.withRefresh('30s')
+ dashboard.time.withFrom('now-24h')
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
      definition: 'label_values(reference_data_harvest_total,kubernetes_namespace)',
      hide: 0,
      includeAll: false,
      multi: false,
      name: 'namespace',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(reference_data_harvest_total,kubernetes_namespace)',
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
      definition: 'label_values(reference_data_harvest_total{' + svc + '},module)',
      hide: 0,
      includeAll: true,
      multi: false,
      name: 'module',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(reference_data_harvest_total{' + svc + '}, module)',
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

  // --- Harvest overview ---
  overviewStat(
    'Successful modules',
    { h: 4, w: 6, x: 0, y: 0 },
    [
      query(
        'count(reference_data_harvest_last_success_timestamp{' + harvest + '} > 0)',
        'modules',
      ),
    ],
  ),

  withLogLink(
    overviewStat(
      'Failed harvests (24h)',
      { h: 4, w: 6, x: 6, y: 0 },
      [
        query(
          harvestCountInRange(
            'max_over_time(reference_data_harvest_total{' + harvest + ', outcome="failure"}[24h]) - min_over_time(reference_data_harvest_total{' + harvest + ', outcome="failure"}[24h])',
          ),
          'failures',
        ),
      ],
    ),
    true,
  )
  + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green'),
    statPanel.standardOptions.threshold.step.withColor('red')
    + statPanel.standardOptions.threshold.step.withValue(1),
  ]),

  withLogLink(
    overviewStat(
      'Partial errors (24h)',
      { h: 4, w: 6, x: 12, y: 0 },
      [
        query(
          harvestCountInRange(
            'max_over_time(reference_data_harvest_partial_errors_total{' + harvest + '}[24h]) - min_over_time(reference_data_harvest_partial_errors_total{' + harvest + '}[24h])',
          ),
          'partial errors',
        ),
      ],
    ),
    true,
  )
  + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green'),
    statPanel.standardOptions.threshold.step.withColor('orange')
    + statPanel.standardOptions.threshold.step.withValue(1),
  ]),

  overviewStat(
    'Scheduler queued tasks',
    { h: 4, w: 6, x: 18, y: 0 },
    [
      query(
        'max(executor_queued_tasks{' + svc + ', name="taskScheduler"})',
        'queued',
      ),
    ],
  )
  + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green'),
    statPanel.standardOptions.threshold.step.withColor('yellow')
    + statPanel.standardOptions.threshold.step.withValue(1),
    statPanel.standardOptions.threshold.step.withColor('red')
    + statPanel.standardOptions.threshold.step.withValue(10),
  ]),

  // --- Harvest outcomes ---
  withLogLink(
    tableLegend(
      cumulativeHarvestPanel(
        'Successful harvests',
        { h: 8, w: 12, x: 0, y: 4 },
        [
          counterQuery(
            'sum by (module, trigger) (reference_data_harvest_total{' + harvest + ', outcome="success"})',
            '{{module}} / {{trigger}}',
          ),
        ],
      ),
      ['delta', 'lastNotNull'],
    ),
  ),

  withLogLink(
    tableLegend(
      cumulativeHarvestPanel(
        'Failed harvests',
        { h: 8, w: 12, x: 12, y: 4 },
        [
          counterQuery(
            'sum by (module, reason) (reference_data_harvest_total{' + harvest + ', outcome="failure"})',
            '{{module}} / {{reason}}',
          ),
        ],
      ),
      ['delta', 'lastNotNull'],
    ),
    true,
  ),

  withLogLink(
    tableLegend(
      cumulativeHarvestPanel(
        'Skipped empty harvests',
        { h: 6, w: 12, x: 0, y: 12 },
        [
          counterQuery(
            'sum by (module, trigger) (reference_data_harvest_total{' + harvest + ', outcome="skipped_empty"})',
            '{{module}} / {{trigger}}',
          ),
        ],
      ),
      ['delta', 'lastNotNull'],
    ),
  ),

  withLogLink(
    tableLegend(
      cumulativeHarvestPanel(
        'Partial harvest errors',
        { h: 6, w: 12, x: 12, y: 12 },
        [
          counterQuery(
            'sum by (module) (reference_data_harvest_partial_errors_total{' + harvest + '})',
            '{{module}}',
          ),
        ],
      ),
      ['delta', 'lastNotNull'],
    ),
    true,
  ),

  // reference_data_harvest_duration_seconds is a summary (no _bucket), so show avg (sum/count).
  withLogLink(
    linePanel(
      'Harvest duration (avg)',
      { h: 8, w: 24, x: 0, y: 18 },
      [
        rateQuery(
          |||
            sum by (module, outcome) (rate(reference_data_harvest_duration_seconds_sum{%s, outcome="success"}[5m]))
            /
            sum by (module, outcome) (rate(reference_data_harvest_duration_seconds_count{%s, outcome="success"}[5m]))
          ||| % [harvest, harvest],
          '{{module}}',
        ),
      ],
      's',
    )
    + timeSeriesPanel.options.legend.withCalcs(['mean', 'max'])
    + timeSeriesPanel.options.legend.withDisplayMode('table')
    + timeSeriesPanel.options.legend.withPlacement('bottom'),
  ),

  barGaugePanel.new('Harvested items by module')
  + barGaugePanel.options.withDisplayMode('gradient')
  + barGaugePanel.options.withOrientation('horizontal')
  + barGaugePanel.options.withShowUnfilled(true)
  + barGaugePanel.options.withValueMode('color')
  + barGaugePanel.options.withMinVizHeight(16)
  + barGaugePanel.options.withMinVizWidth(8)
  + barGaugePanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + barGaugePanel.options.reduceOptions.withValues(false)
  + barGaugePanel.standardOptions.color.withMode('palette-classic')
  + barGaugePanel.standardOptions.withUnit('short')
  + barGaugePanel.queryOptions.withDatasource(prometheus, prometheus)
  + barGaugePanel.queryOptions.withTargets([
    query(
      'max by (module) (reference_data_harvest_items{' + harvest + '})',
      '{{module}}',
    ),
  ])
  + barGaugePanel.panelOptions.withGridPos(8, 12, 0, 26),

  linePanel(
    'Time since last successful harvest',
    { h: 8, w: 12, x: 12, y: 26 },
    [
      rateQuery(
        'max by (module) (time() - reference_data_harvest_last_success_timestamp{' + harvest + '})',
        '{{module}}',
      ),
    ],
    's',
  ),

  tablePanel.new('Module harvest status')
  + tablePanel.queryOptions.withDatasource(prometheus, prometheus)
  + tablePanel.queryOptions.withTargets([
    instantTableQuery(
      'max by (module) (reference_data_harvest_items{' + harvest + '})',
      'A',
    ),
    instantTableQuery(
      'max by (module) (time() - reference_data_harvest_last_success_timestamp{' + harvest + '})',
      'B',
    ),
    instantTableQuery(
      'sum by (module) (max_over_time(reference_data_harvest_total{' + harvest + ', outcome="failure"}[24h]) - min_over_time(reference_data_harvest_total{' + harvest + ', outcome="failure"}[24h]))',
      'C',
    ),
  ])
  + tablePanel.queryOptions.withTransformations([
    {
      id: 'merge',
      options: {},
    },
    {
      id: 'organize',
      options: {
        excludeByName: {
          Time: true,
          __name__: true,
        },
        indexByName: {
          module: 0,
          'Value #A': 1,
          'Value #B': 2,
          'Value #C': 3,
        },
        renameByName: {
          module: 'Module',
          'Value #A': 'Items',
          'Value #B': 'Since last success',
          'Value #C': 'Failures (24h)',
        },
      },
    },
  ])
  + tablePanel.standardOptions.withOverrides([
    tablePanel.standardOptions.override.byName.new('Since last success')
    + tablePanel.standardOptions.override.byName.withPropertiesFromOptions(
      tablePanel.standardOptions.withUnit('s')
    ),
    tablePanel.standardOptions.override.byName.new('Failures (24h)')
    + tablePanel.standardOptions.override.byName.withPropertiesFromOptions(
      tablePanel.standardOptions.color.withMode('thresholds')
      + tablePanel.standardOptions.thresholds.withMode('absolute')
      + tablePanel.standardOptions.thresholds.withSteps([
        tablePanel.standardOptions.threshold.step.withColor('green'),
        tablePanel.standardOptions.threshold.step.withColor('red')
        + tablePanel.standardOptions.threshold.step.withValue(1),
      ])
    ),
  ])
  + tablePanel.options.withSortBy([
    tablePanel.options.sortBy.withDisplayName('Since last success')
    + tablePanel.options.sortBy.withDesc(),
  ])
  + tablePanel.options.withShowHeader(true)
  + tablePanel.panelOptions.withGridPos(8, 24, 0, 34),

  // --- HTTP and DB ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'HTTP requests',
        { h: 8, w: 12, x: 0, y: 42 },
        [
          rateQuery(
            'sum by (status, uri, method) (floor(rate(http_server_requests_seconds_count{' + svc + ', uri!~"/actuator/.*"}[5m])*300))',
            '{{method}} {{uri}} {{status}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    linePanel(
      'HTTP request duration (avg)',
      { h: 8, w: 12, x: 12, y: 42 },
      [
        rateQuery(
          |||
            sum by (uri) (rate(http_server_requests_seconds_sum{%s, uri!~"/actuator/.*"}[5m]))
            /
            sum by (uri) (rate(http_server_requests_seconds_count{%s, uri!~"/actuator/.*"}[5m]))
          ||| % [svc, svc],
          '{{uri}}',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    linePanel(
      'HikariCP connections',
      { h: 6, w: 12, x: 0, y: 50 },
      [
        rateQuery('max(hikaricp_connections_active{' + svc + '})', 'Active'),
        rateQuery('max(hikaricp_connections_idle{' + svc + '})', 'Idle'),
        rateQuery('max(hikaricp_connections_pending{' + svc + '})', 'Pending'),
        rateQuery('max(hikaricp_connections_max{' + svc + '})', 'Max'),
      ],
    ),
  ),

  withLogLink(
    linePanel(
      'HikariCP connection timeouts',
      { h: 6, w: 12, x: 12, y: 50 },
      [
        rateQuery(
          'sum(rate(hikaricp_connections_timeout_total{' + svc + '}[5m]))',
          'Timeouts/sec',
        ),
      ],
      'ops',
    ),
    true,
  ),

])

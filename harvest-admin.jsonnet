local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local gaugePanel = g.panel.gauge;
local statPanel = g.panel.stat;

local prometheus = 'prometheus';
local ns = 'kubernetes_namespace="$namespace"';
local cbName = 'harvest-event-consumer-cb';
local listenerId = 'harvest-event-listener';
local fdkService = 'fdk-harvest-admin-service';

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

dashboard.new('FDK Harvest Admin - Run Performance Dashboard')
+ dashboard.withUid('fdk-harvest-dashboard')
+ dashboard.withTags(['harvest', 'fdk', 'harvest-admin', 'performance'])
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
      definition: 'label_values(harvest_runs_started_total,kubernetes_namespace)',
      hide: 0,
      includeAll: false,
      multi: false,
      name: 'namespace',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(harvest_runs_started_total,kubernetes_namespace)',
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
  // --- Ops status ---
  statPanel.new('Circuit breaker open')
  + statPanel.panelOptions.withGridPos(6, 6, 0, 0)
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
  + statPanel.panelOptions.withGridPos(6, 6, 6, 0)
  + statPanel.options.withGraphMode('none')
  + statPanel.options.withColorMode('background')
  + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + statPanel.options.reduceOptions.withValues(false)
  + statPanel.queryOptions.withDatasource(prometheus, prometheus)
  + statPanel.queryOptions.withTargets([
    rateQuery(
      'max(harvest_kafka_listener_paused{' + ns + ', listener_id="' + listenerId + '"})',
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

  statPanel.new('Current In-Progress Runs')
  + statPanel.panelOptions.withGridPos(6, 6, 12, 0)
  + statPanel.options.withColorMode('value')
  + statPanel.options.withGraphMode('area')
  + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + statPanel.queryOptions.withDatasource(prometheus, prometheus)
  + statPanel.queryOptions.withTargets([
    rateQuery('max(harvest_runs_current{' + ns + '})', 'current'),
  ])
  + statPanel.standardOptions.thresholds.withMode('absolute')
  + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green')
    + statPanel.standardOptions.threshold.step.withValue(0),
    statPanel.standardOptions.threshold.step.withColor('red')
    + statPanel.standardOptions.threshold.step.withValue(1),
  ]),

  gaugePanel.new('Success Rate')
  + gaugePanel.panelOptions.withGridPos(6, 6, 18, 0)
  + gaugePanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + gaugePanel.queryOptions.withDatasource(prometheus, prometheus)
  + gaugePanel.queryOptions.withTargets([
    rateQuery(
      |||
        sum(harvest_runs_completed_total{%s})
        /
        (sum(harvest_runs_completed_total{%s}) + sum(harvest_runs_failed_total{%s}) + 0.0001)
      ||| % [ns, ns, ns],
      'success',
    ),
  ])
  + gaugePanel.standardOptions.withUnit('percentunit')
  + gaugePanel.standardOptions.thresholds.withMode('absolute')
  + gaugePanel.standardOptions.thresholds.withSteps([
    gaugePanel.standardOptions.threshold.step.withColor('green')
    + gaugePanel.standardOptions.threshold.step.withValue(0),
    gaugePanel.standardOptions.threshold.step.withColor('yellow')
    + gaugePanel.standardOptions.threshold.step.withValue(0.9),
    gaugePanel.standardOptions.threshold.step.withColor('red')
    + gaugePanel.standardOptions.threshold.step.withValue(0.95),
  ]),

  // --- Reliability ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Harvest Runs Overview',
        { h: 8, w: 12, x: 0, y: 6 },
        [
          rateQuery(
            'sum(floor(rate(harvest_runs_started_total{' + ns + '}[5m])*300))',
            'Started',
          ),
          rateQuery(
            'sum(floor(rate(harvest_runs_completed_total{' + ns + '}[5m])*300))',
            'Completed',
          ),
          rateQuery(
            'sum by (reason) (floor(rate(harvest_runs_failed_total{' + ns + '}[5m])*300))',
            'Failed: {{reason}}',
          ),
        ],
      ),
      ['lastNotNull', 'max'],
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Event errors',
        { h: 8, w: 12, x: 12, y: 6 },
        [
          rateQuery(
            'sum by (phase, datatype) (floor(rate(harvest_events_errors_total{' + ns + '}[5m])*300))',
            '{{phase}} / {{datatype}}',
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
        { h: 8, w: 12, x: 0, y: 14 },
        [
          rateQuery(
            'sum by (phase, datatype) (floor(rate(harvest_events_processing_failed_total{' + ns + '}[5m])*300))',
            '{{phase}} / {{datatype}}',
          ),
        ],
      ),
    ),
    true,
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Event publish failures',
        { h: 8, w: 12, x: 12, y: 14 },
        [
          rateQuery(
            'sum by (phase, datatype) (floor(rate(harvest_events_publish_failed_total{' + ns + '}[5m])*300))',
            '{{phase}} / {{datatype}}',
          ),
        ],
      ),
    ),
    true,
  ),

  // --- Kafka and circuit breaker ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Kafka event processing',
        { h: 6, w: 12, x: 0, y: 22 },
        [
          rateQuery(
            'sum by (result) (floor(rate(spring_kafka_listener_seconds_count{' + ns + ', name=~"' + listenerId + '.*"}[5m])*300))',
            'listener:{{result}}',
          ),
          rateQuery(
            'sum by (phase) (floor(rate(harvest_events_processing_failed_total{' + ns + '}[5m])*300))',
            'processing_failed:{{phase}}',
          ),
        ],
      ),
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Event publish',
        { h: 6, w: 12, x: 12, y: 22 },
        [
          rateQuery(
            'sum by (result) (floor(rate(spring_kafka_template_seconds_count{' + ns + '}[5m])*300))',
            'publish:{{result}}',
          ),
          rateQuery(
            'sum by (phase, datatype) (floor(rate(harvest_events_publish_failed_total{' + ns + '}[5m])*300))',
            'failed:{{phase}}/{{datatype}}',
          ),
        ],
      ),
    ),
  ),

  withLogLink(
    stackedBarPanel(
      'Circuit breaker not permitted calls',
      { h: 6, w: 12, x: 0, y: 28 },
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
      { h: 6, w: 12, x: 12, y: 28 },
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

  // --- Performance ---
  withLogLink(
    linePanel(
      'Event Processing Rate',
      { h: 8, w: 12, x: 0, y: 34 },
      [
        rateQuery(
          'sum(rate(harvest_events_processed_total{' + ns + '}[5m]))',
          'Events/sec',
        ),
      ],
      'ops',
    )
    + timeSeriesPanel.options.legend.withCalcs(['mean', 'max'])
    + timeSeriesPanel.options.legend.withDisplayMode('table')
    + timeSeriesPanel.options.legend.withPlacement('bottom')
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Events by Phase (Rate)',
        { h: 8, w: 12, x: 12, y: 34 },
        [
          rateQuery(
            'sum by (phase) (floor(rate(harvest_events_by_phase_total{' + ns + '}[5m])*300))',
            '{{phase}}',
          ),
        ],
      ),
    ),
  ),

  withLogLink(
    linePanel(
      'Phase Durations - Sequential & Parallel (by Data Type)',
      { h: 8, w: 24, x: 0, y: 42 },
      [
        rateQuery(
          'histogram_quantile(0.50, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="INITIATING"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - INIT (p50)',
        ),
        rateQuery(
          'histogram_quantile(0.50, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="HARVESTING"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - HARVESTING (p50)',
        ),
        rateQuery(
          'histogram_quantile(0.50, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="REASONING"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - REASONING (p50)',
        ),
        rateQuery(
          'histogram_quantile(0.50, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="RDF_PARSING"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - RDF_PARSING (p50)',
        ),
        rateQuery(
          'histogram_quantile(0.95, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="SEARCH_PROCESSING"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - SEARCH_PROCESSING (p95)',
        ),
        rateQuery(
          'histogram_quantile(0.95, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="AI_SEARCH_PROCESSING"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - AI_SEARCH_PROCESSING (p95)',
        ),
        rateQuery(
          'histogram_quantile(0.95, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="RESOURCE_PROCESSING"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - RESOURCE_PROCESSING (p95)',
        ),
        rateQuery(
          'histogram_quantile(0.95, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="SPARQL_PROCESSING"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - SPARQL_PROCESSING (p95)',
        ),
        rateQuery(
          'histogram_quantile(0.50, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="TOTAL"}[5m])) by (le, datatype)) * 1000',
          '{{datatype}} - TOTAL (p50)',
        ),
      ],
      'ms',
    )
    + timeSeriesPanel.options.legend.withCalcs(['mean', 'p95', 'p99'])
    + timeSeriesPanel.options.legend.withDisplayMode('table')
    + timeSeriesPanel.options.legend.withPlacement('bottom')
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Events by Data Type (Rate)',
        { h: 8, w: 12, x: 0, y: 50 },
        [
          rateQuery(
            'sum by (datatype) (floor(rate(harvest_events_by_datatype_total{' + ns + '}[5m])*300))',
            '{{datatype}}',
          ),
        ],
      ),
    ),
  ),

  withLogLink(
    linePanel(
      'Total Processing Time per Run',
      { h: 8, w: 12, x: 12, y: 50 },
      [
        rateQuery(
          'histogram_quantile(0.50, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="TOTAL"}[30m])) by (le, datatype)) * 1000',
          '{{datatype}} - Total (p50)',
        ),
        rateQuery(
          'histogram_quantile(0.95, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="TOTAL"}[30m])) by (le, datatype)) * 1000',
          '{{datatype}} - Total (p95)',
        ),
        rateQuery(
          'histogram_quantile(0.99, sum(rate(harvest_phase_duration_seconds_bucket{' + ns + ', phase="TOTAL"}[30m])) by (le, datatype)) * 1000',
          '{{datatype}} - Total (p99)',
        ),
      ],
      'ms',
    )
    + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('auto')
    + timeSeriesPanel.options.legend.withCalcs(['mean', 'max', 'lastNotNull'])
    + timeSeriesPanel.options.legend.withDisplayMode('table')
    + timeSeriesPanel.options.legend.withPlacement('bottom')
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Resources Processed per Run',
        { h: 8, w: 12, x: 0, y: 58 },
        [
          rateQuery(
            'sum by (datatype) (increase(harvest_run_resources_total_resources_sum{' + ns + '}[24h])) / sum by (datatype) (increase(harvest_run_resources_total_resources_count{' + ns + '}[24h]))',
            '{{datatype}} - Avg Total Resources',
          ),
          rateQuery(
            'sum by (datatype) (increase(harvest_run_resources_processed_resources_sum{' + ns + '}[24h])) / sum by (datatype) (increase(harvest_run_resources_processed_resources_count{' + ns + '}[24h]))',
            '{{datatype}} - Avg Processed Resources',
          ),
        ],
      ),
      ['mean', 'max'],
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Phase resource shortfall',
        { h: 8, w: 12, x: 12, y: 58 },
        [
          rateQuery(
            'sum by (phase, datatype) (floor(rate(harvest_run_phase_resource_shortfall_resources_sum{' + ns + '}[5m])*300))',
            '{{phase}} / {{datatype}}',
          ),
        ],
      ),
    ),
  ),

  statPanel.new('Total Resources (In Progress)')
  + statPanel.panelOptions.withGridPos(8, 8, 0, 66)
  + statPanel.options.withColorMode('value')
  + statPanel.options.withGraphMode('area')
  + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + statPanel.queryOptions.withDatasource(prometheus, prometheus)
  + statPanel.queryOptions.withTargets([
    rateQuery('max(harvest_runs_total_resources{' + ns + '})', 'total'),
  ])
  + statPanel.standardOptions.thresholds.withMode('absolute')
  + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green')
    + statPanel.standardOptions.threshold.step.withValue(0),
  ]),

  statPanel.new('Processed Resources')
  + statPanel.panelOptions.withGridPos(8, 16, 8, 66)
  + statPanel.options.withColorMode('value')
  + statPanel.options.withGraphMode('area')
  + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + statPanel.queryOptions.withDatasource(prometheus, prometheus)
  + statPanel.queryOptions.withTargets([
    rateQuery('max(harvest_runs_processed_resources{' + ns + '})', 'In Progress'),
    rateQuery('max(harvest_runs_completed_processed_resources{' + ns + '})', 'Completed (24h)'),
    rateQuery('max(harvest_runs_all_processed_resources{' + ns + '})', 'All (In Progress + Completed 24h)'),
  ])
  + statPanel.standardOptions.thresholds.withMode('absolute')
  + statPanel.standardOptions.thresholds.withSteps([
    statPanel.standardOptions.threshold.step.withColor('green')
    + statPanel.standardOptions.threshold.step.withValue(0),
  ]),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Events per Data Source URL (by Phase and Type)',
        { h: 8, w: 24, x: 0, y: 74 },
        [
          rateQuery(
            'sum by (datasource_url, phase, datatype) (floor(rate(harvest_events_by_datasource_url_total{' + ns + '}[5m])*300))',
            '{{datasource_url}} - {{datatype}} - {{phase}}',
          ),
        ],
      ),
    ),
  ),
])

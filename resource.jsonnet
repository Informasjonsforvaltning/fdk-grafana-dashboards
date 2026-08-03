local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local barGaugePanel = g.panel.barGauge;
local pieChartPanel = g.panel.pieChart;
local tablePanel = g.panel.table;
local statPanel = g.panel.stat;

local prometheus = 'prometheus';
local ns = 'kubernetes_namespace="$namespace"';
local fdkService = 'fdk-resource-service';
local cbNameRegex = 'rdfParseConsumer|conceptConsumer|datasetConsumer|dataServiceConsumer|informationModelConsumer|serviceConsumer|eventConsumer';

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

local instantTableQuery(expr, refId) =
  prometheusQuery.new(prometheus, expr)
  + prometheusQuery.withFormat('table')
  + prometheusQuery.withInstant()
  + prometheusQuery.withRange(false)
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
  + timeSeriesPanel.standardOptions.color.withMode('palette-classic')
  + timeSeriesPanel.standardOptions.withUnit(unit)
  + timeSeriesPanel.queryOptions.withDatasource(prometheus, prometheus)
  + timeSeriesPanel.queryOptions.withInterval('2m')
  + timeSeriesPanel.queryOptions.withTargets(targets)
  + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
  + timeSeriesPanel.options.legend.withShowLegend(true)
  + timeSeriesPanel.options.legend.withDisplayMode('list')
  + timeSeriesPanel.options.legend.withPlacement('bottom');

local tableLegend(panel, calcs=['sum']) =
  panel
  + timeSeriesPanel.options.legend.withCalcs(calcs)
  + timeSeriesPanel.options.legend.withDisplayMode('table')
  + timeSeriesPanel.options.legend.withPlacement('bottom')
  + timeSeriesPanel.options.legend.withShowLegend(true);

local overviewStat(title, gridPos, targets, unit='short', graphMode='none') =
  statPanel.new(title)
  + statPanel.options.withColorMode('value')
  + statPanel.options.withGraphMode(graphMode)
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

dashboard.new('FDK Resource Service')
+ dashboard.withUid('70499678-88db-495a-b8e4-f8d819fa0274')
+ dashboard.withTags(['fdk', 'resource', 'union-graphs', 'prometheus'])
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
      definition: 'label_values(spring_kafka_listener_seconds_count,kubernetes_namespace)',
      hide: 0,
      includeAll: false,
      multi: false,
      name: 'namespace',
      options: [],
      query: {
        qryType: 1,
        query: 'label_values(spring_kafka_listener_seconds_count,kubernetes_namespace)',
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
  statusStat(
    'Circuit breaker open',
    { h: 6, w: 6, x: 0, y: 0 },
    'max(resilience4j_circuitbreaker_state{' + ns + ', name=~"' + cbNameRegex + '", state="open"})',
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
    'Listeners paused (CB open)',
    { h: 6, w: 6, x: 6, y: 0 },
    'max(resilience4j_circuitbreaker_state{' + ns + ', name=~"' + cbNameRegex + '", state="open"})',
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
    'Order Status Overview',
    { h: 6, w: 12, x: 12, y: 0 },
    [
      query('max(union_graph_orders_pending{' + ns + '})', 'Pending', 'A'),
      query('max(union_graph_orders_processing{' + ns + '})', 'Processing', 'B'),
      query('max(union_graph_orders_completed_total{' + ns + '})', 'Completed', 'C'),
      query('max(union_graph_orders_failed_total{' + ns + '})', 'Failed', 'D'),
    ],
  )
  + statPanel.standardOptions.color.withMode('palette-classic')
  + statPanel.options.withGraphMode('none'),

  // --- Kafka and circuit breaker ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Kafka consumer outcomes',
        { h: 6, w: 12, x: 0, y: 6 },
        [
          rateQuery(
            'sum by (outcome, topic) (floor(rate(kafka_consumer_events_total{' + ns + '}[5m])*300))',
            '{{topic}} / {{outcome}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Spring Kafka listener',
        { h: 6, w: 12, x: 12, y: 6 },
        [
          rateQuery(
            'sum by (result) (floor(rate(spring_kafka_listener_seconds_count{' + ns + '}[5m])*300))',
            'listener:{{result}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Event publish',
        { h: 6, w: 12, x: 0, y: 12 },
        [
          rateQuery(
            'sum by (result) (floor(rate(spring_kafka_template_seconds_count{' + ns + ', name="harvestEventKafkaTemplate"}[5m])*300))',
            'publish:{{result}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    linePanel(
      'Spring Kafka listener duration',
      { h: 6, w: 12, x: 12, y: 12 },
      [
        rateQuery(
          |||
            sum(rate(spring_kafka_listener_seconds_sum{%s}[5m]))
            /
            sum(rate(spring_kafka_listener_seconds_count{%s}[5m]))
          ||| % [ns, ns],
          'Average',
        ),
        rateQuery(
          'max(spring_kafka_listener_seconds_max{' + ns + '})',
          'Max',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    stackedBarPanel(
      'Circuit breaker not permitted calls',
      { h: 6, w: 12, x: 0, y: 18 },
      [
        rateQuery(
          'sum by (name) (floor(rate(resilience4j_circuitbreaker_not_permitted_calls_total{' + ns + ', name=~"' + cbNameRegex + '"}[5m])*300))',
          '{{name}}',
        ),
      ],
    )
    + timeSeriesPanel.options.legend.withShowLegend(true),
  ),

  withLogLink(
    linePanel(
      'Circuit breaker failure rate',
      { h: 6, w: 12, x: 12, y: 18 },
      [
        rateQuery(
          'max by (name) (resilience4j_circuitbreaker_failure_rate{' + ns + ', name=~"' + cbNameRegex + '"})',
          '{{name}}',
        ),
      ],
      'percent',
    )
    + {
      fieldConfig+: {
        defaults+: {
          max: 100,
          min: 0,
        },
      },
    },
  ),

  // --- Resource store and RDF ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Resources stored',
        { h: 6, w: 12, x: 0, y: 24 },
        [
          rateQuery(
            'sum by (type) (floor(rate(resources_stored_total{' + ns + '}[5m])*300))',
            '{{type}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Resources deleted',
        { h: 6, w: 12, x: 12, y: 24 },
        [
          rateQuery(
            'sum by (type) (floor(rate(resources_deleted_total{' + ns + '}[5m])*300))',
            '{{type}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
    true,
  ),

  withLogLink(
    linePanel(
      'Store JSON duration',
      { h: 6, w: 12, x: 0, y: 30 },
      [
        rateQuery(
          |||
            sum by (type) (rate(store_resource_json_seconds_sum{%s}[5m]))
            /
            sum by (type) (rate(store_resource_json_seconds_count{%s}[5m]))
          ||| % [ns, ns],
          '{{type}}',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    linePanel(
      'Store JSON-LD duration',
      { h: 6, w: 12, x: 12, y: 30 },
      [
        rateQuery(
          |||
            sum by (type) (rate(store_resource_jsonld_seconds_sum{%s}[5m]))
            /
            sum by (type) (rate(store_resource_jsonld_seconds_count{%s}[5m]))
          ||| % [ns, ns],
          '{{type}}',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'RDF conversion rate',
        { h: 6, w: 12, x: 0, y: 36 },
        [
          rateQuery(
            'sum by (from, to, outcome) (floor(rate(rdf_conversion_duration_seconds_count{' + ns + '}[5m])*300))',
            '{{from}}→{{to}} / {{outcome}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    linePanel(
      'RDF conversion duration',
      { h: 6, w: 12, x: 12, y: 36 },
      [
        rateQuery(
          |||
            sum by (from, to) (rate(rdf_conversion_duration_seconds_sum{%s, outcome="success"}[5m]))
            /
            sum by (from, to) (rate(rdf_conversion_duration_seconds_count{%s, outcome="success"}[5m]))
          ||| % [ns, ns],
          '{{from}}→{{to}}',
        ),
      ],
      's',
    ),
  ),

  // --- Union graphs ---
  withLogLink(
    linePanel(
      'Order lifecycle rate',
      { h: 8, w: 12, x: 0, y: 42 },
      [
        rateQuery(
          'sum without (instance, pod) (rate(union_graph_orders_total{' + ns + '}[5m]))',
          'Created',
        ),
        rateQuery(
          'sum without (instance, pod) (rate(union_graph_orders_completed_total{' + ns + '}[5m]))',
          'Completed',
        ),
        rateQuery(
          'sum without (instance, pod) (rate(union_graph_orders_failed_total{' + ns + '}[5m]))',
          'Failed',
        ),
        rateQuery(
          'sum without (instance, pod) (rate(union_graph_orders_deleted_total{' + ns + '}[5m]))',
          'Deleted',
        ),
        rateQuery(
          'sum without (instance, pod) (rate(union_graph_orders_reset_total{' + ns + '}[5m]))',
          'Reset',
        ),
      ],
      'ops',
    ),
  ),

  barGaugePanel.new('Processing Progress (Current Orders)')
  + barGaugePanel.options.withDisplayMode('gradient')
  + barGaugePanel.options.withOrientation('horizontal')
  + barGaugePanel.options.withShowUnfilled(true)
  + barGaugePanel.options.withValueMode('color')
  + barGaugePanel.options.withMinVizHeight(16)
  + barGaugePanel.options.withMinVizWidth(8)
  + barGaugePanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + barGaugePanel.options.reduceOptions.withValues(false)
  + barGaugePanel.standardOptions.color.withMode('thresholds')
  + barGaugePanel.standardOptions.withUnit('percent')
  + barGaugePanel.standardOptions.withMin(0)
  + barGaugePanel.standardOptions.withMax(100)
  + barGaugePanel.standardOptions.thresholds.withMode('absolute')
  + barGaugePanel.standardOptions.thresholds.withSteps([
    barGaugePanel.standardOptions.threshold.step.withColor('blue'),
    barGaugePanel.standardOptions.threshold.step.withColor('yellow')
    + barGaugePanel.standardOptions.threshold.step.withValue(50),
    barGaugePanel.standardOptions.threshold.step.withColor('green')
    + barGaugePanel.standardOptions.threshold.step.withValue(90),
  ])
  + barGaugePanel.queryOptions.withDatasource(prometheus, prometheus)
  + barGaugePanel.queryOptions.withTargets([
    query(
      'sum by (order_id) (union_graph_processing_progress_ratio{' + ns + ', order_id!=""}) * 100',
      '{{order_id}}',
      'A',
    )
    + prometheusQuery.withRange(true),
  ])
  + barGaugePanel.panelOptions.withGridPos(8, 12, 12, 42),

  withLogLink(
    linePanel(
      'Resources Processed vs Total',
      { h: 8, w: 12, x: 0, y: 50 },
      [
        rateQuery(
          'sum by (order_id) (union_graph_processing_resources_processed{' + ns + ', order_id!=""})',
          '{{order_id}} - Processed',
        ),
        rateQuery(
          'sum by (order_id) (union_graph_processing_resources{' + ns + ', order_id!=""})',
          '{{order_id}} - Total',
        ),
      ],
    ),
  ),

  withLogLink(
    linePanel(
      'Processing Duration',
      { h: 8, w: 12, x: 12, y: 50 },
      [
        rateQuery(
          |||
            sum(rate(union_graph_processing_duration_seconds_sum{%s}[5m]))
            /
            sum(rate(union_graph_processing_duration_seconds_count{%s}[5m]))
          ||| % [ns, ns],
          'Average',
        ),
        rateQuery(
          'max(union_graph_processing_duration_seconds_max{' + ns + '})',
          'Max',
        ),
        rateQuery(
          'sum(rate(union_graph_processing_duration_seconds_count{' + ns + '}[5m]))',
          'Count/sec',
        ),
      ],
      's',
    ),
  ),

  pieChartPanel.new('Failed Orders by Reason')
  + pieChartPanel.options.withPieType('pie')
  + pieChartPanel.options.reduceOptions.withCalcs(['lastNotNull'])
  + pieChartPanel.options.reduceOptions.withValues(false)
  + pieChartPanel.options.legend.withDisplayMode('table')
  + pieChartPanel.options.legend.withPlacement('right')
  + pieChartPanel.options.legend.withShowLegend(true)
  + pieChartPanel.options.legend.withValues(['value'])
  + pieChartPanel.options.tooltip.withMode('single')
  + pieChartPanel.options.tooltip.withSort('none')
  + pieChartPanel.standardOptions.color.withMode('palette-classic')
  + pieChartPanel.queryOptions.withDatasource(prometheus, prometheus)
  + pieChartPanel.queryOptions.withTargets([
    query('sum by (reason) (union_graph_orders_failed_total{' + ns + '})', '{{reason}}', 'A'),
  ])
  + pieChartPanel.panelOptions.withGridPos(8, 12, 0, 58),

  overviewStat(
    'Processing Time Statistics',
    { h: 8, w: 12, x: 12, y: 58 },
    [
      query(
        |||
          sum(rate(union_graph_processing_duration_seconds_sum{%s}[5m]))
          /
          sum(rate(union_graph_processing_duration_seconds_count{%s}[5m]))
        ||| % [ns, ns],
        'Average',
        'A',
      ),
      query('max(union_graph_processing_duration_seconds_max{' + ns + '})', 'Max', 'B'),
      query('sum(rate(union_graph_processing_duration_seconds_count{' + ns + '}[5m]))', 'Count/sec', 'C'),
    ],
    's',
    'area',
  ),

  overviewStat(
    'DataServices Expanded',
    { h: 6, w: 12, x: 0, y: 66 },
    [
      query('max(union_graph_data_services_expanded_total{' + ns + '})', 'Total Expanded', 'A'),
      query('sum by () (rate(union_graph_data_services_expanded_total{' + ns + '}[5m]))', 'Expansion Rate', 'B'),
    ],
    'short',
    'area',
  ),

  withLogLink(
    linePanel(
      'Resources Processed Rate',
      { h: 6, w: 12, x: 12, y: 66 },
      [
        rateQuery(
          'sum without (instance, pod) (rate(union_graph_resources_processed_total{' + ns + '}[5m]))',
          'Resources/sec',
        ),
      ],
      'ops',
    ),
  ),

  withLogLink(
    tableLegend(
      stackedBarPanel(
        'Webhook calls by status',
        { h: 8, w: 12, x: 0, y: 72 },
        [
          rateQuery(
            'sum by (success, status) (floor(rate(union_graph_webhook_calls_total{' + ns + '}[5m])*300))',
            'success={{success}} / {{status}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    linePanel(
      'Webhook Call Duration',
      { h: 8, w: 12, x: 12, y: 72 },
      [
        rateQuery(
          |||
            sum(rate(union_graph_webhook_call_duration_seconds_sum{%s}[5m]))
            /
            sum(rate(union_graph_webhook_call_duration_seconds_count{%s}[5m]))
          ||| % [ns, ns],
          'Average',
        ),
        rateQuery(
          'max(union_graph_webhook_call_duration_seconds_max{' + ns + '})',
          'Max',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    linePanel(
      'Union graph executor',
      { h: 6, w: 12, x: 0, y: 80 },
      [
        rateQuery('max(union_graph_executor_active_threads{' + ns + '})', 'Active threads'),
        rateQuery('max(union_graph_executor_pool_size{' + ns + '})', 'Pool size'),
        rateQuery('max(union_graph_executor_queue_size{' + ns + '})', 'Queue size'),
        rateQuery('max(union_graph_executor_queue_remaining{' + ns + '})', 'Queue remaining'),
      ],
    ),
  ),

  withLogLink(
    linePanel(
      'Union graph batch duration',
      { h: 6, w: 12, x: 12, y: 80 },
      [
        rateQuery(
          |||
            sum(rate(union_graph_batch_duration_seconds_sum{%s}[5m]))
            /
            sum(rate(union_graph_batch_duration_seconds_count{%s}[5m]))
          ||| % [ns, ns],
          'Average',
        ),
        rateQuery(
          'max(union_graph_batch_duration_seconds_max{' + ns + '})',
          'Max',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    linePanel(
      'Union graph snapshot bytes',
      { h: 6, w: 12, x: 0, y: 86 },
      [
        rateQuery(
          |||
            sum(rate(union_graph_snapshot_bytes_sum{%s}[5m]))
            /
            sum(rate(union_graph_snapshot_bytes_count{%s}[5m]))
          ||| % [ns, ns],
          'Avg size',
        ),
        rateQuery(
          'sum(rate(union_graph_snapshot_bytes_sum{' + ns + '}[5m]))',
          'Bytes/sec',
        ),
      ],
      'bytes',
    ),
  ),

  tablePanel.new('Current Processing Orders Details')
  + tablePanel.queryOptions.withDatasource(prometheus, prometheus)
  + tablePanel.queryOptions.withTargets([
    instantTableQuery(
      'sum by (order_id) (union_graph_processing_progress_ratio{' + ns + ', order_id!=""}) * 100',
      'A',
    ),
    instantTableQuery(
      'sum by (order_id) (union_graph_processing_resources_processed{' + ns + ', order_id!=""})',
      'B',
    ),
    instantTableQuery(
      'sum by (order_id) (union_graph_processing_resources{' + ns + ', order_id!=""})',
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
          'Value #A': 1,
          'Value #B': 2,
          'Value #C': 3,
          order_id: 0,
        },
        renameByName: {
          'Value #A': 'Progress %',
          'Value #B': 'Processed',
          'Value #C': 'Total',
          order_id: 'Order ID',
        },
      },
    },
  ])
  + tablePanel.standardOptions.withOverrides([
    tablePanel.standardOptions.override.byName.new('Progress %')
    + tablePanel.standardOptions.override.byName.withPropertiesFromOptions(
      tablePanel.standardOptions.withUnit('percent')
      + tablePanel.standardOptions.withMin(0)
      + tablePanel.standardOptions.withMax(100)
    ),
  ])
  + tablePanel.options.withSortBy([
    tablePanel.options.sortBy.withDisplayName('Progress %')
    + tablePanel.options.sortBy.withDesc(),
  ])
  + tablePanel.options.withShowHeader(true)
  + tablePanel.panelOptions.withGridPos(10, 12, 12, 86),

  // --- HTTP and DB ---
  withLogLink(
    tableLegend(
      stackedBarPanel(
        'HTTP /v1 requests',
        { h: 8, w: 12, x: 0, y: 96 },
        [
          rateQuery(
            'sum by (status, uri, method) (floor(rate(http_server_requests_seconds_count{' + ns + ', uri=~"/v1/.*"}[5m])*300))',
            '{{method}} {{uri}} {{status}}',
          ),
        ],
      ),
      ['sum', 'lastNotNull'],
    ),
  ),

  withLogLink(
    linePanel(
      'HTTP /v1 duration',
      { h: 8, w: 12, x: 12, y: 96 },
      [
        rateQuery(
          |||
            sum by (uri) (rate(http_server_requests_seconds_sum{%s, uri=~"/v1/.*"}[5m]))
            /
            sum by (uri) (rate(http_server_requests_seconds_count{%s, uri=~"/v1/.*"}[5m]))
          ||| % [ns, ns],
          '{{uri}}',
        ),
      ],
      's',
    ),
  ),

  withLogLink(
    linePanel(
      'HikariCP connections',
      { h: 6, w: 12, x: 0, y: 104 },
      [
        rateQuery('max(hikaricp_connections_active{' + ns + '})', 'Active'),
        rateQuery('max(hikaricp_connections_idle{' + ns + '})', 'Idle'),
        rateQuery('max(hikaricp_connections_pending{' + ns + '})', 'Pending'),
        rateQuery('max(hikaricp_connections_max{' + ns + '})', 'Max'),
      ],
    ),
  ),

  withLogLink(
    linePanel(
      'HikariCP timeouts',
      { h: 6, w: 12, x: 12, y: 104 },
      [
        rateQuery(
          'sum(rate(hikaricp_connections_timeout_total{' + ns + '}[5m]))',
          'Timeouts/sec',
        ),
      ],
      'ops',
    ),
    true,
  ),

  withLogLink(
    linePanel(
      'Error log rate',
      { h: 6, w: 24, x: 0, y: 110 },
      [
        rateQuery(
          'sum(rate(logback_events_total{' + ns + ', level="error"}[5m]))',
          'Errors/sec',
        ),
      ],
      'ops',
    ),
    true,
  ),
])

local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local prometheusQuery = g.query.prometheus;
local timeSeriesPanel = g.panel.timeSeries;
local barGaugePanel = g.panel.barGauge;

local statPanel = g.panel.stat;
local util = g.util;

local prometheus = 'prometheus';

local logExplorerUrl(errorOnly=false) =
  'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT'
  + (if errorOnly then '%0Aseverity%3DERROR' else '')
  + ';aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod';

local withLogLink(panel, errorOnly=false) =
  panel
  + {
    fieldConfig+: {
      defaults+: {
        links: [
          {
            targetBlank: true,
            title: 'View in Log Explorer',
            url: logExplorerUrl(errorOnly),
          },
        ],
      },
    },
  };

local rateQuery(expr, legend) =
  prometheusQuery.new(prometheus, expr)
  + prometheusQuery.withIntervalFactor(2)
  + prometheusQuery.withLegendFormat(legend);

local stackedPanel(title, gridPos, targets, legend=true) =
  timeSeriesPanel.new(title)
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
  + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
  + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
  + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: 'normal', group: 'A' })
  + timeSeriesPanel.queryOptions.withDatasource(prometheus, prometheus)
  + timeSeriesPanel.queryOptions.withInterval('2m')
  + timeSeriesPanel.queryOptions.withTargets(targets)
  + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
  + timeSeriesPanel.options.legend.withShowLegend(legend);

local linePanel(title, gridPos, targets, legend=false, unit='short') =
  timeSeriesPanel.new(title)
  + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
  + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints('never')
  + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls('true')
  + timeSeriesPanel.standardOptions.withUnit(unit)
  + timeSeriesPanel.queryOptions.withDatasource(prometheus, prometheus)
  + timeSeriesPanel.queryOptions.withInterval('2m')
  + timeSeriesPanel.queryOptions.withTargets(targets)
  + timeSeriesPanel.panelOptions.withGridPos(gridPos.h, gridPos.w, gridPos.x, gridPos.y)
  + timeSeriesPanel.options.legend.withShowLegend(legend);

dashboard.new('FDK RDF Parsing')
+ dashboard.withTags(['rdfparsing','harvesting'])
+ dashboard.time.withFrom('now-12h')
+ dashboard.time.withTo('now')
+ dashboard.withTimezone('browser')
+ dashboard.withTemplating({
   "list": [
     {
     "current": {
       "selected": false,
       "text": "staging",
       "value": "staging"
     },
     "datasource": {
       "type": "prometheus",
       "uid": "prometheus"
     },
     "definition": "label_values(processed_messages,kubernetes_namespace)",
     "hide": 0,
     "includeAll": false,
     "multi": false,
     "name": "namespace",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(rdf_parse_seconds_sum,kubernetes_namespace)",
       "refId": "PrometheusVariableQueryEditor-VariableQuery"
     },
     "refresh": 1,
     "regex": "",
     "skipUrlSync": false,
     "sort": 0,
     "type": "query"
   },
   {
     "allValue": ".*",
     "current": {
       "selected": false,
       "text": "All",
       "value": "$__all"
     },
     "datasource": {
       "type": "prometheus",
       "uid": "prometheus"
     },
     "definition": "label_values(rdf_parse_seconds_sum,type)",
     "hide": 0,
     "includeAll": true,
     "multi": false,
     "name": "type",
     "options": [],
     "query": {
       "qryType": 1,
       "query": "label_values(rdf_parse_seconds_sum,type)",
       "refId": "PrometheusVariableQueryEditor-VariableQuery"
     },
     "refresh": 1,
     "regex": "",
     "skipUrlSync": false,
     "sort": 0,
     "type": "query"
   }]
 })
+ dashboard.withPanels([
    timeSeriesPanel.new('Successful parsings')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (type, kubernetes_namespace, fdk_service) (rate(rdf_parse_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300)
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{type}}
            |||)
          ])
          + timeSeriesPanel.panelOptions.withGridPos(6, 12, 0, 0)
          + timeSeriesPanel.options.legend.withShowLegend(false)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Failed parsings')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.fieldConfig.defaults.custom.withStacking({ mode: "normal", group: "A" })
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'prometheus',
              |||
                sum by (type, fdk_service, kubernetes_namespace) (rate(rdf_parse_error{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300)
              |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{type}}
            |||)
          ])
        + timeSeriesPanel.panelOptions.withGridPos(6, 12, 12, 0)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + {
          fieldConfig+: {
            defaults+: {
              links: [
                {
                  targetBlank: true,
                  title: 'View in Log Explorer',
                  url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT%0Aseverity%3DERROR;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                }
              ]
           }
        }
      },

    timeSeriesPanel.new('Parsing time in seconds')
        + timeSeriesPanel.fieldConfig.defaults.custom.withLineWidth(1)
        + timeSeriesPanel.fieldConfig.defaults.custom.withShowPoints("never")
        + timeSeriesPanel.fieldConfig.defaults.custom.withSpanNulls("true")
        + timeSeriesPanel.panelOptions.withGridPos(8, 24, 0, 12)
        + timeSeriesPanel.options.legend.withShowLegend(false)
        + timeSeriesPanel.queryOptions.withDatasource('prometheus', 'prometheus')
        + timeSeriesPanel.queryOptions.withInterval('2m')
        + timeSeriesPanel.queryOptions.withTargets([
            prometheusQuery.new(
              'promehteus',
                |||
                    sum by (type, fdk_service, kubernetes_namespace) (rate(rdf_parse_seconds_sum{kubernetes_namespace="$namespace", type=~"$type"}[5m])/rate(rdf_parse_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m]))
                |||
            )
            + prometheusQuery.withIntervalFactor(2)
            + prometheusQuery.withLegendFormat(|||
              {{type}}
            |||)
          ])
        + {
              fieldConfig+: {
                defaults+: {
                  links: [
                    {
                      targetBlank: true,
                      title: 'View in Log Explorer',
                      url: 'https://console.cloud.google.com/logs/query;query=resource.type%3D%22k8s_container%22%0Aresource.labels.location%3D%22europe-north1-a%22%0Aresource.labels.namespace_name%3D%22${__field.labels.kubernetes_namespace}%22%0Alabels.k8s-pod%2Ffdk_service%3D%22${__field.labels.fdk_service}%22%20severity%3E%3DDEFAULT;aroundTime=${__value.time:date:iso:YYYY-MM-DDTHH:mm:ssZ}?project=digdir-fdk-prod'
                    }
                  ]
               }
            }
          },

    // --- Ops status ---
    statPanel.new('Circuit breaker open')
        + statPanel.panelOptions.withGridPos(6, 12, 0, 20)
        + statPanel.options.withGraphMode('none')
        + statPanel.options.withColorMode('background')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.options.reduceOptions.withValues(false)
        + statPanel.queryOptions.withDatasource(prometheus, prometheus)
        + statPanel.queryOptions.withTargets([
            rateQuery(
              'max by (name) (resilience4j_circuitbreaker_state{kubernetes_namespace="$namespace", state="open"})',
              '{{name}}',
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
        + statPanel.panelOptions.withGridPos(6, 12, 12, 20)
        + statPanel.options.withGraphMode('none')
        + statPanel.options.withColorMode('background')
        + statPanel.options.reduceOptions.withCalcs(['lastNotNull'])
        + statPanel.options.reduceOptions.withValues(false)
        + statPanel.queryOptions.withDatasource(prometheus, prometheus)
        + statPanel.queryOptions.withTargets([
            rateQuery(
              'max by (listener) (kafka_listener_paused{kubernetes_namespace="$namespace"})',
              '{{listener}}',
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

    // --- Kafka and circuit breaker ---
    withLogLink(
      stackedPanel(
        'Kafka event processing',
        { h: 6, w: 12, x: 0, y: 26 },
        [
          rateQuery(
            'sum by (type, result, fdk_service, kubernetes_namespace) (floor(rate(rdf_parse_event_processing_total{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300))',
            '{{type}}:{{result}}',
          ),
        ],
      ),
    ),

    withLogLink(
      stackedPanel(
        'Event publish (parsed + harvest)',
        { h: 6, w: 12, x: 12, y: 26 },
        [
          rateQuery(
            'sum by (kind, type, status, reason, fdk_service, kubernetes_namespace) (floor(rate(rdf_parse_event_publish_total{kubernetes_namespace="$namespace"}[5m])*300))',
            '{{kind}}:{{type}} ({{status}}/{{reason}})',
          ),
        ],
      ),
      true,
    ),

    withLogLink(
      stackedPanel(
        'Circuit breaker not permitted calls',
        { h: 6, w: 12, x: 0, y: 32 },
        [
          rateQuery(
            'sum by (name, fdk_service, kubernetes_namespace) (floor(rate(resilience4j_circuitbreaker_not_permitted_calls_total{kubernetes_namespace="$namespace"}[5m])*300))',
            '{{name}}',
          ),
        ],
      ),
    ),

    withLogLink(
      linePanel(
        'Circuit breaker failure rate',
        { h: 6, w: 12, x: 12, y: 32 },
        [
          rateQuery(
            'max by (name, fdk_service, kubernetes_namespace) (resilience4j_circuitbreaker_failure_rate{kubernetes_namespace="$namespace"})',
            '{{name}}',
          ),
        ],
        true,
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

    // --- New in fdk-parser-service (PR #115) ---
    withLogLink(
      stackedPanel(
        'Failed parsings by reason',
        { h: 6, w: 12, x: 0, y: 38 },
        [
          rateQuery(
            'sum by (type, reason, fdk_service, kubernetes_namespace) (floor(rate(rdf_parse_error{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300))',
            '{{type}} - {{reason}}',
          ),
        ],
      ),
      true,
    ),

    withLogLink(
      stackedPanel(
        'Parser profile match rate',
        { h: 6, w: 12, x: 12, y: 38 },
        [
          rateQuery(
            'sum by (type, parser, status, fdk_service, kubernetes_namespace) (floor(rate(rdf_parse_profile_match_total{kubernetes_namespace="$namespace", type=~"$type"}[5m])*300))',
            '{{type}} / {{parser}} ({{status}})',
          ),
        ],
      ),
    ),

    withLogLink(
      linePanel(
        'Pipeline lag (event produced to parse start)',
        { h: 8, w: 12, x: 0, y: 44 },
        [
          rateQuery(
            'sum by (type, fdk_service, kubernetes_namespace) (rate(rdf_parse_pipeline_lag_seconds_sum{kubernetes_namespace="$namespace", type=~"$type"}[5m])/rate(rdf_parse_pipeline_lag_seconds_count{kubernetes_namespace="$namespace", type=~"$type"}[5m]))',
            '{{type}}',
          ),
        ],
        true,
        's',
      ),
    ),

    withLogLink(
      linePanel(
        'Payload size (avg chars)',
        { h: 8, w: 12, x: 12, y: 44 },
        [
          rateQuery(
            'sum by (type, direction, fdk_service, kubernetes_namespace) (rate(rdf_parse_payload_size_chars_sum{kubernetes_namespace="$namespace", type=~"$type"}[5m])/rate(rdf_parse_payload_size_chars_count{kubernetes_namespace="$namespace", type=~"$type"}[5m]))',
            '{{type}} ({{direction}})',
          ),
        ],
        true,
      ),
    ),

    linePanel(
      'Kafka consumer lag by topic',
      { h: 6, w: 24, x: 0, y: 52 },
      [
        rateQuery(
          'max by (topic, kubernetes_namespace) (kafka_consumer_fetch_manager_records_lag{kubernetes_namespace="$namespace"})',
          '{{topic}}',
        ),
      ],
      true,
    ),
])

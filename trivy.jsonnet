local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local table_panel = import 'grafonnet-7.0/panel/table.libsonnet';
local timeseries_panel = import 'github.com/rhowe/grafonnet-lib/grafonnet/timeseries_panel.libsonnet';
local prometheus = grafana.prometheus;
local template = grafana.template;

dashboard.new(
  'Trivy',
  tags=['trivy'],
  time_from='now-2h',
)
.addPanel(
  grafana.statPanel.new(
    'CRITICAL',
    unit='none',
    graphMode='none',
    reducerFunction='last',
  ).addTarget(
    prometheus.target(
      'sum(trivy_image_vulnerabilities{severity="Critical"})',
      datasource='prometheus',
    )
  ).addThreshold({
    color: 'semi-dark-red',
    value: null,
  }),
  gridPos={
    x: 0,
    y: 0,
    w: 4,
    h: 6,
  }
)
.addPanel(
  grafana.statPanel.new(
    'HIGH',
    unit='none',
    graphMode='none',
    reducerFunction='last',
  ).addTarget(
    prometheus.target(
      'sum(trivy_image_vulnerabilities{severity="High"})',
      datasource='prometheus',
    )
  ).addThreshold({
    color: 'semi-dark-orange',
    value: null,
  }),
  gridPos={
    x: 4,
    y: 0,
    w: 4,
    h: 6,
  }
)
.addPanel(
  grafana.statPanel.new(
    'MEDIUM',
    unit='none',
    graphMode='none',
    reducerFunction='last',
  ).addTarget(
    prometheus.target(
      'sum(trivy_image_vulnerabilities{severity="Medium"})',
      datasource='prometheus',
    )
  ).addThreshold({
    color: 'semi-dark-yellow',
    value: null,
  }),
  gridPos={
    x: 8,
    y: 0,
    w: 4,
    h: 6,
  }
)
.addPanel(
  grafana.statPanel.new(
    'LOW',
    unit='none',
    graphMode='none',
    reducerFunction='last',
  ).addTarget(
    prometheus.target(
      'sum(trivy_image_vulnerabilities{severity="Low"})',
      datasource='prometheus',
    )
  ).addThreshold({
    color: 'semi-dark-green',
    value: null,
  }),
  gridPos={
    x: 12,
    y: 0,
    w: 3,
    h: 6,
  }
)
.addPanel(
  grafana.statPanel.new(
    'UNKNOWN',
    unit='none',
    graphMode='none',
    reducerFunction='last',
  ).addTarget(
    prometheus.target(
      'sum(trivy_image_vulnerabilities{severity="Unknown"})',
      datasource='prometheus',
    )
  ).addThreshold({
    color: 'semi-dark-blue',
    value: null,
  }),
  gridPos={
    x: 15,
    y: 0,
    w: 3,
    h: 6,
  }
)
.addPanel(
  std.mergePatch(grafana.pieChartPanel.new(
    ''
  ).addTarget(
    prometheus.target(
      'sum(trivy_image_vulnerabilities{}) by (severity)',
      datasource='prometheus',
      legendFormat='{{severity}}',
    )
  ), {
    type: 'piechart',
    fieldConfig: {
      defaults: {
        color: {
          mode: 'palette-classic',
        },
        custom: {
          hideFrom: {
            legend: false,
            tooltip: false,
            viz: false,
          },
        },
        mappings: [],
      },
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Critical',
          },
          properties: [
            {
              id: 'color',
              value: {
                fixedColor: 'red',
                mode: 'fixed',
              },
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'High',
          },
          properties: [
            {
              id: 'color',
              value: {
                fixedColor: 'orange',
                mode: 'fixed',
              },
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Medium',
          },
          properties: [
            {
              id: 'color',
              value: {
                fixedColor: 'yellow',
                mode: 'fixed',
              },
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Low',
          },
          properties: [
            {
              id: 'color',
              value: {
                fixedColor: 'green',
                mode: 'fixed',
              },
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Unknown',
          },
          properties: [
            {
              id: 'color',
              value: {
                fixedColor: 'blue',
                mode: 'fixed',
              },
            },
          ],
        },
      ],
    },
  }),
  gridPos={
    x: 18,
    y: 0,
    w: 6,
    h: 6,
  }
)
.addPanel(
  table_panel.new(
    ''
  ).addTarget(
    prometheus.target(
      'sum(trivy_image_vulnerabilities{}) by (image_registry, image_repository, image_tag)',
      datasource='prometheus',
      format='table',
      instant=true,
    )
  ).addTarget(
    prometheus.target(
      'max(trivy_image_vulnerabilities{severity="Critical"}) by (image_registry, image_repository, image_tag)',
      datasource='prometheus',
      format='table',
      instant=true,
    )
  ).addTarget(
    prometheus.target(
      'max(trivy_image_vulnerabilities{severity="High"}) by (image_registry, image_repository, image_tag)',
      datasource='prometheus',
      format='table',
      instant=true,
    )
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'image_registry',
    },
    properties=[
      {
        id: 'displayName',
        value: 'Registry',
      },
      {
        id: 'custom.width',
        value: 150,
      },
    ],
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'image_repository',
    },
    properties=[
      {
        id: 'displayName',
        value: 'Repository',
      },
      {
        id: 'custom.width',
        value: 300,
      },
    ],
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'image_tag',
    },
    properties=[
      {
        id: 'displayName',
        value: 'Tag',
      },
      {
        id: 'custom.width',
        value: 360,
      },
    ],
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'Value #A',
    },
    properties=[
      {
        id: 'displayName',
        value: 'TOTAL',
      },
      {
        id: 'custom.align',
        value: 'left',
      },
      {
        id: 'custom.width',
        value: 80,
      },
    ],
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'Value #B',
    },
    properties=[
      {
        id: 'displayName',
        value: 'CRITICAL',
      },
      {
        id: 'custom.displayMode',
        value: 'gradient-gauge',
      },
      {
        id: 'max',
        value: 20,
      },
      {
        id: 'thresholds',
        value: {
          mode: 'absolute',
          steps: [
            {
              color: 'rgba(50, 172, 45, 0.97)',
              value: null,
            },
            {
              color: 'rgba(237, 129, 40, 0.89)',
              value: 5,
            },
            {
              color: 'rgba(245, 54, 54, 0.9)',
              value: 10,
            },
          ],
        },
      },
    ],
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'Value #C',
    },
    properties=[
      {
        id: 'displayName',
        value: 'HIGH',
      },
      {
        id: 'custom.displayMode',
        value: 'gradient-gauge',
      },
      {
        id: 'max',
        value: 30,
      },
      {
        id: 'thresholds',
        value: {
          mode: 'absolute',
          steps: [
            {
              color: 'rgba(50, 172, 45, 0.97)',
              value: null,
            },
            {
              color: 'rgba(237, 129, 40, 0.89)',
              value: 10,
            },
            {
              color: 'rgba(245, 54, 54, 0.9)',
              value: 20,
            },
          ],
        },
      },
    ],
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'Time',
    },
    properties=[
      {
        id: 'custom.hidden',
        value: true,
      },
    ],
  ) + {
    transformations: [
      {
        id: 'merge',
      },
      {
        id: 'sortBy',
        options: {
          sort: [
            {
              desc: true,
              field: 'Value #B',
            },
          ],
        },
      },
    ],
    options: {
      footer: {
        enablePagination: true,
      },
    },
  },
  gridPos={
    x: 0,
    y: 1,
    w: 24,
    h: 20,
  }
)

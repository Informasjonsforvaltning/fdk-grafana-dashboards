local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local table_panel = import 'grafonnet-7.0/panel/table.libsonnet';
local timeseries_panel = import 'grafonnet/timeseries_panel.libsonnet';
local prometheus = grafana.prometheus;
local template = grafana.template;

dashboard.new(
  'Kafka',
  tags=['kafka'],
  time_from='now-2h',
)
.addTemplate(
  template.new(
    'topic',
    'prometheus',
    'label_values(kafka_topic_partition_current_offset{topic!="__consumer_offsets",topic!="_schemas"}, topic)',
    label='Topic',
    includeAll=true,
    multi=true,
  )
)
.addPanel(
  timeseries_panel.new(
    'Messages in per Second',
    showPoints='never',
  ).addTarget(
    prometheus.target(
      'sum(rate(kafka_topic_partition_current_offset{topic=~"$topic"}[60s])) by (topic)',
      datasource='prometheus',
      intervalFactor=1,
      interval='1s',
      legendFormat='{{topic}}',
    )
  ), gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 6,
  }
)
.addPanel(
  timeseries_panel.new(
    'Messages Consumed per Second',
    showPoints='never',
  )
  .addTarget(
    prometheus.target(
      'sum(rate(kafka_consumergroup_current_offset{topic=~"$topic"}[60s])) by (consumergroup, topic)',
      datasource='prometheus',
      intervalFactor=1,
      interval='1s',
      legendFormat='{{consumergroup}} (topic: {{topic}})',
    )
  ), gridPos={
    x: 0,
    y: 1,
    w: 24,
    h: 6,
  }
)
.addPanel(
  timeseries_panel.new(
    title='Lag by Consumer Group',
    showPoints='never',
  ).addTarget(
    prometheus.target(
      'avg(kafka_consumergroup_lag{topic=~"$topic"}) by (consumergroup, topic)',
      datasource='prometheus',
      intervalFactor=1,
      interval='1s',
      legendFormat='{{consumergroup}} (topic: {{topic}})',
    )
  ), gridPos={
    x: 0,
    y: 2,
    w: 24,
    h: 6,
  }
)
.addPanel(
  table_panel.new(
    title='Partitions per Topic',
    datasource='prometheus',
  )
  .addTarget(
    prometheus.target(
      'sum(kafka_topic_partitions{topic=~"$topic"}) by(topic)',
      format='table',
      instant=true,
    )
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
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'topic',
    },
    properties=[
      {
        id: 'displayName',
        value: 'Topic',
      },
    ],
  ), gridPos={
    x: 0,
    y: 3,
    w: 12,
    h: 6,
  }
)
.addPanel(
  table_panel.new(
    title='Consumer Group Members',
    datasource='prometheus',
  )
  .addTarget(
    prometheus.target(
      'sum(kafka_consumergroup_members{consumergroup!="schema-registry"}) by(consumergroup)',
      format='table',
      instant=true,
    )
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
  ).addOverride(
    matcher={
      id: 'byName',
      options: 'consumergroup',
    },
    properties=[
      {
        id: 'displayName',
        value: 'Consumer Group',
      },
    ],

  ), gridPos={
    x: 12,
    y: 3,
    w: 12,
    h: 6,
  }
)

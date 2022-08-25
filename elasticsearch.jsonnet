// https://grafana.com/grafana/dashboards/9746-elasticsearch-example/
local elasticsearch = (import 'elasticsearch.json');

elasticsearch {
  panels: std.flattenArrays([
    [
      elasticsearch.panels[0],
    ],
    [
      std.mergePatch(elasticsearch.panels[1], {
        targets: [
          elasticsearch.panels[1].targets[0] {
            legendFormat: 'Value',
          },
        ],
      }),
    ],
    elasticsearch.panels[2:],
  ]),
}

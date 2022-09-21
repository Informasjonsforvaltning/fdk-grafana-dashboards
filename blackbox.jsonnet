// https://grafana.com/grafana/dashboards/7587-prometheus-blackbox-exporter/
// NOTE: manual s/DS_PROMETHEUS-SERVER/DS_PROMETHEUS_SERVER/
local blackbox = (import 'blackbox.json');

local patch = {
  templating: {
    list: blackbox.templating.list[0:1] + [{
      hide: 2,
      name: 'DS_PROMETHEUS_SERVER',
      query: 'prometheus',
      skipUrlSync: false,
      type: 'constant',
    }] + [{
      allValue: null,
      current: {},
      datasource: 'prometheus',
      hide: 0,
      includeAll: true,
      label: null,
      multi: true,
      name: 'target',
      options: [],
      query: 'label_values(probe_success, instance)',
      refresh: 1,
      regex: '',
      sort: 0,
      tagValuesQuery: '',
      tags: [],
      tagsQuery: '',
      type: 'query',
      useTags: false,
    }],
  },
};

std.mergePatch(blackbox, patch)
